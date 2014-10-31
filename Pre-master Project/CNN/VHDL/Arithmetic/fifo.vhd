library IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

library ieee_proposed;
use ieee_proposed.fixed_float_types.all;
use ieee_proposed.fixed_pkg.all;
 
entity fifo is
	Generic (
		constant FIFO_DEPTH 	: positive := 32;
		constant FRAC_WIDTH	: positive := 8;
		constant INT_WIDTH	: positive := 8
	);
	Port ( 
		clk     		: in  STD_LOGIC;                                       -- Clock input
		conv_en 		: in  STD_LOGIC;                                       -- Convolution is active
		data_in  	: in  ufixed (INT_WIDTH-1 downto -FRAC_WIDTH);			-- Data input bus
		data_out 	: out ufixed (INT_WIDTH-1 downto -FRAC_WIDTH)			-- Data output bus
	);
end FIFO;
 
architecture Behavioral of fifo is
	signal full : std_logic;
	signal read_en : std_logic;
begin
 
	-- Memory Pointer Process
	fifo_proc : process (clk)
		type FIFO_Memory is array (0 to FIFO_DEPTH - 1) of ufixed (INT_WIDTH-1 downto -FRAC_WIDTH);
		variable Memory : FIFO_Memory;
		
		variable Head : natural range 0 to FIFO_DEPTH - 1;
		variable Tail : natural range 0 to FIFO_DEPTH - 1;

	begin
		if rising_edge(clk) then
			if conv_en = '0' then
				Head := 0;
				Tail := 0;
				full  <= '0';
			else
				if (read_en = '1') then
					-- Update data output
					data_out <= Memory(Tail);
					
					-- Update Tail pointer as needed
					if (Tail = FIFO_DEPTH - 1) then
						Tail := 0;
					else
						Tail := Tail + 1;
					end if;
				end if;
				
				if (conv_en = '1') then -- always write during convolution.
					-- Write Data to Memory
					Memory(Head) := data_in;
					
					-- Increment Head pointer as needed
					if (Head = FIFO_DEPTH - 1) then
						Head := 0;
					else
						Head := Head + 1;
					end if;
				end if;
				
				-- Update full flag
				if (Head = FIFO_DEPTH-1) then
					full <= '1';
				end if;
			end if;
		end if;
	end process;
	
	enable_read : process(full) 
	begin
		if (full='1') then 
			read_en <= '1';
		else
			read_en <= '0';
		end if;
	end process;
		
end Behavioral;