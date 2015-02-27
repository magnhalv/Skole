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
        generic (
            INT_WIDTH     : Natural := 8;
            FRAC_WIDTH     : Natural := 8
        );
        Port(     
            clk         : in std_logic;
            reset         : in std_logic;        
            weight_we     : in std_logic;
            weight_in     : in ufixed(INT_WIDTH-1 downto -FRAC_WIDTH);
            multi_value : in ufixed(INT_WIDTH-1 downto -FRAC_WIDTH);
            acc_value     : in ufixed(INT_WIDTH-1 downto -FRAC_WIDTH);
            weight_out    : out ufixed(INT_WIDTH-1 downto -FRAC_WIDTH);
            result         : out ufixed(INT_WIDTH-1 downto -FRAC_WIDTH)
        );
    end component;
    
    signal clk :  std_logic;
    signal reset : std_logic;
    signal weight_we :  std_logic;
    signal weight_in : ufixed(7 downto -8);
    signal multi_value : ufixed(7 downto -8);
    signal acc_value : ufixed(7 downto -8);
    signal weight_out : ufixed(7 downto -8);
    signal result  : ufixed(7 downto -8);
    
    constant clk_period : time := 2 ns;	
    
    constant expected0 : ufixed(7 downto -8) := "0000010100000000";
    constant expected1 : ufixed(7 downto -8) := "0000000100000010";
    constant expected2 : ufixed(7 downto -8) := "0000000000000001";
    constant expected3 : ufixed(7 downto -8) := "0000000000000000";
    
        
BEGIN
  
	test_mac: mac PORT MAP(
		clk => clk,
		reset => reset,
		weight_we => weight_we,
		weight_in => weight_in,
		multi_value => multi_value,
		acc_value => acc_value,
		weight_out => weight_out,
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
			reset <= '0';
			wait for 100 ns;
			
			wait for clk_period/2;
			reset <= '1';
			weight_we <= '1';
			weight_in <= to_ufixed(2, weight_in);
			wait for clk_period;
			
			-- TEST CASE 1: 2*2+1 = 5
			weight_we <= '0';
			multi_value <= to_ufixed(2, multi_value);
			acc_value <= to_ufixed(1, acc_value);
			
			wait for 3*clk_period/2;
			assert result = expected0
				report "Result is " & to_string(result) & ". Expected " & to_string(expected0)
				severity error;
			wait for clk_period/2;
			
			-- TEST CASE 2: 0.00390625*2+1 = 1.0078125
			multi_value <= to_ufixed(0.00390625, multi_value);
			acc_value <= to_ufixed(1, acc_value);
			
			wait for 3*clk_period/2;
			assert result = expected1
				report "Result is " & to_string(result) & ". Expected " & to_string(expected1)
				severity error;
			wait for clk_period/2;	
			
			-- TEST CASE 3: Test lower bound accuracy.
			-- 0.00390625*0.00390625+0.00390625 = 0.00392150879 ~ 0.00390625.
			weight_we <= '1';
			weight_in <= to_ufixed(0.00390625, weight_in);
			wait for clk_period;
			weight_we <= '0';
			
			multi_value <= to_ufixed(0.00390625, multi_value);
			acc_value <= to_ufixed(0.00390625, acc_value);
			
			wait for 3*clk_period/2;
			assert result = expected2
				report "Result is " & to_string(result) & ". Expected " & to_string(expected2)
				severity error;
			wait for clk_period/2;
			
			-- TEST CASE 4 Upper bound accuracy. This shows that if the result is above 255
			-- this module will not give the correct answer!
			-- 128*2 + 0 = 256. The module's result will be 0, due to overflow. 
			weight_we <= '1';
			weight_in <= to_ufixed(2, weight_in);
			wait for clk_period;
			weight_we <= '0';
			
			multi_value <= to_ufixed(128, multi_value);
			acc_value <= to_ufixed(0, acc_value);
			
			wait for 3*clk_period/2;
			assert result = expected3
				report "Result is " & to_string(result) & ". Expected " & to_string(expected3)
				severity error;
			wait for clk_period/2;
			
			
			wait; -- will wait forever
     END PROCESS tb;
  --  End Test Bench 

  END;
