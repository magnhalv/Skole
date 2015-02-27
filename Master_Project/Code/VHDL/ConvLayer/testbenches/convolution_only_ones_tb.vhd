library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library ieee_proposed;
use ieee_proposed.fixed_float_types.all;
use ieee_proposed.fixed_pkg.all;
  
ENTITY convolution_only_ones_tb IS
	generic 	(
		IMAGE_DIM	: Natural := 8;
		KERNEL_DIM 	: Natural := 3;
		INT_WIDTH	: Natural := 8;
		FRAC_WIDTH	: Natural := 8
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
			weight_data 		: in ufixed(INT_WIDTH-1 downto -FRAC_WIDTH);
			pixel_in 			: in ufixed(INT_WIDTH-1 downto -FRAC_WIDTH);
			output_valid		: out std_logic; 
			conv_en_out			: out std_logic;
			pixel_out 			: out ufixed(INT_WIDTH-1 downto -FRAC_WIDTH);
			bias 				: out ufixed(INT_WIDTH-1 downto -FRAC_WIDTH)
		);
	END COMPONENT;

	constant zero 	: ufixed(INT_WIDTH-1 downto -FRAC_WIDTH) := "0000000000000000";
	constant one 	: ufixed(INT_WIDTH-1 downto -FRAC_WIDTH) := "0000000100000000";
	constant two 	: ufixed(INT_WIDTH-1 downto -FRAC_WIDTH) := "0000001000000000";
	constant three : ufixed(INT_WIDTH-1 downto -FRAC_WIDTH) := "0000001100000000";
	constant four 	: ufixed(INT_WIDTH-1 downto -FRAC_WIDTH) := "0000010000000000";
	constant five 	: ufixed(INT_WIDTH-1 downto -FRAC_WIDTH) := "0000010100000000";
	
	constant result0 	: ufixed(INT_WIDTH-1 downto -FRAC_WIDTH) := to_ufixed(9, 7, -8);
	constant result1 	: ufixed(INT_WIDTH-1 downto -FRAC_WIDTH) := to_ufixed(9, 7, -8);
	constant result2 	: ufixed(INT_WIDTH-1 downto -FRAC_WIDTH) := to_ufixed(9, 7, -8);
	constant result3 	: ufixed(INT_WIDTH-1 downto -FRAC_WIDTH) := to_ufixed(9, 7, -8);
	constant result4 	: ufixed(INT_WIDTH-1 downto -FRAC_WIDTH) := to_ufixed(9, 7, -8);
	constant result5 	: ufixed(INT_WIDTH-1 downto -FRAC_WIDTH) := to_ufixed(9, 7, -8);
	constant result6 	: ufixed(INT_WIDTH-1 downto -FRAC_WIDTH) := to_ufixed(9, 7, -8);
	constant result7 	: ufixed(INT_WIDTH-1 downto -FRAC_WIDTH) := to_ufixed(9, 7, -8);
	constant result8 	: ufixed(INT_WIDTH-1 downto -FRAC_WIDTH) := to_ufixed(9, 7, -8);
	constant result9 	: ufixed(INT_WIDTH-1 downto -FRAC_WIDTH) := to_ufixed(9, 7, -8);
	constant result10	: ufixed(INT_WIDTH-1 downto -FRAC_WIDTH) := to_ufixed(9, 7, -8);
	constant result11	: ufixed(INT_WIDTH-1 downto -FRAC_WIDTH) := to_ufixed(9, 7, -8);
	constant result12	: ufixed(INT_WIDTH-1 downto -FRAC_WIDTH) := to_ufixed(9, 7, -8);
	constant result13	: ufixed(INT_WIDTH-1 downto -FRAC_WIDTH) := to_ufixed(9, 7, -8);
	constant result14	: ufixed(INT_WIDTH-1 downto -FRAC_WIDTH) := to_ufixed(9, 7, -8);
	constant result15	: ufixed(INT_WIDTH-1 downto -FRAC_WIDTH) := to_ufixed(9, 7, -8);
	
	
	type img_array is array (IMAGE_DIM*IMAGE_DIM-1 downto 0) of ufixed(INT_WIDTH-1 downto -FRAC_WIDTH);
	type kernel_array is array (KERNEL_DIM*KERNEL_DIM downto 0) of ufixed(INT_WIDTH-1 downto -FRAC_WIDTH);
	type conv_array is array (15 downto 0) of ufixed(INT_WIDTH-1 downto -FRAC_WIDTH);
	
	signal image 	: img_array := (
		one, one, one, one, one, one, one, one,
		one, one, one, one, one, one, one, one,
		one, one, one, one, one, one, one, one,
		one, one, one, one, one, one, one, one,
		one, one, one, one, one, one, one, one,
		one, one, one, one, one, one, one, one,
		one, one, one, one, one, one, one, one,
		one, one, one, one, one, one, one, one
	);
	
	signal kernel 	: kernel_array := (
		one, one, one, 
		one, one, one, 
		one, one, one,
		two -- bias
		);
		
	signal result : conv_array := (
		result15, result14, result13, result12,
		result11, result10, result9, result8,
		result7, result6, result5, result4,
		result3, result2, result1, result0);
		 

	signal clk			   : std_logic := '0';
	signal reset		   : std_logic := '1';
	signal conv_en_in	   : std_logic := '0';
	signal layer_nr        : std_logic := '0';
	signal weight_we	   : std_logic := '0';
	signal weight_data     : ufixed(INT_WIDTH-1 downto -FRAC_WIDTH) := (others => '0');
    signal pixel_in        : ufixed(INT_WIDTH-1 downto -FRAC_WIDTH) := (others => '0');
	signal output_valid    : std_logic; 
	signal pixel_out       : ufixed(INT_WIDTH-1 downto -FRAC_WIDTH);
	signal conv_en_out     : std_logic;
	signal bias_out        : ufixed(INT_WIDTH-1 downto -FRAC_WIDTH);
	
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
			weight_data <= kernel(i);
			wait for clk_period;
		end loop;
		
		weight_we <= '0';
		wait;
		
	end process;
	
	
	create_input : PROCESS
	BEGIN
		wait for clk_period*(KERNEL_DIM*KERNEL_DIM+3); -- wait until weights are loaded. 
		conv_en_in <= '1';
		for test_nr in 0 to Nof_Convs-1 loop
			for i in 0 to ((IMAGE_DIM*IMAGE_DIM)-1) loop
				pixel_in <= image(IMAGE_DIM*IMAGE_DIM-1-i);
				wait for clk_period;
			end loop;
		end loop;
		conv_en_in <= '0';
		
		wait; -- will wait forever
	END PROCESS;
	
	assert_outputs : process(clk)
		variable convs_tested : Natural := 0;
	begin
		if rising_edge(clk) then
			if (convs_tested < Nof_Convs) then
				if (output_valid ='1') then
					assert pixel_out = result(nof_outputs)
						report "Output nr. " & Natural'image(nof_outputs) & ". Expected value: " &
							to_string(result(nof_outputs)) & ". Actual value: " & to_string(pixel_out) & "."
						severity error;
					if (nof_outputs = 15) then
						convs_tested := convs_tested + 1;
						nof_outputs <= 0;
					else
						nof_outputs <= nof_outputs + 1;
					end if;
				end if;
			end if;
		end if; 
	end process;
	
	assert_correct_nof_outputs : process(clk)
	begin
		if rising_edge(clk) then
			if (nof_outputs >= 32) then
				assert nof_outputs = 32
					report "More values was set as valid outputs than expected!"
					severity error;
			end if;
		end if;
	end process;
--  End Test Bench 

END;
