LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
 
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--USE ieee.numeric_std.ALL;
 
ENTITY conv_controller_tb IS
	generic (
		KERNEL_DIM 	: integer := 7;
		IMAGE_DIM 	: integer := 32
	);
END conv_controller_tb;
 
ARCHITECTURE behavior OF conv_controller_tb IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT conv_controller
	 generic (
		IMAGE_DIM : integer := IMAGE_DIM;
		KERNEL_DIM : integer := KERNEL_DIM
	 );
    PORT(
         clk 				: in  std_logic;
         conv_en 			: in  std_logic;
         output_valid 	: out  std_logic
        );
    END COMPONENT;
    

   --Inputs
   signal clk : std_logic := '0';
   signal conv_en : std_logic := '0';

 	--Outputs
   signal output_valid 	: std_logic;

   -- Clock period definitions
   constant clk_period : time := 1 ns;
	constant DELAY_BEFORE_VALID 	: integer := (IMAGE_DIM*(KERNEL_DIM-1)+(KERNEL_DIM+1));
	constant DELAY_BEFORE_FIN		: integer := ((IMAGE_DIM*IMAGE_DIM)-DELAY_BEFORE_VALID+1);
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: conv_controller PORT MAP (
          clk => clk,
          conv_en => conv_en,
          output_valid => output_valid
        );

   -- Clock process definitions
   clk_process :process
   begin
		clk <= '0';
		wait for clk_period/2;
		clk <= '1';
		wait for clk_period/2;
   end process;
 

   -- Stimulus process
   stim_proc: process
   begin		
      -- hold reset state for 100 ns.
      wait for 100 ns;
		
		wait for clk_period/2;
		conv_en <= '1';
      
		wait for clk_period*(DELAY_BEFORE_VALID-1);
		assert output_valid ='0'
			report "Pre-delay. Output was 1. Should be 0."
			severity error;
		
		wait for clk_period;
		assert output_valid ='1'
			report "Pre-delay. Output was 0. Should be 1."
			severity error;
		
		wait for clk_period*(DELAY_BEFORE_FIN-1);
		conv_en <= '0';
		wait for clk_period;
		assert output_valid ='1'
			report "Post-delay. Output was 0. Should be 1."
			severity error;
			
		
	
		wait for clk_period;
		assert output_valid ='0'
			report "Post-delay. Output was 1. Should be 0."
			severity error;
      wait;
		
		wait for clk_period;
   end process;

END;
