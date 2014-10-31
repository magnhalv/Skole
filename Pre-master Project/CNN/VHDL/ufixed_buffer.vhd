library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

library ieee_proposed;
use ieee_proposed.fixed_float_types.all;
use ieee_proposed.fixed_pkg.all;

entity ufixed_buffer is
	generic (
		INT_WIDTH 	: positive := 8;
		FRAC_WIDTH 	: positive := 8
	);
	Port ( 
		clk 		: in std_logic;
		reset		: in std_logic;
      we 		: in std_logic;
      data_in 	: in ufixed(INT_WIDTH-1 downto -FRAC_WIDTH);
      data_out : out ufixed(INT_WIDTH-1 downto -FRAC_WIDTH)
	);
end ufixed_buffer;

architecture Behavioral of ufixed_buffer is

begin

	write_data : process(clk)
	begin
		if rising_edge(clk) then
			if (reset ='1') then
				data_out <= (others => '0');
			elsif (we='1') then
				data_out <= data_in;
			end if;
		end if;
	end process;


end Behavioral;

