library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
library ieee_proposed;
use ieee_proposed.fixed_float_types.all;
use ieee_proposed.fixed_pkg.all;

entity tan_h is
    generic (
        INT_WIDTH : Natural := 16;
        FRAC_WIDTH : Natural := 16
    );
	Port (
		clk 	: in std_logic;
		x 		: in  fixed (7 downto -8);
		y 		: out fixed(7 downto -8)
	);
end tan_h;
 
architecture Behavioral of tan_h is
	signal y_product 				: fixed(8 downto -16);
	signal y_sum 					: fixed(9 downto -16);
	signal y_a						: fixed(0 downto -8);
	signal y_b 						: fixed(0 downto -5);
	signal interval1 				: fixed(7 downto -8);
	signal interval2 				: fixed(7 downto -8); 
	signal interval3 				: fixed(7 downto -8);
	signal interval4				: fixed(7 downto -8);
begin

	interval1 <= to_fixed(5, 7, -8);
	interval2 <= to_fixed(2.375, 7, -8);
	interval3 <= to_fixed(1, 7, -8);
	interval4 <= to_fixed(0, 7, -8);

	set_c: process(clk)
	begin 
		if rising_edge(clk) then
			
		end if;
	end process;
	
	calculate_y : process(x, y_a, y_b, y_sum, y_product) 
	begin
		y_product <= x*y_a;
		y_sum <= y_product + y_b;
		y <= y_sum(7 downto -8);
	end process;
end Behavioral;
