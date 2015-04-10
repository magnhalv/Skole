library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.ALL;

library ieee_proposed;
use ieee_proposed.fixed_float_types.all;
use ieee_proposed.fixed_pkg.all;

entity tanh_tb is
    generic (
        INT_WIDTH : natural := 16;
        FRAC_WIDTH : natural := 16
    );
end tanh_tb;

architecture behavior of tanh_tb is

  -- Component Declaration
	component tan_h
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
	end component;
	
	signal clk : std_logic := '0';
	signal input_valid : std_logic := '0';
	signal x :  sfixed(INT_WIDTH-1 downto -FRAC_WIDTH) := (others => '0');
	signal output_valid : std_logic := '0';
	signal y :  sfixed(INT_WIDTH-1 downto -FRAC_WIDTH) := (others => '0');
	
	constant clk_period : time := 2 ns;	
	
	constant m1 : sfixed(INT_WIDTH-1 downto -FRAC_WIDTH) := to_sfixed(-0.54324, INT_WIDTH-1, -FRAC_WIDTH);
	
begin

    
    tanh_port : tan_h PORT MAP(
        clk => clk,
        input_valid => input_valid,
        x => x,
        output_valid => output_valid,
        y => y
    );

	clk_process :process
	begin
		clk <= '0';
		wait for clk_period/2;  --for 0.5 ns signal is '0'.
		clk <= '1';
		wait for clk_period/2;  --for next 0.5 ns signal is '1'.
	end process;
	
	tb : process
	begin
        wait for clk_period*5;
        input_valid <= '1';
        x <= to_sfixed(0.5, x);
        wait for clk_period;
        x <= to_sfixed(1, x);
        wait for clk_period;
        x <= (others => '0');
        wait for clk_period;
        x <= to_sfixed(-0.5, x);
        wait for clk_period;
        x <= to_sfixed(-1, x);
        wait for clk_period;
        x <= to_sfixed(1.67, x);
        wait for clk_period;
        x <= to_sfixed(-5, x);
        wait for clk_period;
        x <= to_sfixed(-0.26000, x);
        wait for clk_period;
        input_valid <= '0';
        x <= (others => '0');
        wait; -- wait forever
	end process tb;

end;
