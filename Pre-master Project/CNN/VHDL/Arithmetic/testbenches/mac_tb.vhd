library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
library ieee_proposed;
use ieee_proposed.fixed_float_types.all;
use ieee_proposed.fixed_pkg.all;

  ENTITY mac_tb IS
  END mac_tb;

  ARCHITECTURE behavior OF mac_tb IS 

  -- Component Declaration
          COMPONENT mac
				Port ( 	
					clk : in  STD_LOGIC;
					weight_we : in  STD_LOGIC;
					weight_data : in  ufixed(7 downto -8);
					multi_value : in  ufixed(7 downto -8);
					acc_value : in  ufixed(7 downto -8);
					result : out  ufixed(7 downto -8)
				);
			end component;

          signal clk :  std_logic;
          signal weight_we :  std_logic;
			 signal weight_data : ufixed(7 downto -8);
			 signal multi_value : ufixed(7 downto -8);
			 signal acc_value : ufixed(7 downto -8);
			 signal result  : ufixed(7 downto -8);
			 
			 constant clk_period : time := 2 ns;	
			 
			 constant expected0 : ufixed(7 downto -8) := "0000010100000000";
          
			
BEGIN
  
	test_mac: mac PORT MAP(
		clk => clk,
		weight_we => weight_we,
		weight_data => weight_data,
		multi_value => multi_value,
		acc_value => acc_value,
		result => result
   );
  
  clk_process :process
	begin
		clk <= '0';
		wait for clk_period/2;  --for 0.5 ns signal is '0'.
		clk <= '1';
		wait for clk_period/2;  --for next 0.5 ns signal is '1'.
	end process;   


  --  Test Bench Statements
     tb : PROCESS
     BEGIN
			wait for 100 ns;
			wait for clk_period/2;
			weight_we <= '1';
			weight_data <= to_ufixed(2, weight_data);
			
			wait for clk_period;
			weight_we <= '0';
			multi_value <= to_ufixed(2, multi_value);
			acc_value <= to_ufixed(1, acc_value);
			
			wait for clk_period*2;
			assert result = expected0;
			
			wait; -- will wait forever
     END PROCESS tb;
  --  End Test Bench 

  END;
