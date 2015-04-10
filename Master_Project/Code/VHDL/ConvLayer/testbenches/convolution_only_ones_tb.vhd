library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library ieee_proposed;
use ieee_proposed.fixed_float_types.all;
use ieee_proposed.fixed_pkg.all;
  
ENTITY convolution_only_ones_tb IS
	generic 	(
		IMAGE_DIM	: Natural := 32;
		KERNEL_DIM 	: Natural := 5;
		INT_WIDTH	: Natural := 16;
		FRAC_WIDTH	: Natural := 16
	);
END convolution_only_ones_tb;

ARCHITECTURE behavior OF convolution_only_ones_tb IS 

-- Component Declaration
	COMPONENT convolution
		generic 	(
			IMG_DIM	: Natural := IMAGE_DIM;
			KERNEL_DIM 	: Natural := KERNEL_DIM;
			INT_WIDTH	: Natural := INT_WIDTH;
			FRAC_WIDTH	: Natural := FRAC_WIDTH
		);
		port ( 
			clk					: in std_logic;
			reset				: in std_logic;
			layer_nr            : in std_logic;
			conv_en 			: in std_logic;
			weight_we			: in std_logic;
			weight_data 		: in sfixed(INT_WIDTH-1 downto -FRAC_WIDTH);
			pixel_in 			: in sfixed(INT_WIDTH-1 downto -FRAC_WIDTH);
			output_valid		: out std_logic; 
			conv_en_out			: out std_logic;
			pixel_out 			: out sfixed(INT_WIDTH-1 downto -FRAC_WIDTH);
			bias 				: out sfixed(INT_WIDTH-1 downto -FRAC_WIDTH)
		);
	END COMPONENT;

	constant one 	: sfixed(INT_WIDTH-1 downto -FRAC_WIDTH) := to_sfixed(1, INT_WIDTH-1, -FRAC_WIDTH);
	
	constant result0 	: sfixed(INT_WIDTH-1 downto -FRAC_WIDTH) := to_sfixed(25, INT_WIDTH-1, -FRAC_WIDTH);	 

	signal clk			   : std_logic := '0';
	signal reset		   : std_logic := '1';
	signal conv_en_in	   : std_logic := '0';
	signal layer_nr        : std_logic := '0';
	signal weight_we	   : std_logic := '0';
	signal weight_data     : sfixed(INT_WIDTH-1 downto -FRAC_WIDTH) := (others => '0');
    signal pixel_in        : sfixed(INT_WIDTH-1 downto -FRAC_WIDTH) := (others => '0');
	signal output_valid    : std_logic; 
	signal pixel_out       : sfixed(INT_WIDTH-1 downto -FRAC_WIDTH);
	signal conv_en_out     : std_logic;
	signal bias_out        : sfixed(INT_WIDTH-1 downto -FRAC_WIDTH);
	
	constant clk_period : time := 1 ns;
	signal nof_outputs 	: Natural := 0;
	constant Nof_Convs 	: Natural := 2;
BEGIN

	convolution_test : convolution port map(
		clk => clk,
		reset => reset,
		conv_en => conv_en_in,
		layer_nr => layer_nr,
		weight_we => weight_we,
		weight_data => weight_data,
		pixel_in => pixel_in,
		output_valid => output_valid,
		pixel_out => pixel_out,
		conv_en_out => conv_en_out,
		bias => bias_out
	);
	
	clock : process
	begin
		clk <= '0';
		wait for clk_period/2;
		clk <= '1';
		wait for clk_period/2;
	end process;


	load_weights : process
	begin
	   layer_nr <= '0';
		reset <= '0';
		weight_we <= '0';
		wait for clk_period;
		reset <= '1';
		weight_we <= '1';
		for i in 0 to KERNEL_DIM*KERNEL_DIM loop
			weight_data <= one;
			wait for clk_period;
		end loop;
		
		weight_we <= '0';
		wait;
		
	end process;
	
	
	create_input : PROCESS
	BEGIN
		wait for clk_period*(KERNEL_DIM*KERNEL_DIM+3); -- wait until weights are loaded. 
		conv_en_in <= '1';
        for i in 0 to ((IMAGE_DIM*IMAGE_DIM)-1) loop
            pixel_in <= one;
            wait for clk_period;
        end loop;
		conv_en_in <= '0';
		
		wait; -- will wait forever
	END PROCESS;
	
	assert_outputs : process(clk)
	begin
		if rising_edge(clk) then
            if (output_valid ='1') then
                assert pixel_out = result0
                    report "Output nr. " & Natural'image(nof_outputs) & ". Expected value: " &
                        to_string(result0) & ". Actual value: " & to_string(pixel_out) & "."
                    severity error;
			end if;
		end if; 
	end process;
--  End Test Bench 

END;
