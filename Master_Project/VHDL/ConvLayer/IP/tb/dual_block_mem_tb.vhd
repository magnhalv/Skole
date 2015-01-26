--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   13:32:51 11/13/2014
-- Design Name:   
-- Module Name:   /home/magnus/Github/Skole/Pre-master Project/CNN/VHDL/Memory/tb/dual_block_mem_tb.vhd
-- Project Name:  CNN
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: dual_block_mem
-- 
-- Dependencies:
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
-- Notes: 
-- This testbench has been automatically generated using types std_logic and
-- std_logic_vector for the ports of the unit under test.  Xilinx recommends
-- that these types always be used for the top-level I/O of a design in order
-- to guarantee that the testbench will bind correctly to the post-implementation 
-- simulation model.
--------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
 
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--USE ieee.numeric_std.ALL;
 
ENTITY dual_block_mem_tb IS
END dual_block_mem_tb;
 
ARCHITECTURE behavior OF dual_block_mem_tb IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT dual_block_mem
    PORT(
         clka : IN  std_logic;
         wea : IN  std_logic_vector(0 downto 0);
         addra : IN  std_logic_vector(6 downto 0);
         dina : IN  std_logic_vector(15 downto 0);
         clkb : IN  std_logic;
         addrb : IN  std_logic_vector(6 downto 0);
         doutb : OUT  std_logic_vector(15 downto 0)
        );
    END COMPONENT;
    

   --Inputs
   signal clka : std_logic := '0';
   signal wea : std_logic_vector(0 downto 0) := (others => '0');
   signal addra : std_logic_vector(6 downto 0) := (others => '0');
   signal dina : std_logic_vector(15 downto 0) := (others => '0');
   signal clkb : std_logic := '0';
   signal addrb : std_logic_vector(6 downto 0) := (2=> '1', others => '0');

 	--Outputs
   signal doutb : std_logic_vector(15 downto 0);

   -- Clock period definitions
   constant clka_period : time := 10 ns;
   constant clkb_period : time := 10 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: dual_block_mem PORT MAP (
          clka => clka,
          wea => wea,
          addra => addra,
          dina => dina,
          clkb => clkb,
          addrb => addrb,
          doutb => doutb
        );

   -- Clock process definitions
   clka_process :process
   begin
		clka <= '0';
		wait for clka_period/2;
		clka <= '1';
		wait for clka_period/2;
   end process;
 
   clkb_process :process
   begin
		clkb <= '0';
		wait for clkb_period/2;
		clkb <= '1';
		wait for clkb_period/2;
   end process;
 

   -- Stimulus process
   stim_proc: process
   begin		
      -- hold reset state for 100 ns.
      wait for 100 ns;	

      wait for clka_period*10;
		
		wea <= "1";
		addra <= (others => '0');
		dina <= "0000000000000001";
		wait for clka_period;
		
		addra <= "0000001";
		dina <= "0000000000000010";
		addrb <= (others => '0');
		wait for clka_period;
		
		addra <= "0000010";
		dina <= "0000000000000100";
		addrb <= "0000001";
		assert doutb = "0000000000000001"
			report "First read did not provide expected output."
			severity error;
		
		wait for clka_period;
		assert doutb = "0000000000000010"
			report "Second read did not provide expected output."
			severity error;
		
		
		
		wait for clka_period;
		
		
		

      -- insert stimulus here 

      wait;
   end process;

END;
