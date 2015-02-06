LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

library ieee_proposed;
use ieee_proposed.fixed_float_types.all;
use ieee_proposed.fixed_pkg.all;

ENTITY tb_sigmoid IS
END tb_sigmoid;

ARCHITECTURE behavior OF tb_sigmoid IS 

  -- Component Declaration
	COMPONENT sigmoid
		Port (
		clk : in STD_LOGIC;
		x : in  ufixed (7 downto -8);
		y : out ufixed(7 downto -8));
	END COMPONENT;
	
	signal clk : std_logic;
	SIGNAL x :  ufixed(7 downto -8);
	SIGNAL y :  ufixed(7 downto -8);
	
	constant clk_period : time := 2 ns;	
	
	constant expected1 : ufixed(7 downto -8) := "0000000100000000";
	constant expected2 : ufixed(7 downto -8) := "0000000100000000";
	constant expected3 : ufixed(7 downto -8) := "0000000011111000";
	constant expected4 : ufixed(7 downto -8) := "0000000011101011";
	constant expected5 : ufixed(7 downto -8) := "0000000010100101";
	constant expected6 : ufixed(7 downto -8) := "0000000010100011";
	
BEGIN

  -- Component Instantiation
   my_sigmoid : sigmoid PORT MAP(
		clk => clk,
      x => x,
		y => y
	);

	clk_process :process
	begin
		clk <= '0';
		wait for clk_period/2;  --for 0.5 ns signal is '0'.
		clk <= '1';
		wait for clk_period/2;  --for next 0.5 ns signal is '1'.
	end process;
	
	tb : PROCESS
	BEGIN
		wait for 100 ns; -- wait until global set/reset completes

		x <= to_ufixed(255, x);
		wait for clk_period;
		assert y=expected1 -- 1
			report "Assertion 1. The value of 'y' is: " & to_string(y) & ". Expected: " & to_string(expected1)
			severity error;
		
		wait for clk_period/2;
		x <= to_ufixed(5, x);
		wait for clk_period/2;
		assert y = expected2 -- 1
			report "Assertion 2. The value of 'y' is: " & to_string(y) & ". Expected: " & to_string(expected2)
			severity error;
		
		wait for clk_period/2;
		x <= to_ufixed(4, x); 
		wait for clk_period/2;
		assert y = expected3 -- 0.96875
			report "Assertion 3. The value of 'y' is: " & to_string(y) & ". Expected: " & to_string(expected3)
			severity error;
		
		wait for clk_period/2;
		x <= to_ufixed(2.375, x);
		wait for clk_period/2;
		assert y = expected4 -- 0.91796875
			report "Assertion 4. The value of 'y' is: " & to_string(y) & ". Expected: " & to_string(expected4)
			severity error;
		
		wait for clk_period/2;
		x <= to_ufixed(1.75, x);
		wait for clk_period/2;
		assert y = expected5 -- 0.646875
			report "Assertion 5. The value of 'y' is: " & to_string(y) & ". Expected: " & to_string(expected5)
			severity error;
		
		wait for clk_period/2;
		x <= to_ufixed(1, x);
		wait for clk_period/2;
		assert y = expected6 -- 0.6375
			report "Assertion 6. The value of 'y' is: " & to_string(y) & ". Expected: " & to_string(expected6)
			severity error;
		
		wait; -- wait forever
	END PROCESS tb;

END;
