library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

library ieee_proposed;
use ieee_proposed.fixed_float_types.all;
use ieee_proposed.fixed_pkg.all;

entity conv_layer_interface is
	generic (
        C_S_AXI_DATA_WIDTH  : integer := 32;
        IMG_DIM             : integer := 8;
        KERNEL_DIM          : integer := 2;
        MAX_POOL_DIM        : integer := 2;
        INT_WIDTH           : integer := 8;
        FRAC_WIDTH          : integer := 8
    );
    Port (
        clk             : in std_logic;
        reset           : in std_logic;
        s_axi_raddr     : in std_logic_vector(1 downto 0);
        s_axi_rdata     : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
        s_axi_wdata     : in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
        s_axi_we        : in std_logic;
        
        s_axis_tvalid   : in std_logic;
        s_axis_tready   : out std_logic;
        s_axis_tdata    : in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
        s_axis_tkeep    : in std_logic_vector((C_S_AXI_DATA_WIDTH/8)-1 downto 0);
        s_axis_tlast    : in std_logic
    );
    
    
    
end conv_layer_interface;

architecture Behavioral of conv_layer_interface is
    
    component convolution_layer is
        generic (
            IMG_DIM 		: integer := IMG_DIM;
            KERNEL_DIM 		: integer := KERNEL_DIM;
            MAX_POOL_DIM 	: integer := MAX_POOL_DIM;
            INT_WIDTH 		: integer := INT_WIDTH;
            FRAC_WIDTH 		: integer := FRAC_WIDTH
        );
        
        port ( 
            clk 		: in std_logic;
            reset		: in std_logic;
            conv_en		: in std_logic;
            first_layer	: in std_logic;
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
	signal start_cl      : std_logic;
	
	signal is_writing_weights : std_logic;
	signal is_executing_cl : std_logic;
	
	-- Conv layer (cl) signals --
	signal cl_conv_en		 : std_logic;
    signal cl_first_layer   : std_logic;
    signal cl_weight_we     : std_logic;
    signal cl_weight_data   : ufixed(INT_WIDTH-1 downto -FRAC_WIDTH);
    signal cl_pixel_in      : ufixed(INT_WIDTH-1 downto -FRAC_WIDTH);
    signal cl_pixel_valid   : std_logic;
    signal cl_pixel_out     : ufixed(INT_WIDTH-1 downto -FRAC_WIDTH);
    signal cl_dummy_bias    : ufixed(INT_WIDTH-1 downto -FRAC_WIDTH);
	
	
begin

    s_axis_tready <= is_writing_weights;   
    
    op_code <= s_axi_wdata(1 downto 0);
    
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
    
    Read : process(clk)
    begin
        if rising_edge(clk) then
            case s_axi_raddr is
                when "00" => s_axi_rdata <= "0000000000000000" & to_slv(cl_dummy_bias);
                when "01" => s_axi_rdata <= (0 => is_writing_weights, others => '0');
                when others => s_axi_rdata <= (others => '0');
            end case;
        end if;
    end process;
    
    s_axis_tready <= is_writing_weights or is_executing_cl;
    
    
    
    WriteWeights : process(clk)
        variable nof_writes : integer;
    begin
        if reset = '1' then
            nof_writes := 0;
            is_writing_weights <= '0';
        elsif rising_edge(clk) then
            if write_weights = '1' then
                is_writing_weights <= '1';  
            elsif is_writing_weights = '1' then
                if nof_writes = KERNEL_DIM*KERNEL_DIM+5 then
                    is_writing_weights <= '0';
                else
                    nof_writes := nof_writes + 1;
                end if;
            else
                nof_writes := 0;
                is_writing_weights <= '0';
            end if;
        end if;
    end process;
    
    
    cl_weight_we <= is_writing_weights and s_axis_tvalid;
    cl_weight_data <= to_ufixed(s_axis_tdata(INT_WIDTH+FRAC_WIDTH-1 downto 0), cl_weight_data);

    -- PORT MAPS --
    
    conv_layer_port_map : convolution_layer port map(
        clk         => clk,
        reset       => reset,
        conv_en     => cl_conv_en,
        first_layer => cl_first_layer,
        weight_we   => cl_weight_we,
        weight_data => cl_weight_data,
        pixel_in    => cl_pixel_in,
        pixel_valid => cl_pixel_valid,
        pixel_out   => cl_pixel_out,
        dummy_bias  => cl_dummy_bias
    );

end Behavioral;

