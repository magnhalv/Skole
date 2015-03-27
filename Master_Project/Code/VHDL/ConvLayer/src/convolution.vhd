library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library ieee_proposed;
use ieee_proposed.fixed_float_types.all;
use ieee_proposed.fixed_pkg.all;

entity convolution is
    generic 	(
		IMG_DIM : Natural := 6;
		KERNEL_DIM : Natural := 3;
		INT_WIDTH : Natural := 8;
		FRAC_WIDTH : Natural := 8
	);
	port ( 
		clk : in std_logic;
		reset : in std_logic;
		conv_en : in std_logic;
		layer_nr : in std_logic;
		weight_we : in std_logic;
		weight_data : in sfixed(INT_WIDTH-1 downto -FRAC_WIDTH);
		pixel_in : in sfixed(INT_WIDTH-1 downto -FRAC_WIDTH);
	    
	    conv_en_out : out std_logic;
	    output_valid : out std_logic;
		pixel_out : out sfixed(INT_WIDTH-1 downto -FRAC_WIDTH);
		bias : out sfixed(INT_WIDTH-1 downto -FRAC_WIDTH)
	);
end convolution;

architecture Behavioral of convolution is

    component conv_controller
        generic (
            IMAGE_DIM       : Natural := IMG_DIM;
            KERNEL_DIM      : Natural := KERNEL_DIM
        );
        port (
            clk : in  std_logic;
            conv_en : in  std_logic;
            output_valid : out  std_logic
        );
        end component;

    component sfixed_shift_registers 
        generic (
            NOF_REGS : Natural := IMG_DIM-KERNEL_DIM;
            INT_WIDTH : Natural := INT_WIDTH;
            FRAC_WIDTH : Natural := FRAC_WIDTH
        );
        port (
            clk : in std_logic;
            reset : in std_logic;
            we : in std_logic;
            output_reg : in Natural;
            data_in : in sfixed(INT_WIDTH-1 downto -FRAC_WIDTH);
            data_out : out sfixed(INT_WIDTH-1 downto -FRAC_WIDTH)
        );
    end component;
       
    
    component mac
        generic (
            INT_WIDTH : Natural := INT_WIDTH;
            FRAC_WIDTH : Natural := FRAC_WIDTH
        );
        port (
            clk : in std_logic;
            reset : in std_logic;
            weight_we : in std_logic;
            weight_in : in sfixed(INT_WIDTH-1 downto -FRAC_WIDTH);
            multi_value : in sfixed(INT_WIDTH-1 downto -FRAC_WIDTH);
            acc_value : in sfixed(INT_WIDTH-1 downto -FRAC_WIDTH);
            weight_out : out sfixed(INT_WIDTH-1 downto -FRAC_WIDTH);
            result : out sfixed(INT_WIDTH-1 downto -FRAC_WIDTH)
        );
    end component;

    
    type sfixed_array is array (KERNEL_DIM-1 downto 0) of sfixed(INT_WIDTH-1 downto -FRAC_WIDTH);
    type sfixed_array_of_arrays is array (KERNEL_DIM-1 downto 0) of sfixed_array;
    
    signal weight_values : sfixed_array_of_arrays;
    signal acc_values : sfixed_array_of_arrays;
    signal shift_reg_output : sfixed_array;
    
    signal output_shift_reg_nr : Natural;
    

begin

    pixel_out <= acc_values(KERNEL_DIM-1)(KERNEL_DIM-1);
    
    controller : conv_controller port map (
        clk => clk,
        conv_en => conv_en,
        output_valid => output_valid
    );

    gen_mac_rows: for row in 0 to KERNEL_DIM-1 generate
        gen_mac_columns: for col in 0 to KERNEL_DIM-1 generate
            begin
            
                mac_first_leftmost : if row = 0 and col = 0 generate
                begin
                    mac1 : mac port map (
                        clk => clk,
                        reset => reset,
                        weight_we => weight_we,
                        weight_in => weight_data,
                        multi_value => pixel_in,
                        acc_value => (others => '0'),
                        weight_out => weight_values(row)(col),
                        result => acc_values(row)(col)
                    );
                end generate;
                
                mac_other_leftmost : if row > 0 and col = 0 generate
                begin
                    mac1 : mac port map (
                        clk => clk,
                        reset => reset,
                        weight_we => weight_we,
                        weight_in => weight_values(row-1)(KERNEL_DIM-1),
                        multi_value => pixel_in,
                        acc_value => shift_reg_output(row-1),
                        weight_out => weight_values(row)(col),
                        result => acc_values(row)(col)
                    );
                end generate;
                
                mac_others : if (col > 0 and col < KERNEL_DIM-1) generate
                begin
                    mac3 : mac port map (
                        clk => clk,
                        reset => reset,
                        weight_we => weight_we,
                        weight_in => weight_values(row)(col-1),
                        multi_value => pixel_in,
                        acc_value => acc_values(row)(col-1),
                        weight_out => weight_values(row)(col),
                        result => acc_values(row)(col)
                    );
                end generate;
                
                mac_rightmost : if col = KERNEL_DIM-1  generate
                begin
                    mac4 : mac port map (
                        clk => clk,
                        reset => reset,
                        weight_we => weight_we,
                        weight_in => weight_values(row)(col-1),
                        multi_value => pixel_in,
                        acc_value => acc_values(row)(col-1),
                        weight_out => weight_values(row)(col),
                        result => acc_values(row)(col)
                    );
                end generate;
                
                shift_regs : if row < KERNEL_DIM-1 and col = KERNEL_DIM-1 generate
                begin
                    sr : sfixed_shift_registers port map (
                        clk => clk,
                        reset => reset,
                        we => conv_en,
                        output_reg => output_shift_reg_nr,
                        data_in => acc_values(row)(col),
                        data_out => shift_reg_output(row)
                    );
                end generate;
                
        end generate;
    end generate;
    
    shift_reg_config : process(layer_nr)
    begin
        if layer_nr = '0' then
            output_shift_reg_nr <= IMG_DIM-KERNEL_DIM-1;
        else
           output_shift_reg_nr <= (IMG_DIM-KERNEL_DIM-1)-KERNEL_DIM-1;
        end if; 
    end process;
    
    bias_register : process(clk, reset)
    begin
        if rising_edge(clk) then
            if reset = '0' then
                bias <= (others => '0');
            elsif weight_we = '1' then
                bias <= weight_values(KERNEL_DIM-1)(KERNEL_DIM-1);
            end if; 
        end if;
    end process;
    
    conv_reg : process(clk) 
    begin
        if rising_edge(clk) then
            conv_en_out <= conv_en;
        end if;
    end process;
    
    
end Behavioral;
