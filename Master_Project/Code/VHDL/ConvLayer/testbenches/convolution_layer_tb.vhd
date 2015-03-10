library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library ieee_proposed;
use ieee_proposed.fixed_float_types.all;
use ieee_proposed.fixed_pkg.all;

ENTITY convolution_layer_tb IS
	generic (
		IMG_DIM 			: Natural := 8;
		KERNEL_DIM 		: Natural := 3;
		MAX_POOL_DIM 	: Natural := 2;
		INT_WIDTH 		: Natural := 8;
		FRAC_WIDTH 		: Natural := 8
	);
END convolution_layer_tb;

ARCHITECTURE behavior OF convolution_layer_tb IS 

	COMPONENT convolution_layer
		generic (
			IMG_DIM 			: Natural := IMG_DIM;
			KERNEL_DIM 		: Natural := KERNEL_DIM;
			MAX_POOL_DIM 	: Natural := MAX_POOL_DIM;
			INT_WIDTH 		: Natural := INT_WIDTH;
			FRAC_WIDTH 		: Natural := FRAC_WIDTH
		);
		
		port ( 
			clk 			: in std_logic;
			reset			: in std_logic;
			conv_en		: in std_logic;
			weight_we	: in std_logic;
			weight_data	: in ufixed(INT_WIDTH-1 downto -FRAC_WIDTH);
			pixel_in		: in ufixed(INT_WIDTH-1 downto -FRAC_WIDTH);
			pixel_valid	: out std_logic;
			pixel_out 	: out ufixed(INT_WIDTH-1 downto -FRAC_WIDTH)
		);
	END COMPONENT;
	
	constant zero 	: ufixed(INT_WIDTH-1 downto -FRAC_WIDTH) := "0000000000000000";
	constant one 	: ufixed(INT_WIDTH-1 downto -FRAC_WIDTH) := "0000000100000000";
	constant two 	: ufixed(INT_WIDTH-1 downto -FRAC_WIDTH) := "0000001000000000";
	constant three : ufixed(INT_WIDTH-1 downto -FRAC_WIDTH) := "0000001100000000";
	constant four 	: ufixed(INT_WIDTH-1 downto -FRAC_WIDTH) := "0000010000000000";
	constant five 	: ufixed(INT_WIDTH-1 downto -FRAC_WIDTH) := "0000010100000000";
	
	constant result0 : ufixed(INT_WIDTH-1 downto -FRAC_WIDTH) := "1000100000000000";
	constant result1 : ufixed(INT_WIDTH-1 downto -FRAC_WIDTH) := "0111110000000000";
	constant result2 : ufixed(INT_WIDTH-1 downto -FRAC_WIDTH) := "1000011100000000";
	constant result3 : ufixed(INT_WIDTH-1 downto -FRAC_WIDTH) := "0101111000000000";
	constant result4 : ufixed(INT_WIDTH-1 downto -FRAC_WIDTH) := "0111110000000000";
	constant result5 : ufixed(INT_WIDTH-1 downto -FRAC_WIDTH) := "1000011000000000";
	constant result6 : ufixed(INT_WIDTH-1 downto -FRAC_WIDTH) := "1000000000000000";
	constant result7 : ufixed(INT_WIDTH-1 downto -FRAC_WIDTH) := "0101100100000000";
	constant result8 : ufixed(INT_WIDTH-1 downto -FRAC_WIDTH) := "0110001000000000";
	
	constant OUTPUT_DIM : Natural := (IMG_DIM-KERNEL_DIM+1)/MAX_POOL_DIM;
	type img_array is array ((IMG_DIM*IMG_DIM)-1 downto 0) of ufixed(INT_WIDTH-1 downto -FRAC_WIDTH);
	type kernel_array is array ((KERNEL_DIM*KERNEL_DIM) downto 0) of ufixed(INT_WIDTH-1 downto -FRAC_WIDTH);
	type pooled_array is array ((OUTPUT_DIM*OUTPUT_DIM)-1 downto 0) of ufixed(INT_WIDTH-1 downto -FRAC_WIDTH);
	
	signal image 	: img_array := (
		four,		four,		five, 	one, 		one, 		one, 		one, 		zero,
		one, 		five,		four, 	two, 		five, 	two, 		four, 	four,
		four, 	four,		two, 		three, 	two, 		five, 	four, 	one,
		zero, 	one,		one, 		five, 	three, 	three, 	five, 	three,
		zero, 	two,		two, 		two, 		two, 		four, 	three, 	zero,
		zero, 	three,	five, 	one, 		one, 		one, 		three, 	four,
		zero, 	three, 	four, 	three, 	one, 		one, 		two, 		zero,
		four, 	four, 	three, 	five, 	zero, 	three, 	five, 	four);
	signal kernel 	: kernel_array := (
		one, -- bias
		two, 		five, 	five,
		five, 	five, 	four,
		three,	four, 	four);
	signal result 	: pooled_array := (
		result0, 	result1, 	result2,
		result3, 	result4, 	result5,
		result6, 	result7, 	result8);
	
	signal clk 				: std_logic;
	signal reset			: std_logic;
	signal conv_en			: std_logic;
	signal weight_we		: std_logic;
	signal weight_data	: ufixed(INT_WIDTH-1 downto -FRAC_WIDTH);
	signal pixel_in		: ufixed(INT_WIDTH-1 downto -FRAC_WIDTH);
	signal pixel_valid	: std_logic;
	signal pixel_out 		: ufixed(INT_WIDTH-1 downto -FRAC_WIDTH);
	
	constant clk_period : time := 1 ns; 
	 

BEGIN

	conv_layer : convolution_layer port map(
			clk 			=> clk,
			reset			=> reset,
			conv_en		=> conv_en,
			weight_we	=> weight_we,
			weight_data	=> weight_data,
			pixel_in		=> pixel_in,
			pixel_valid	=> pixel_valid,
			pixel_out 	=> pixel_out
	);

	clock : process
	begin
		clk <= '1';
		wait for clk_period/2;
		clk <= '0';
		wait for clk_period/2;
	end process;

	test_input : PROCESS
	BEGIN
		reset <= '1';
		wait for clk_period*10;

	  -- Add user defined stimulus here

	  wait; -- will wait forever
	END PROCESS;

END;
