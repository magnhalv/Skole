LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

library ieee_proposed;
use ieee_proposed.fixed_float_types.all;
use ieee_proposed.fixed_pkg.all;

ENTITY max_pool_tb IS
	generic (
			POOL_DIM 	: positive := 2;
			INT_WIDTH 	: positive := 8;
			FRAC_WIDTH 	: positive := 8
	);
END max_pool_tb;
 
ARCHITECTURE behavior OF max_pool_tb IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
	 
	component max_pool
		generic (
			POOL_DIM 	: positive := POOL_DIM;
			INT_WIDTH 	: positive := INT_WIDTH;
			FRAC_WIDTH 	: positive := FRAC_WIDTH
		);
		Port ( 
			clk 				: in std_logic;
			conv_en			: in std_logic;
			input_valid		: in std_logic;
			data_in			: in ufixed(INT_WIDTH-1 downto -FRAC_WIDTH);
			data_out			: out ufixed(INT_WIDTH-1 downto -FRAC_WIDTH);
			output_valid 	: out std_logic
			
		);
	end component;


   --Inputs
   signal clk : std_logic := '0';
   signal conv_en : std_logic := '0';
   signal input_valid : std_logic := '0';
   signal data_in : ufixed(INT_WIDTH-1 downto -FRAC_WIDTH) := (others => '0');

 	--Outputs
   signal data_out : ufixed(INT_WIDTH-1 downto -FRAC_WIDTH);
   signal output_valid : std_logic;

   -- Clock period definitions
   constant clk_period : time := 1 ns;
	
	signal expected1 : ufixed(INT_WIDTH-1 downto -FRAC_WIDTH); 
	signal expected2 : ufixed(INT_WIDTH-1 downto -FRAC_WIDTH); 
	signal expected3 : ufixed(INT_WIDTH-1 downto -FRAC_WIDTH); 
	signal expected4 : ufixed(INT_WIDTH-1 downto -FRAC_WIDTH); 
 
BEGIN
 
	expected1 <= to_ufixed(4, expected1);
	expected2 <= to_ufixed(201, expected2);
	expected3 <= to_ufixed(0.3, expected3);
	expected4 <= to_ufixed(255, expected4);
	-- Instantiate the Unit Under Test (UUT)
   uut: max_pool PORT MAP (
          clk => clk,
          conv_en => conv_en,
          input_valid => input_valid,
          data_in => data_in,
          data_out => data_out,
          output_valid => output_valid
        );

   -- Clock process definitions
   clk_process :process
   begin
		clk <= '1';
		wait for clk_period/2;
		clk <= '0';
		wait for clk_period/2;
   end process;
 

   -- Stimulus process
   input_proc: process
   begin		
      wait for 10*clk_period;
		
		conv_en <= '1';
		
		wait for 16*clk_period;
		
		-- row 1
		
		input_valid <= '1';
		data_in <= to_ufixed(4, data_in);
		wait for clk_period;

		data_in <= to_ufixed(3, data_in);
		wait for clk_period;
		
		data_in <= to_ufixed(90, data_in);
		wait for clk_period;
		
		data_in <= to_ufixed(201, data_in);
		wait for clk_period;
		input_valid <= '0';
		
		wait for clk_period*2; 
		
		-- row 2
		input_valid <= '1';
		data_in <= to_ufixed(2, data_in);
		wait for clk_period;

		data_in <= to_ufixed(1, data_in);
		wait for clk_period;
		
		data_in <= to_ufixed(200, data_in);
		wait for clk_period;
		
		data_in <= to_ufixed(153, data_in);
		wait for clk_period;
		input_valid <= '0';
		
		wait for clk_period*2;
		
		-- row 3
		input_valid <= '1';
		data_in <= to_ufixed(0.1, data_in);
		wait for clk_period;

		data_in <= to_ufixed(0.2, data_in);
		wait for clk_period;
		
		data_in <= to_ufixed(255, data_in);
		wait for clk_period;
		
		data_in <= to_ufixed(221, data_in);
		wait for clk_period;
		input_valid <= '0';
		
		wait for clk_period*2; 
		
		-- row 4
		
		input_valid <= '1';
		data_in <= to_ufixed(0.30, data_in);
		wait for clk_period;

		data_in <= to_ufixed(0.15, data_in);
		wait for clk_period;
		
		data_in <= to_ufixed(240, data_in);
		wait for clk_period;
		
		data_in <= to_ufixed(128, data_in);
		wait for clk_period;
		input_valid <= '0';
		conv_en <= '0';
	
      wait;
   end process;
	
	assert_result : process
	begin
	wait for clk_period*26;
	
	wait for clk_period*8;
	
	assert data_out = expected1
		report "Test 1. Data out was " & to_string(data_out) & ". Expected " & to_string(expected1)
		severity error;
	
	wait for clk_period*2;
	
	assert data_out = expected2
		report "Test 2. Data out was " & to_string(data_out) & ". Expected " & to_string(expected2)
		severity error;
		
	wait for clk_period*9;
	
	assert data_out = expected3
		report "Test 3. Data out was " & to_string(data_out) & ". Expected " & to_string(expected3)
		severity error;
		
	wait for clk_period*2;
	
	assert data_out = expected4
		report "Test 4. Data out was " & to_string(data_out) & ". Expected " & to_string(expected4)
		severity error;
	
	wait;
	end process;

END;
