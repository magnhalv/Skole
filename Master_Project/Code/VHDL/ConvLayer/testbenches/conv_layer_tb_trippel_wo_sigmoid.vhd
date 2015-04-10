		library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library ieee_proposed;
use ieee_proposed.fixed_float_types.all;
use ieee_proposed.fixed_pkg.all;

ENTITY conv_layer_tb_trippel_wo_sig IS
	generic (
		IMG_DIM 			: Natural := 6;
		KERNEL_DIM 		: Natural := 3;
		MAX_POOL_DIM 	: Natural := 2;
		INT_WIDTH 		: Natural := 8;
		FRAC_WIDTH 		: Natural := 8
	);
END conv_layer_tb_trippel_wo_sig;

ARCHITECTURE behavior OF conv_layer_tb_trippel_wo_sig IS 

	component convolution_layer is
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
			layer_nr	: in std_logic;
			weight_we	: in std_logic;
			weight_data	: in ufixed(INT_WIDTH-1 downto -FRAC_WIDTH);
			pixel_in		: in ufixed(INT_WIDTH-1 downto -FRAC_WIDTH);
			pixel_valid	: out std_logic;
			pixel_out 	: out ufixed(INT_WIDTH-1 downto -FRAC_WIDTH);
			dummy_bias	: out ufixed(INT_WIDTH-1 downto -FRAC_WIDTH)
		);
	end component;
	
	signal clk 				: std_logic := '0';
	signal reset			: std_logic := '0';
	signal conv_en			: std_logic := '0';
	signal layer_nr	: std_logic := '0';
	signal weight_we		: std_logic := '0';
	signal weight_data	: ufixed(INT_WIDTH-1 downto -FRAC_WIDTH) := (others => '0');
	signal pixel_in		: ufixed(INT_WIDTH-1 downto -FRAC_WIDTH) := (others => '0');
	signal pixel_valid	: std_logic := '0';
	signal pixel_out 		: ufixed(INT_WIDTH-1 downto -FRAC_WIDTH) := (others => '0');
	signal dummy_bias		: ufixed(INT_WIDTH-1 downto -FRAC_WIDTH) := (others => '0');
	
	constant clk_period : time := 1 ns;
	
	-- INPUT/OUTPUT
	
	constant zero 	: ufixed(INT_WIDTH-1 downto -FRAC_WIDTH) := "0000000000000000";
	constant one 	: ufixed(INT_WIDTH-1 downto -FRAC_WIDTH) := "0000000100000000";
	constant two 	: ufixed(INT_WIDTH-1 downto -FRAC_WIDTH) := "0000001000000000";
	constant three : ufixed(INT_WIDTH-1 downto -FRAC_WIDTH) := "0000001100000000";
	constant four 	: ufixed(INT_WIDTH-1 downto -FRAC_WIDTH) := "0000010000000000";
	constant five 	: ufixed(INT_WIDTH-1 downto -FRAC_WIDTH) := "0000010100000000";
	
	constant result0 	: ufixed(INT_WIDTH-1 downto -FRAC_WIDTH) := to_ufixed(43, 7, -8);
	constant result1 	: ufixed(INT_WIDTH-1 downto -FRAC_WIDTH) := to_ufixed(54, 7, -8);
	constant result2 	: ufixed(INT_WIDTH-1 downto -FRAC_WIDTH) := to_ufixed(69, 7, -8);
	constant result3 	: ufixed(INT_WIDTH-1 downto -FRAC_WIDTH) := to_ufixed(49, 7, -8);
	constant result4 	: ufixed(INT_WIDTH-1 downto -FRAC_WIDTH) := to_ufixed(104, 7, -8);
	constant result5 	: ufixed(INT_WIDTH-1 downto -FRAC_WIDTH) := to_ufixed(122, 7, -8);
	constant result6 	: ufixed(INT_WIDTH-1 downto -FRAC_WIDTH) := to_ufixed(116, 7, -8);
	constant result7 	: ufixed(INT_WIDTH-1 downto -FRAC_WIDTH) := to_ufixed(101, 7, -8);
	constant result8 	: ufixed(INT_WIDTH-1 downto -FRAC_WIDTH) := to_ufixed(161, 7, -8);
	constant result9 	: ufixed(INT_WIDTH-1 downto -FRAC_WIDTH) := to_ufixed(174, 7, -8);
	constant result10	: ufixed(INT_WIDTH-1 downto -FRAC_WIDTH) := to_ufixed(170, 7, -8);
	constant result11	: ufixed(INT_WIDTH-1 downto -FRAC_WIDTH) := to_ufixed(147, 7, -8);
	
	constant OUTPUT_DIM : Natural := (IMG_DIM-KERNEL_DIM+1)/MAX_POOL_DIM;
	type img_array is array ((IMG_DIM*IMG_DIM)-1 downto 0) of ufixed(INT_WIDTH-1 downto -FRAC_WIDTH);
	type kernel_array is array ((KERNEL_DIM*KERNEL_DIM) downto 0) of ufixed(INT_WIDTH-1 downto -FRAC_WIDTH);
	type pooled_array is array (11 downto 0) of ufixed(INT_WIDTH-1 downto -FRAC_WIDTH);
	
	signal img1 : img_array := (
		one, one, two, zero, one, one, 
		two, zero, four, one, four, four, 
		one, four, three, three, one, one, 
		three, five, three, one, one, five, 
		three, three, five, three, zero, five, 
		three, three, five, three, zero, one

	);
	
	signal img2 : img_array := (
		one, two, two, three, three, three, 
		zero, three, five, five, four, three, 
		four, one, five, zero, two, four, 
		two, zero, five, five, five, four, 
		three, one, three, five, five, one, 
		five, one, one, two, two, two
	);
	
	signal img3 : img_array := (
		two, two, four, three, five, five, 
		zero, five, five, one, four, zero, 
		three, two, five, two, five, one, 
		zero, zero, three, one, three, one, 
		one, two, three, zero, three, five, 
		one, two, two, one, four, one
	);
	
	signal kernel : kernel_array := (
		three, three, four, 
		zero, zero, two, 
		one, zero, four,
		three
	);
	
	signal result : pooled_array := (
		result11, result10, result9, result8,
		result7, result6, result5, result4,
		result3, result2, result1, result0
	);
	
	signal nof_outputs : Natural := 0;
	
       
