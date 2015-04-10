library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library ieee_proposed;
use ieee_proposed.fixed_float_types.all;
use ieee_proposed.fixed_pkg.all;

entity sfixed_buffer is
	generic (
		INT_WIDTH 	: Natural := 8;
		FRAC_WIDTH 	: Natural := 8
	);
	Port ( 
        clk : in std_logic;
        reset : in std_logic;
        we : in std_logic;
        data_in : in sfixed(INT_WIDTH-1 downto -FRAC_WIDTH);
        data_out : out sfixed(INT_WIDTH-1 downto -FRAC_WIDTH)
	);
end sfixed_buffer;

architecture Behavioral of sfixed_buffer is
	signal stored_value : sfixed(INT_WIDTH-1 downto -FRAC_WIDTH);
begin

	data_out <= stored_value;
	
	write_data : process(clk)
	begin
		if rising_edge(clk) then
			if (reset ='0') then
				stored_value <= (others => '0');
			elsif (we='1') then
				stored_value <= data_in;
			end if;
		end if;
	end process;


end Behavioral;

