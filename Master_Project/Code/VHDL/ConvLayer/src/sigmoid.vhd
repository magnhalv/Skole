library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
library ieee_proposed;
use ieee_proposed.fixed_float_types.all;
use ieee_proposed.fixed_pkg.all;
use ieee_proposed.float_pkg.all;

entity sigmoid is
	Port (
		clk 	: in std_logic;
		x 		: in  float32;
		y 		: out ufixed(15 downto -16)
	);
end sigmoid;
 
architecture Behavioral of sigmoid is
	
begin

	y <= to_ufixed(x, 15, -16);
	
end Behavioral;

