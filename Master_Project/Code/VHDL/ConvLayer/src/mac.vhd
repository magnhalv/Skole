library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
library ieee_proposed;
use ieee_proposed.fixed_float_types.all;
use ieee_proposed.fixed_pkg.all;

entity mac is
	generic  (
					INT_WIDTH 	: Natural := 8;
					FRAC_WIDTH 	: Natural := 8
				);
	Port( 	
			clk 		: in std_logic;
			reset 		: in std_logic;		
			weight_we 	: in std_logic;
			weight_in 	: in sfixed(INT_WIDTH-1 downto -FRAC_WIDTH);
			multi_value : in sfixed(INT_WIDTH-1 downto -FRAC_WIDTH);
			acc_value 	: in sfixed(INT_WIDTH-1 downto -FRAC_WIDTH);
			weight_out	: out sfixed(INT_WIDTH-1 downto -FRAC_WIDTH);
			result 		: out sfixed(INT_WIDTH-1 downto -FRAC_WIDTH)
		);
end mac;

architecture Behavioral of mac is
	
	signal weight_reg 	: sfixed(INT_WIDTH-1 downto -FRAC_WIDTH);
	signal sum 			: sfixed(INT_WIDTH*2 downto -FRAC_WIDTH*2);
    signal product      : sfixed((INT_WIDTH*2)-1 downto -FRAC_WIDTH*2);
	
begin	
	
	weight_out <= weight_reg;
	
	weight_register : process(clk) 
	begin
		if rising_edge(clk) then
			if (reset = '0') then
				weight_reg <= (others => '0');
			elsif(weight_we = '1') then
				weight_reg <= weight_in;
			end if;
		end if;
	end process;
	
    result_register : process(clk) 
    begin
        if rising_edge(clk) then
            result <= resize(sum, INT_WIDTH-1, -FRAC_WIDTH);
        end if;
    end process;
    
    mult_and_acc : process(product, weight_reg, acc_value, multi_value) 
    begin
        product <= weight_reg*multi_value;
        sum <= product+acc_value;
    end process;
	

end Behavioral;

