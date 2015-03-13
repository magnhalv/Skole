library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library ieee_proposed;
use ieee_proposed.fixed_float_types.all;
use ieee_proposed.fixed_pkg.all;

entity conv_layer_interface is
	generic (
        C_S_AXI_DATA_WIDTH  : Natural := 32;
        IMG_DIM             : Natural := 6;
        KERNEL_DIM          : Natural := 3;
        MAX_POOL_DIM        : Natural := 2;
        INT_WIDTH           : Natural := 16;
        FRAC_WIDTH          : Natural := 16
    );
    Port (
        clk             : in std_logic;
        reset           : in std_logic; -- NOTE: Is active low.
        s_axi_raddr     : in std_logic_vector(2 downto 0);
        s_axi_rdata     : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
        s_axi_wdata     : in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
        s_axi_we        : in std_logic;
        
        s_axis_tvalid   : in std_logic;
        s_axis_tready   : out std_logic;
        s_axis_tdata    : in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
        s_axis_tkeep    : in std_logic_vector((C_S_AXI_DATA_WIDTH/8)-1 downto 0);
        s_axis_tlast    : in std_logic;
        
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
            MAX_POOL_DIM 	: Natural := MAX_POOL_DIM;
            INT_WIDTH 		: Natural := INT_WIDTH;
            FRAC_WIDTH 		: Natural := FRAC_WIDTH
        );
        
        port ( 
            clk 		: in std_logic;
            reset		: in std_logic;
            conv_en		: in std_logic;
            layer_nr	: in std_logic;
            weight_we	: in std_logic;
            weight_data	: in ufixed(INT_WIDTH-1 downto -FRAC_WIDTH);
            pixel_in	: in ufixed(INT_WIDTH-1 downto -FRAC_WIDTH);
            pixel_valid	: out std_logic;
            pixel_out 	: out ufixed(INT_WIDTH-1 downto -FRAC_WIDTH);
            dummy_bias	: out ufixed(INT_WIDTH-1 downto -FRAC_WIDTH)
        );
    end component;

	-- Instruction signals --
	signal op_code         : std_logic_vector(1 downto 0);
	signal write_weights   : std_logic;
	signal start_cl        : std_logic;
	
	signal is_writing_weights : std_logic;
	signal is_executing_cl : std_logic;
	
	-- Result buffer
	type ufixed_array_length_4 is array (3 downto 0) of ufixed(INT_WIDTH-1 downto -FRAC_WIDTH);
	signal results : ufixed_array_length_4;
	
	
	-- Conv layer (cl) signals --
	signal cl_conv_en		: std_logic;
    signal cl_layer_nr      : std_logic;
    signal cl_weight_we     : std_logic;
    signal cl_weight_data   : ufixed(INT_WIDTH-1 downto -FRAC_WIDTH);
    signal cl_pixel_in      : ufixed(INT_WIDTH-1 downto -FRAC_WIDTH);
    signal cl_pixel_valid   : std_logic;
    signal cl_pixel_out     : ufixed(INT_WIDTH-1 downto -FRAC_WIDTH);
    signal cl_dummy_bias    : ufixed(INT_WIDTH-1 downto -FRAC_WIDTH);
    

	
