library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

library ieee_proposed;
use ieee_proposed.fixed_float_types.all;
use ieee_proposed.fixed_pkg.all;
  
ENTITY convolution_tb IS
	generic 	(
		IMAGE_DIM	: integer := 5;
		KERNEL_DIM 	: integer := 3;
		INT_WIDTH	: integer := 8;
		FRAC_WIDTH	: integer := 8
	);
END convolution_tb;

ARCHITECTURE behavior OF convolution_tb IS 

-- Component Declaration
	COMPONENT convolution
		generic 	(
			IMAGE_DIM	: integer := IMAGE_DIM;
			KERNEL_DIM 	: integer := KERNEL_DIM;
			INT_WIDTH	: integer := INT_WIDTH;
			FRAC_WIDTH	: integer := FRAC_WIDTH
		);
		port ( 
			clk					: in std_logic;
			reset					: in std_logic;
			conv_en				: in std_logic;
			weight_we			: in std_logic;
			weight_data 		: in ufixed(INT_WIDTH-1 downto -FRAC_WIDTH);
			pixel_in 			: in ufixed(INT_WIDTH-1 downto -FRAC_WIDTH);
			bias					: in ufixed(INT_WIDTH-1 downto -FRAC_WIDTH);
			output_valid		: out std_logic; 
			final_pixel			: out std_logic;
			pixel_out 			: out ufixed(INT_WIDTH-1 downto -FRAC_WIDTH)
		);
	END COMPONENT;

	signal clk				: std_logic;
	signal reset			: std_logic;
	signal conv_en			: std_logic;
	signal weight_we		: std_logic;
	signal weight_data 	: ufixed(INT_WIDTH-1 downto -FRAC_WIDTH);
	signal pixel_in 		: ufixed(INT_WIDTH-1 downto -FRAC_WIDTH);
	signal bias				: ufixed(INT_WIDTH-1 downto -FRAC_WIDTH);
	signal output_valid	: std_logic; 
	signal final_pixel		: std_logic;
	signal pixel_out 		: ufixed(INT_WIDTH-1 downto -FRAC_WIDTH);
	
	constant clk_period : time := 1 ns;

BEGIN

	convolution_test : convolution port map(
		clk => clk,
		reset => reset,
		conv_en => conv_en,
		weight_we => weight_we,
		weight_data => weight_data,
		pixel_in => pixel_in,
		bias => bias,
		output_valid => output_valid,
		final_pixel => final_pixel,
		pixel_out => pixel_out
	);
	
	clock : process
	begin
		clk <= '1';
		wait for clk_period/2;
		clk <= '0';
		wait for clk_period/2;
	end process;

	create_input : PROCESS
	BEGIN
		reset <= '1';
		wait for clk_period;
		reset <= '0';
		weight_we <= '1';
		weight_data <= to_ufixed(1, weight_data);
		wait for clk_period;
		weight_we <= '0';
		conv_en <= '1';
		bias <= to_ufixed(0, bias);

		for i in 1 to (IMAGE_DIM*IMAGE_DIM) loop
			pixel_in <= to_ufixed(i, pixel_in);
			wait for clk_period;
		end loop;
	  conv_en <= '0';
	  pixel_in <= (others => '0');

		wait; -- will wait forever
	END PROCESS;
	
	assert_output : process(clk)
		variable nof_outputs : integer := 0;
		--variable expected_output : integer :=
	begin
		if rising_edge(clk) then
			if (output_valid ='1') then
				nof_outputs := nof_outputs + 1;
			end if;
		end if;
	end process;
--  End Test Bench 

END;
