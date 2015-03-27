library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
library ieee_proposed;
use ieee_proposed.fixed_float_types.all;
use ieee_proposed.fixed_pkg.all;

entity tan_h is
    generic (
        INT_WIDTH : Natural := 16;
        FRAC_WIDTH : Natural := 16;
        CONST_INT_WIDTH : Natural := 16;
        CONST_FRAC_WIDTH : Natural := 16
    );
	Port (
		clk : in std_logic;
		x : in  sfixed (INT_WIDTH-1 downto -FRAC_WIDTH);
		y : out sfixed (INT_WIDTH-1 downto -FRAC_WIDTH)
	);
end tan_h;
 
architecture Behavioral of tan_h is

	constant m1 : sfixed(CONST_INT_WIDTH-1 downto -CONST_FRAC_WIDTH) := to_sfixed(-0.54324*0.5, CONST_INT_WIDTH-1, -CONST_FRAC_WIDTH); 
	constant m2 : sfixed(CONST_INT_WIDTH-1 downto -CONST_FRAC_WIDTH) := to_sfixed(-0.16957*0.5, CONST_INT_WIDTH-1, -CONST_FRAC_WIDTH);
	constant c1 : sfixed(CONST_INT_WIDTH-1 downto -CONST_FRAC_WIDTH) := to_sfixed(1, CONST_INT_WIDTH-1, -CONST_FRAC_WIDTH);
	constant c2 : sfixed(CONST_INT_WIDTH-1 downto -CONST_FRAC_WIDTH) := to_sfixed(0.42654, CONST_INT_WIDTH-1, -CONST_FRAC_WIDTH);
	constant d1 : sfixed(CONST_INT_WIDTH-1 downto -CONST_FRAC_WIDTH) := to_sfixed(0.016, CONST_INT_WIDTH-1, -CONST_FRAC_WIDTH);
	constant d2 : sfixed(CONST_INT_WIDTH-1 downto -CONST_FRAC_WIDTH) := to_sfixed(0.4519, CONST_INT_WIDTH-1, -CONST_FRAC_WIDTH);
	constant a : sfixed(CONST_INT_WIDTH-1 downto -CONST_FRAC_WIDTH) := to_sfixed(1.52, CONST_INT_WIDTH-1, -CONST_FRAC_WIDTH);
	constant b : sfixed(CONST_INT_WIDTH-1 downto -CONST_FRAC_WIDTH) := to_sfixed(2.57, CONST_INT_WIDTH-1, -CONST_FRAC_WIDTH);
	
	signal abs_x : sfixed(INT_WIDTH-1 downto -FRAC_WIDTH);
	signal pow_x : sfixed(INT_WIDTH-1 downto -FRAC_WIDTH);
	signal signed_bit : std_logic;
	signal tanh_x : sfixed(INT_WIDTH-1 downto -FRAC_WIDTH);
	
	signal term1 : sfixed(INT_WIDTH-1 downto -FRAC_WIDTH);
	signal term2 : sfixed(INT_WIDTH-1 downto -FRAC_WIDTH);
	
begin

    abs_x <= resize(abs(x), abs_x); -- Absolute value of x
    pow_x <= resize(abs_x*abs_x, INT_WIDTH-1, -FRAC_WIDTH);
    signed_bit <= x(INT_WIDTH-1);
    
    
    set_output: process(clk)
    begin 
        if rising_edge(clk) then
            if signed_bit = '1' then
                y <= resize(-tanh_x, INT_WIDTH-1, -FRAC_WIDTH);
            else
                y <= tanh_x;
            end if;
        end if;
    end process;
    
    aprox_tanh : process(abs_x, pow_x, term1, term2, signed_bit )
    begin
        if abs_x <= a and abs_x >= 0 then
            tanh_x <= resize(m1*pow_x+c1*abs_x + d1, INT_WIDTH-1, -FRAC_WIDTH);
        elsif abs_x <= b and abs_x > a then
            tanh_x <= resize(m2*pow_x + c2*abs_x + d2, INT_WIDTH-1, -FRAC_WIDTH);
        else
            tanh_x <= to_sfixed(1, INT_WIDTH-1, -FRAC_WIDTH);
        end if; 
        
    end process;
        

	
end Behavioral;
