library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library ieee_proposed;
use ieee_proposed.fixed_float_types.all;
use ieee_proposed.fixed_pkg.all;
use ieee_proposed.float_pkg.all;

entity conv_layer_interface is
	generic (
        C_S_AXI_DATA_WIDTH  : Natural := 32;
        IMG_DIM             : Natural := 32;
        KERNEL_DIM          : Natural := 5;
        POOL_DIM            : Natural := 2;
        INT_WIDTH           : Natural := 16;
        FRAC_WIDTH          : Natural := 16
    );
    Port (

        clk             : in std_logic;
        reset           : in std_logic; -- NOTE: Is active low.
        -- Interface for controlling module
        s_axi_raddr     : in std_logic_vector(2 downto 0);
        s_axi_rdata     : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
        s_axi_wdata     : in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
        s_axi_waddr     : in std_logic_vector(2 downto 0);
        s_axi_we        : in std_logic;

        -- Interface for streaming data in
        s_axis_tvalid   : in std_logic;
        s_axis_tready   : out std_logic;
        s_axis_tdata    : in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
        s_axis_tkeep    : in std_logic_vector((C_S_AXI_DATA_WIDTH/8)-1 downto 0);
        s_axis_tlast    : in std_logic;

        -- Interface for streaming data out
        m_axis_tvalid   : out std_logic;
        m_axis_tready   : in std_logic;
        m_axis_tdata    : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
        m_axis_tkeep    : out std_logic_vector((C_S_AXI_DATA_WIDTH/8)-1 downto 0);
        m_axis_tlast    : out std_logic
    );



end conv_layer_interface;

architecture Behavioral of conv_layer_interface is

    component convolution_layer is
        generic (
            IMG_DIM 		: Natural := IMG_DIM;
            KERNEL_DIM 		: Natural := KERNEL_DIM;
            POOL_DIM 	    : Natural := POOL_DIM;
            INT_WIDTH 		: Natural := INT_WIDTH;
            FRAC_WIDTH 		: Natural := FRAC_WIDTH
        );

        port (
            clk 		: in std_logic;
            reset		: in std_logic;
            conv_en		: in std_logic;
            final_set : in std_logic;
            layer_nr	: in std_logic;
            weight_we	: in std_logic;
            weight_data	: in sfixed(INT_WIDTH-1 downto -FRAC_WIDTH);
            pixel_in	: in sfixed(INT_WIDTH-1 downto -FRAC_WIDTH);
            pixel_valid	: out std_logic;
            pixel_out 	: out float32;
            dummy_bias	: out sfixed(INT_WIDTH-1 downto -FRAC_WIDTH)
        );
    end component;

    -- Constants
    constant Layer0_Nof_Outputs : std_logic_vector := std_logic_vector(to_unsigned(14*14, 32));
    constant Layer1_Nof_Outputs : std_logic_vector := std_logic_vector(to_unsigned(5*5, 32));
    constant Layer1_Set_Size    : std_logic_vector := std_logic_vector(to_unsigned(14*14, 32));

	-- Control signals
	signal op_code          : std_logic_vector(1 downto 0);
	signal start_processing : std_logic;
	signal nof_outputs      : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    signal nof_input_sets   : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);

	-- State signals
	signal is_writing_weights : std_logic;
	signal is_executing_cl : std_logic;

	-- Output streaming buffer
	signal out_sbuffer : std_logic_vector(INT_WIDTH+FRAC_WIDTH-1 downto 0);

	-- Result buffer
	type sfixed_array_length_4 is array (3 downto 0) of sfixed(INT_WIDTH-1 downto -FRAC_WIDTH);
	signal results : sfixed_array_length_4;




	-- Conv layer (cl) signals --
    signal cl_reset         : std_logic;
    signal conv_layer_reset : std_logic;
	signal cl_conv_en		: std_logic;
    signal cl_layer_nr      : std_logic;
    signal cl_final_set     : std_logic;
    signal cl_weight_we     : std_logic;
    signal cl_weight_data   : sfixed(INT_WIDTH-1 downto -FRAC_WIDTH);
    signal cl_pixel_in      : sfixed(INT_WIDTH-1 downto -FRAC_WIDTH);
    signal cl_pixel_valid   : std_logic;
    signal cl_pixel_out     : float32;
    signal cl_dummy_bias    : sfixed(INT_WIDTH-1 downto -FRAC_WIDTH);


