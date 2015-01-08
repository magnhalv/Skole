-- Part of TDT4255 Computer Design laboratory exercises
-- Group for Computer Architecture and Design
-- Department of Computer and Information Science
-- Norwegian University of Science and Technology

-- blinky.vhd
-- See the accompanying compendium for more information.
-- An LED blinker, for the second part of the VHDL tutorial
-- The module is centered around a register, which stores an 
-- unsigned integer value and is incremented by one for every 
-- clock tick. The register is reset to 0 when it reaches
-- the value of ticksForPeriod. Additionally, a comparator
-- is used to generate the high/low levels at the output.

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity blinky is
	generic (
		ticksBeforeLevelChange : integer := 24000000;
		ticksForPeriod : integer := 48000000
	);
	port ( 
		clk, reset : in  STD_LOGIC;
		pulse : out  STD_LOGIC
	);
end blinky;

architecture Behavioral of blinky is
	signal tickCount : unsigned(31 downto 0);
begin
	CountPeriodTicks: process(clk, reset)
	begin
		if reset = '1' then
			-- note the others <= '0' syntax; this is useful
			-- for generating a sequence of zeroes of the appropriate
			-- length
			tickCount <= (others => '0');
		elsif rising_edge(clk) then
			if tickCount < ticksForPeriod then
				-- period not complete, increment ticks
				tickCount <= tickCount + 1;
			else
				-- period reached, back to zero ticks
				tickCount <= (others => '0');
			end if;
		end if;
	end process;
	-- drive the output depending on the counter value
	pulse <= '0' when tickCount < ticksBeforeLevelChange
				else '1';
end Behavioral;