begin

	conv_layer : convolution_layer port map ( 
		clk 			=> clk,
		reset			=> reset,
		conv_en		=> conv_en,
		layer_nr	=> layer_nr,
		weight_we	=> weight_we,
		weight_data	=> weight_data,
		pixel_in		=> pixel_in,
		pixel_valid	=> pixel_valid,
		pixel_out 	=> pixel_out,
		dummy_bias	=> dummy_bias
	);

	clock : process
	begin
		clk <= '0';
		wait for clk_period/2;
		clk <= '1';
		wait for clk_period/2;
	end process;
	
	create_input : process
	begin 
		layer_nr <= '0';
		reset <= '1';
		weight_we <= '1';
		for i in 0 to (KERNEL_DIM*KERNEL_DIM) loop
			weight_data <= kernel(i);
			wait for clk_period;
		end loop;
		weight_we <= '0';
		wait for clk_period;
		
		conv_en <= '1';
		for i in 0 to (IMG_DIM*IMG_DIM)-1 loop
			pixel_in <= img1((IMG_DIM*IMG_DIM)-1-i);
			wait for clk_period;
		end loop;
		
		for i in 0 to (IMG_DIM*IMG_DIM)-1 loop
			pixel_in <= img2((IMG_DIM*IMG_DIM)-1-i);
			wait for clk_period;
		end loop;
		
		for i in 0 to (IMG_DIM*IMG_DIM)-1 loop
			pixel_in <= img3((IMG_DIM*IMG_DIM)-1-i);
			wait for clk_period;
		end loop;
		conv_en <= '0';
		wait; 
	end process;
	
	assert_outputs : process(clk)
	begin
		if rising_edge(clk) then
			if (pixel_valid ='1') then
				assert pixel_out = result(nof_outputs)
					report "Output nr. " & Natural'image(nof_outputs) & ". Expected value: " &
						to_string(result(nof_outputs)) & ". Actual value: " & to_string(pixel_out) & "."
					severity error;
				nof_outputs <= nof_outputs + 1;
			end if;
		end if; 
	end process;
	
	assert_correct_nof_outputs : process(clk)
	begin
		if rising_edge(clk) then
			if (nof_outputs >= 12) then
				assert nof_outputs = 12
					report "More values was set as valid outputs than expected!"
					severity error;
			end if;
		end if;
	end process;
	

end;