begin


    op_code <= s_axi_wdata(1 downto 0);


    WriteControlRegisters : process(clk, reset)
    begin
        if reset = '0' then
            cl_layer_nr <= '0';
            nof_outputs <= (others => '0');
            start_processing <= '0';
            nof_input_sets <= (others => '0');
        elsif rising_edge(clk) then
            if s_axi_we = '1' then
                if s_axi_waddr = "000" then
                    case op_code is
                        when "00" =>
                            start_processing <= '1';
                        when others =>
                            start_processing <= '0';
                    end case;
                elsif s_axi_waddr = "001" then
                    start_processing <= '0';
                    if s_axi_wdata(0) = '1' then
                        nof_outputs <= Layer0_Nof_Outputs;
                        cl_layer_nr <= '0';
                    elsif s_axi_wdata(1) = '1' then
                        nof_outputs <= Layer1_Nof_Outputs;
                        cl_layer_nr <= '1';
                    end if;
                elsif s_axi_waddr = "010" then
                    start_processing <= '0';
                    nof_input_sets <= s_axi_wdata;
                else
                    start_processing <= '0';
                end if;
            else
                start_processing <= '0';
            end if;
        end if;
    end process;

    Read : process(nof_outputs, s_axis_tdata, s_axi_raddr, results, cl_dummy_bias, is_writing_weights, is_executing_cl)
    begin
        case s_axi_raddr is
            when b"000" => s_axi_rdata <= s_axis_tdata; -- 0
            when b"001" => s_axi_rdata <= (others => '1'); -- 4
            when b"010" => s_axi_rdata <= (others => '1'); -- 8
            when b"011" => s_axi_rdata <= (others => '1'); -- 12
            when b"100" => s_axi_rdata <= (0 => (is_writing_weights or is_executing_cl), others => '0'); -- 16
            when b"101" => s_axi_rdata <= (others => '1'); -- 20
            when b"110" => s_axi_rdata <= nof_outputs; -- 24
            when b"111" => s_axi_rdata <= to_slv(cl_dummy_bias); -- 28
            when others => s_axi_rdata <= (others => '1');
        end case;
    end process;

    s_axis_tready <= is_writing_weights or is_executing_cl;

    cl_weight_we <= is_writing_weights and s_axis_tvalid;
    cl_weight_data <= to_sfixed(s_axis_tdata, cl_weight_data);


    Controller : process(clk, reset)
        variable nof_processed_outputs : integer;
        variable nof_data_written : integer;
        variable nof_weights_written : integer;
        variable nof_input_sets_processed : integer;
        variable set_size : integer;
    begin
        if reset = '0' then
            nof_processed_outputs := 0;
            nof_data_written := 0;
            nof_weights_written := 0;
            nof_input_sets_processed := 0;
            set_size := to_integer(unsigned(Layer1_Set_Size));

            is_executing_cl <= '0';
            is_writing_weights <= '0';

            cl_final_set <= '0';

            m_axis_tlast <= '0';
            m_axis_tvalid <= '0';

            cl_reset <= '1';
        elsif rising_edge(clk) then

            if start_processing = '1' then
                is_writing_weights <= '1';
                cl_reset <= '1';

            -- WEIGHT HANDLING
            elsif is_writing_weights = '1' then
                cl_reset <= '1';
                m_axis_tlast <= '0';
                m_axis_tvalid <= '0';
                cl_final_set <= '0';

                if s_axis_tvalid = '1' then
                    if nof_weights_written = KERNEL_DIM*KERNEL_DIM+3 then
                        is_writing_weights <= '0';
                        nof_weights_written := 0;
                        is_executing_cl <= '1';
                    else
                        nof_weights_written := nof_weights_written + 1;
                    end if;
                end if;

            -- PROCESSING HANDLING

            elsif is_executing_cl = '1' then

                -- PROCESSING FINAL INPUT SET
                if nof_input_sets_processed = to_integer(unsigned(nof_input_sets))-1 then
                    cl_final_set <= '1';
                    if cl_pixel_valid = '1' then
                        out_sbuffer <= to_slv(cl_pixel_out);
                        m_axis_tvalid <= '1';
                        if nof_processed_outputs = to_integer(unsigned(nof_outputs)) -1 then
                            cl_reset <= '0';
                            is_executing_cl <= '0';
                            m_axis_tlast <= '1';
                            nof_processed_outputs := 0;
                            nof_input_sets_processed := 0;
                        else
                            cl_reset <= '1';
                            nof_processed_outputs := nof_processed_outputs + 1;
                            m_axis_tlast <= '0';
                        end if;
                    else
                        cl_reset <= '1';
                        m_axis_tlast <= '0';
                        m_axis_tvalid <= '0';
                    end if;

                -- PROCESSING ALL OTHER SETS

                else
                    cl_reset <= '1';
                    cl_final_set <= '0';
                    m_axis_tvalid <= '0';
                    m_axis_tlast <= '0';
                    if nof_data_written = set_size-1 then
                        is_writing_weights <= '1';
                        is_executing_cl <= '0';
                        nof_data_written := 0;
                        nof_input_sets_processed := nof_input_sets_processed + 1;
                    else
                        nof_data_written := nof_data_written + 1;
                    end if;
                end if;
            else
                cl_reset <= '1';
                nof_processed_outputs := 0;
                nof_data_written := 0;
                nof_weights_written := 0;
                nof_input_sets_processed := 0;
                set_size := to_integer(unsigned(Layer1_Set_Size));

                is_executing_cl <= '0';
                is_writing_weights <= '0';

                m_axis_tlast <= '0';
                m_axis_tvalid <= '0';
            end if;
        end if;
    end process;

    cl_conv_en <= is_executing_cl;
    cl_pixel_in <= to_sfixed(s_axis_tdata, cl_pixel_in);

    m_axis_tkeep <= (others => '1');
    m_axis_tdata <= out_sbuffer;

    -- PORT MAPS --
    conv_layer_reset <= reset and cl_reset;

    conv_layer_port_map : convolution_layer port map(
        clk         => clk,
        reset       => conv_layer_reset,
        conv_en     => cl_conv_en,
        final_set   => cl_final_set,
        layer_nr    => cl_layer_nr,
        weight_we   => cl_weight_we,
        weight_data => cl_weight_data,
        pixel_in    => cl_pixel_in,
        pixel_valid => cl_pixel_valid,
        pixel_out   => cl_pixel_out,
        dummy_bias  => cl_dummy_bias
    );

end Behavioral;
