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
		input_valid : in std_logic;
		x : in  sfixed (INT_WIDTH-1 downto -FRAC_WIDTH);
		output_valid : out std_logic;
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
	
	
	-- cx = cycle x.
	signal abs_x : sfixed(INT_WIDTH-1 downto -FRAC_WIDTH);
	signal abs_x_c1 : sfixed(INT_WIDTH-1 downto -FRAC_WIDTH);
	signal abs_x_c2 : sfixed(INT_WIDTH-1 downto -FRAC_WIDTH);
	
	signal pow_x_c1 : sfixed(INT_WIDTH-1 downto -FRAC_WIDTH);
	signal pow_x_c2 : sfixed(INT_WIDTH-1 downto -FRAC_WIDTH);
	
	signal signed_bit_c1 : std_logic;
	signal signed_bit_c2 : std_logic;
	signal signed_bit_c3 : std_logic;
	
	signal input_valid_c1 : std_logic;
	signal input_valid_c2 : std_logic;
	signal input_valid_c3 : std_logic;
	
	signal tanh_x_c3 : sfixed(INT_WIDTH-1 downto -FRAC_WIDTH);
	
	signal term1_c2 : sfixed(INT_WIDTH-1 downto -FRAC_WIDTH);
	signal term2_c2 : sfixed(INT_WIDTH-1 downto -FRAC_WIDTH);
	signal term3_c2 : sfixed(INT_WIDTH-1 downto -FRAC_WIDTH);
	
begin
    
    abs_x <= resize(abs(x), abs_x); -- Absolute value of x
    
    process_input_c1 : process(clk) 
    begin
        if rising_edge(clk) then
            abs_x_c1 <= abs_x;
            pow_x_c1 <= resize(abs_x*abs_x, INT_WIDTH-1, -FRAC_WIDTH);
            signed_bit_c1 <= x(INT_WIDTH-1);
            input_valid_c1 <= input_valid;
        end if;
    end process;
    
    
    calculate_terms_c2 : process(clk)
    begin
        if rising_edge(clk) then
            signed_bit_c2 <= signed_bit_c1;
            input_valid_c2 <= input_valid_c1;
            if abs_x_c1 <= a and abs_x_c1 >= 0 then
                term1_c2 <= resize(m1*pow_x_c1, INT_WIDTH-1, -FRAC_WIDTH);
                term2_c2 <= resize(c1*abs_x_c1, INT_WIDTH-1, -FRAC_WIDTH);
                term3_c2 <= d1;
            elsif abs_x_c1 <= b and abs_x_c1 > a then
                term1_c2 <= resize(m2*pow_x_c1, INT_WIDTH-1, -FRAC_WIDTH);
                term2_c2 <= resize(c2*abs_x_c1, INT_WIDTH-1, -FRAC_WIDTH);
                term3_c2 <= d2;
            else
                term1_c2 <= (others => '0');
                term2_c2 <= (others => '0');
                term3_c2 <= to_sfixed(1, INT_WIDTH-1, -FRAC_WIDTH);
            end if;
        end if;
    end process;
    
    add_terms_c3 : process(clk) 
    begin
        if rising_edge(clk) then
            signed_bit_c3 <= signed_bit_c2;
            input_valid_c3 <= input_valid_c2;
            tanh_x_c3 <= resize(term1_c2 + term2_c2 + term3_c2, INT_WIDTH-1, -FRAC_WIDTH);
        end if;
    end process;
    
    set_output_c4: process(clk)
        begin 
            if rising_edge(clk) then
                if signed_bit_c3 = '1' then
                    y <= resize(-tanh_x_c3, INT_WIDTH-1, -FRAC_WIDTH);
                else
                    y <= tanh_x_c3;
                end if;
                output_valid <= input_valid_c3;
            end if;
        end process;
        

	
end Behavioral;