begin   
    
    op_code <= s_axi_wdata(1 downto 0);
    cl_layer_nr <= '0'; -- CHANGE LATER
    
    DecodeInstruction : process(clk) 
    begin
        if rising_edge(clk) then
            if s_axi_we = '1' then
                case op_code is
                    when "00" =>
                        write_weights <= '1';
                        start_cl <= '0';
                    when "01" =>
                        write_weights <= '0';
                        start_cl <= '1';
                    when others =>
                        write_weights <= '0';
                        start_cl <= '0';
                end case;
            else
                write_weights <= '0';
                start_cl <= '0';
            end if;
        end if;
    end process;
    
    Read : process(s_axis_tdata, s_axi_raddr, results, cl_dummy_bias, is_writing_weights, is_executing_cl)
    begin
        case s_axi_raddr is
            when b"000" => s_axi_rdata <= to_slv(results(0)); -- 0
            when b"001" => s_axi_rdata <= to_slv(results(1)); -- 4
            when b"010" => s_axi_rdata <= to_slv(results(2)); -- 8
            when b"011" => s_axi_rdata <= to_slv(results(3)); -- 12
            when b"100" => s_axi_rdata <= (0 => is_writing_weights, others => '0'); -- 16
            when b"101" => s_axi_rdata <= (0 => is_executing_cl, others => '0'); -- 20
            when b"110" => s_axi_rdata <= s_axis_tdata; -- 24
            when b"111" => s_axi_rdata <= to_slv(cl_dummy_bias); -- 28
            when others => s_axi_rdata <= (others => '1');
        end case;
    end process;
    
    s_axis_tready <= is_writing_weights or is_executing_cl;
    
    cl_weight_we <= is_writing_weights and s_axis_tvalid;
    cl_weight_data <= to_ufixed(s_axis_tdata(INT_WIDTH+FRAC_WIDTH-1 downto 0), cl_weight_data);
    
    WriteWeights : process(clk, reset)
        variable nof_writes : Natural;
    begin
        if reset = '0' then
            nof_writes := 0;
            is_writing_weights <= '0';
        elsif rising_edge(clk) then
            if write_weights = '1' then
                is_writing_weights <= '1';  
            elsif is_writing_weights = '1' then
                if s_axis_tvalid = '1' then
                    if nof_writes = KERNEL_DIM*KERNEL_DIM then
                        is_writing_weights <= '0';
                    else
                        nof_writes := nof_writes + 1;
                    end if;
                end if;
            else
                nof_writes := 0;
                is_writing_weights <= '0';
            end if;
        end if;
    end process;
    
    cl_conv_en <= is_executing_cl;
    cl_pixel_in <= to_ufixed(s_axis_tdata(INT_WIDTH+FRAC_WIDTH-1 downto 0), cl_pixel_in);
    
    m_axis_tkeep <= (others => '1');
    --m_axis_tdata <= to_slv(cl_pixel_out);
    
    ExecuteCl : process(clk, reset)
        variable nof_results : Natural;
     begin
        if (reset = '0') then
            nof_results := 0;
            is_executing_cl <= '0';
        elsif rising_edge(clk) then
            if start_cl = '1' then
                nof_results := 0;
                is_executing_cl <= '1';
            elsif is_executing_cl = '1' then
                if cl_pixel_valid = '1' then
                    if nof_results = 4 then
                        is_executing_cl <= '0';
                        m_axis_tvalid <= '0'; 
                        --m_axis_tready
                        m_axis_tlast <= '0';
                    else
                        results(nof_results) <= cl_pixel_out;
                        nof_results := nof_results + 1;
                        m_axis_tvalid <= '1';
                        if (m_axis_tready = '0') then
                            m_axis_tdata <= "00000101001110010000000000000000";
                        else
                            m_axis_tdata <= to_slv(cl_pixel_out);
                        end if;
                        --m_axis_tready
                        m_axis_tlast <= '1';

                    end if;
                else
                    m_axis_tvalid <= '0'; 
                    --m_axis_tready
                    m_axis_tlast <= '0';
                end if;
            else
                nof_results := 0;
                is_executing_cl <= '0';
            end if;
        end if;
     end process;

    -- PORT MAPS --
    
    conv_layer_port_map : convolution_layer port map(
        clk         => clk,
        reset       => reset,
        conv_en     => cl_conv_en,
        layer_nr    => cl_layer_nr,
        weight_we   => cl_weight_we,
        weight_data => cl_weight_data,
        pixel_in    => cl_pixel_in,
        pixel_valid => cl_pixel_valid,
        pixel_out   => cl_pixel_out,
        dummy_bias  => cl_dummy_bias
    );

end Behavioral;

