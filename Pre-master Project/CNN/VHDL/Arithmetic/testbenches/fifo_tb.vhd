library IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

library ieee_proposed;
use ieee_proposed.fixed_float_types.all;
use ieee_proposed.fixed_pkg.all;


ENTITY fifo_tb IS
	generic (
		constant INT_WIDTH 	: positive := 8;
		constant FRAC_WIDTH 	: positive := 8;
		constant FIFO_DEPTH 	: positive := 30
	);
END fifo_tb;

ARCHITECTURE behavior OF fifo_tb IS 

  -- Component Declaration
	component fifo
		Generic (
			constant FIFO_DEPTH 	: positive := FIFO_DEPTH;
			constant FRAC_WIDTH	: positive := FRAC_WIDTH;
			constant INT_WIDTH	: positive := INT_WIDTH
		);
		Port ( 
			clk     		: in  STD_LOGIC;                                       	-- Clock input
			conv_en 		: in  STD_LOGIC;                                       	-- Convolution enabled
			data_in  	: in  ufixed (INT_WIDTH-1 downto -FRAC_WIDTH);				-- Data input bus
			data_out 	: out ufixed (INT_WIDTH-1 downto -FRAC_WIDTH)				-- Data output bus
		);
	end component;
	
	signal clk, conv_en : std_logic;
	signal data_in, data_out : ufixed(INT_WIDTH-1 downto -FRAC_WIDTH);
	
	signal expected_output : ufixed (INT_WIDTH-1 downto -FRAC_WIDTH);
	
	constant clk_period : time := 2 ns;
	
          

BEGIN

	fifo_test: fifo PORT MAP(
		clk => clk,
		conv_en => conv_en,
		data_in => data_in,
		data_out => data_out
	);

	clock : process 
	begin
		clk <= '1';
		wait for clk_period/2;
		clk <= '0';
		wait for clk_period/2;
	end process;
	
	tb : PROCESS
	BEGIN
	
		wait for 100 ns;
		conv_en <= '0';
		data_in <= (others => '0');
		wait for clk_period;
		conv_en <= '1';		
		
		for i in 1 to 30 loop
			data_in <= to_ufixed(i, data_in); 
			wait for clk_period;
		end loop;
		
		
		for i in 1 to 40 loop
			data_in <= to_ufixed(i+30, data_in);
			expected_output <= to_ufixed(i, expected_output);
			wait for clk_period/2;
			assert data_out = expected_output
				report "Expected output is " & to_string(expected_output) & ". Actual output is " & to_string(data_out) & "."
				severity error;
			wait for clk_period/2;
		end loop;
		
		conv_en <= '0';
		
		report "Simulation completed.";
		
		wait; 
	END PROCESS tb;

END;
