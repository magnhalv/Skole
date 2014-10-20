library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
library ieee_proposed;
use ieee_proposed.fixed_float_types.all;
use ieee_proposed.fixed_pkg.all;

entity mac is
    Port ( 	clk : in  STD_LOGIC;
				weight_we : in  STD_LOGIC;
				weight_data : in  ufixed(7 downto -8);
				multi_value : in  ufixed(7 downto -8);
				acc_value : in  ufixed(7 downto -8);
				result : out  ufixed(7 downto -8));
end mac;

architecture Behavioral of mac is
	
	signal weight_reg 	: ufixed(7 downto -8);
	signal sum 				: ufixed(16 downto -16);
	signal product 		: ufixed(15 downto -16);
	signal result_reg		: ufixed(7 downto -8);
	
begin	
	
	weight_register : process(clk) 
	begin
		if rising_edge(clk) then
			
			if(weight_we = '1') then
				weight_reg <= weight_data;
			end if;
		end if;
	end process;
	
	result_register : process(clk) 
	begin
		if rising_edge(clk) then
			result_reg <= sum(7 downto -8);
		end if;
	end process;
	
	mult_and_acc : process(product, weight_reg, acc_value, multi_value) 
	begin
		product <= weight_reg*multi_value;
		sum <= product+acc_value;
	end process;
	
	result <= result_reg;

end Behavioral;

