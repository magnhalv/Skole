library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
library ieee_proposed;
use ieee_proposed.fixed_float_types.all;
use ieee_proposed.fixed_pkg.all;

entity sigmoid is
	Port (
		clk 	: in std_logic;
		x 		: in  ufixed (7 downto -8);
		y 		: out ufixed(7 downto -8));
end sigmoid;
 
architecture Behavioral of sigmoid is
	signal y_product 				: ufixed(8 downto -16);
	signal y_sum 					: ufixed(9 downto -16);
	signal y_a						: ufixed(0 downto -8);
	signal y_b 						: ufixed(0 downto -5);
	signal interval1 				: ufixed(7 downto -8);
	signal interval2 				: ufixed(7 downto -8); 
	signal interval3 				: ufixed(7 downto -8);
	signal interval4				: ufixed(7 downto -8);
begin

	interval1 <= to_ufixed(5, 7, -8);
	interval2 <= to_ufixed(2.375, 7, -8);
	interval3 <= to_ufixed(1, 7, -8);
	interval4 <= to_ufixed(0, 7, -8);

	set_c: process(clk)
	begin 
		if rising_edge(clk) then
			if (x >= interval1) then
				y_a <= to_ufixed(0, y_a);
				y_b <= to_ufixed(1, y_b);
			elsif(x >= interval2) then
				y_a <= to_ufixed(0.03125, y_a);
				y_b <= to_ufixed(0.84375, y_b);
			elsif(x >= interval3) then
				y_a <= to_ufixed(0.0125, y_a);
				y_b <= to_ufixed(0.625, y_b);
			elsif (x >= interval4) then
				y_a <= to_ufixed(0.25, y_a);
				y_b <= to_ufixed(0.5, y_b);
			else 
				y_a <= (others => '0');
				y_b <= (others => '0');
			end if;
		end if;
	end process;
	
	calculate_y : process(x, y_a, y_b, y_sum, y_product) 
	begin
		y_product <= x*y_a;
		y_sum <= y_product + y_b;
		y <= y_sum(7 downto -8);
	end process;
end Behavioral;

