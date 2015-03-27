library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library ieee_proposed;
use ieee_proposed.fixed_float_types.all;
use ieee_proposed.fixed_pkg.all;
  
ENTITY convolution_signed_tb IS
	generic 	(
		IMAGE_DIM	: Natural := 6;
		KERNEL_DIM 	: Natural := 3;
		INT_WIDTH	: Natural := 8;
		FRAC_WIDTH	: Natural := 8
	);
END convolution_signed_tb;

ARCHITECTURE behavior OF convolution_signed_tb IS 

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
			conv_en			    : in std_logic;
			weight_we			: in std_logic;
			weight_data 		: in sfixed(INT_WIDTH-1 downto -FRAC_WIDTH);
			pixel_in 			: in sfixed(INT_WIDTH-1 downto -FRAC_WIDTH);
			output_valid		: out std_logic; 
			conv_en_out			: out std_logic;
			pixel_out 			: out sfixed(INT_WIDTH-1 downto -FRAC_WIDTH);
			bias				: out sfixed(INT_WIDTH-1 downto -FRAC_WIDTH)
		);
	END COMPONENT;

	constant n_one : sfixed(INT_WIDTH-1 downto -FRAC_WIDTH) := to_sfixed(-1, INT_WIDTH-1,-FRAC_WIDTH);
	constant n_two : sfixed(INT_WIDTH-1 downto -FRAC_WIDTH) := to_sfixed(-2, INT_WIDTH-1, -FRAC_WIDTH);
    constant n_three : sfixed(INT_WIDTH-1 downto -FRAC_WIDTH) := to_sfixed(-3, INT_WIDTH-1, -FRAC_WIDTH);
	constant n_four : sfixed(INT_WIDTH-1 downto -FRAC_WIDTH) := to_sfixed(-4, INT_WIDTH-1, -FRAC_WIDTH);
	constant n_five : sfixed(INT_WIDTH-1 downto -FRAC_WIDTH) := to_sfixed(-5, INT_WIDTH-1, -FRAC_WIDTH);
	constant zero : sfixed(INT_WIDTH-1 downto -FRAC_WIDTH) := to_sfixed(0, INT_WIDTH-1, -FRAC_WIDTH);
	constant one: sfixed(INT_WIDTH-1 downto -FRAC_WIDTH) := to_sfixed(1, INT_WIDTH-1, -FRAC_WIDTH);
	constant two : sfixed(INT_WIDTH-1 downto -FRAC_WIDTH) := to_sfixed(2, INT_WIDTH-1, -FRAC_WIDTH);
	constant three : sfixed(INT_WIDTH-1 downto -FRAC_WIDTH) := to_sfixed(3, INT_WIDTH-1, -FRAC_WIDTH);
	constant four : sfixed(INT_WIDTH-1 downto -FRAC_WIDTH) := to_sfixed(4, INT_WIDTH-1, -FRAC_WIDTH);
	constant five : sfixed(INT_WIDTH-1 downto -FRAC_WIDTH) := to_sfixed(5, INT_WIDTH-1, -FRAC_WIDTH);
	
	constant result0    : sfixed(INT_WIDTH-1 downto -FRAC_WIDTH) := to_sfixed(7, INT_WIDTH-1, -FRAC_WIDTH);
	constant result1    : sfixed(INT_WIDTH-1 downto -FRAC_WIDTH) := to_sfixed(56, INT_WIDTH-1, -FRAC_WIDTH);
	constant result2    : sfixed(INT_WIDTH-1 downto -FRAC_WIDTH) := to_sfixed(-29, INT_WIDTH-1, -FRAC_WIDTH);
	constant result3    : sfixed(INT_WIDTH-1 downto -FRAC_WIDTH) := to_sfixed(-53, INT_WIDTH-1, -FRAC_WIDTH);
	
	constant result4    : sfixed(INT_WIDTH-1 downto -FRAC_WIDTH) := to_sfixed(16, INT_WIDTH-1, -FRAC_WIDTH);
	constant result5    : sfixed(INT_WIDTH-1 downto -FRAC_WIDTH) := to_sfixed(-19, INT_WIDTH-1, -FRAC_WIDTH);
	constant result6    : sfixed(INT_WIDTH-1 downto -FRAC_WIDTH) := to_sfixed(22, INT_WIDTH-1, -FRAC_WIDTH);
	constant result7    : sfixed(INT_WIDTH-1 downto -FRAC_WIDTH) := to_sfixed(15, INT_WIDTH-1, -FRAC_WIDTH);
	
	constant result8    : sfixed(INT_WIDTH-1 downto -FRAC_WIDTH) := to_sfixed(-11, INT_WIDTH-1, -FRAC_WIDTH);
	constant result9    : sfixed(INT_WIDTH-1 downto -FRAC_WIDTH) := to_sfixed(82, INT_WIDTH-1, -FRAC_WIDTH);
	constant result10    : sfixed(INT_WIDTH-1 downto -FRAC_WIDTH) := to_sfixed(-66, INT_WIDTH-1, -FRAC_WIDTH);
	constant result11    : sfixed(INT_WIDTH-1 downto -FRAC_WIDTH) := to_sfixed(-22, INT_WIDTH-1, -FRAC_WIDTH);
	
	constant result12    : sfixed(INT_WIDTH-1 downto -FRAC_WIDTH) := to_sfixed(-14, INT_WIDTH-1, -FRAC_WIDTH);
	constant result13    : sfixed(INT_WIDTH-1 downto -FRAC_WIDTH) := to_sfixed(-24, INT_WIDTH-1, -FRAC_WIDTH);
	constant result14    : sfixed(INT_WIDTH-1 downto -FRAC_WIDTH) := to_sfixed(41, INT_WIDTH-1, -FRAC_WIDTH);
	constant result15    : sfixed(INT_WIDTH-1 downto -FRAC_WIDTH) := to_sfixed(16, INT_WIDTH-1, -FRAC_WIDTH);

	
	type img_array is array (IMAGE_DIM*IMAGE_DIM-1 downto 0) of sfixed(INT_WIDTH-1 downto -FRAC_WIDTH);
	type kernel_array is array (KERNEL_DIM*KERNEL_DIM downto 0) of sfixed(INT_WIDTH-1 downto -FRAC_WIDTH);
	type conv_array is array (15 downto 0) of sfixed(INT_WIDTH-1 downto -FRAC_WIDTH);
	
	signal image 	: img_array := (
        n_two, five, three, n_one, zero, n_two,
        n_four, one, n_three, n_four, zero, four,
        n_three, n_three, four, n_five, n_four, five,
        five, five, n_two, n_four, three, three,
        three, n_three, three, n_five, n_two, four,
        n_five, n_two, zero, two, two, n_two
	);
	
	
	
	signal kernel 	: kernel_array := (
        n_four, two, two,
        two, n_three, n_five,
        n_two, five, n_three,
		one -- bias
		);
	signal result : conv_array := (
        result15, result14, result13, result12,
        result11, result10, result9, result8, 
        result7, result6, result5, result4, 
        result3, result2, result1, result0
    );
		 

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
        for i in 0 to ((IMAGE_DIM*IMAGE_DIM)-1) loop
            pixel_in <= image(IMAGE_DIM*IMAGE_DIM-1-i);
            wait for clk_period;
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
					if (nof_outputs = 35) then
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
			if (nof_outputs >= 16) then
				assert nof_outputs = 16
					report "More values was set as valid outputs than expected!"
					severity error;
			end if;
		end if;
	end process;
--  End Test Bench 

END;
