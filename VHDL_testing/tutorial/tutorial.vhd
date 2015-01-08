-- Part of TDT4255 Computer Design laboratory exercises
-- Group for Computer Architecture and Design
-- Department of Computer and Information Science
-- Norwegian University of Science and Technology

-- tutorial.vhd
-- See the accompanying compendium for more information.
-- The main VHDL design for the hands-on tutorial, parts 1 and 2
-- Part 1 covers the basic syntax and simple combinational
-- operators. Part 2 extends the design with sequential logic,
-- an LED blinker module.


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tutorial is
    Port ( X : out  STD_LOGIC;
           Y : out  STD_LOGIC;
           Z : out  STD_LOGIC;
           A : in  STD_LOGIC;
           B : in  STD_LOGIC;
           C : in  STD_LOGIC;
			  clk, reset : in std_logic);
end tutorial;

architecture Behavioral of tutorial is
	signal tempSignal1, tempSignal2 : std_logic;
begin
	-- architecture body
	BlinkyInst: entity work.blinky
					--generic map (ticksBeforeLevelChange => 100, ticksForPeriod => 200)
					port map (clk => clk, reset => reset, pulse => X);
					
	-- drive the internal signals from inputs
	DriveInternalSignals: process(B, C) is
	begin
		tempSignal1 <= B or C;
		tempSignal2 <= B xor C;
	end process DriveInternalSignals;
	
	-- drive the outputs
	Y <= tempSignal1;
	Z <= tempSignal1 when A = '1' else tempSignal2;
end Behavioral;

