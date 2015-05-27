library IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

library ieee_proposed;
use ieee_proposed.fixed_float_types.all;
use ieee_proposed.fixed_pkg.all;
use ieee_proposed.float_pkg.all;

entity sfixed_fifo_tb is
    generic (
        constant INT_WIDTH : positive := 16;
        constant FRAC_WIDTH : positive := 16;
        constant FIFO_DEPTH	: positive := 10
    );
end sfixed_fifo_tb;

architecture testbench of sfixed_fifo_tb is

    component sfixed_fifo is
        Generic (
            constant INT_WIDTH : positive := INT_WIDTH;
            constant FRAC_WIDTH : positive := FRAC_WIDTH;
            constant FIFO_DEPTH	: positive := FIFO_DEPTH
        );
        Port ( 
            clk		 : in  std_logic;
            reset	 : in  std_logic;
            write_en : in  std_logic;
            data_in	 : in  sfixed(INT_WIDTH-1 downto -FRAC_WIDTH);
            data_out : out sfixed(INT_WIDTH-1 downto -FRAC_WIDTH)
        );
    end component;

    signal clk		: std_logic := '0';
    signal reset	: std_logic := '0';
    signal write_en : std_logic := '0';
    signal data_in	: sfixed(INT_WIDTH-1 downto -FRAC_WIDTH) := (others => '0');
    signal data_out : sfixed(INT_WIDTH-1 downto -FRAC_WIDTH) := (others => '0');

    constant clk_period : time := 1 ns;

    constant one : sfixed(INT_WIDTH-1 downto -FRAC_WIDTH) := to_sfixed(1, INT_WIDTH-1, -FRAC_WIDTH);
    constant two : sfixed(INT_WIDTH-1 downto -FRAC_WIDTH) := to_sfixed(2, INT_WIDTH-1, -FRAC_WIDTH);
    
begin
    
    fifo : sfixed_fifo port map ( 
        clk => clk,
        reset => reset,
        write_en => write_en,
        data_in	=> data_in,
        data_out => data_out
    );

    clock : process
    begin
        clk <= '0';
        wait for clk_period/2;
        clk <= '1';
        wait for clk_period/2;
    end process;

    create_input : process
    begin
        reset <= '0';
        wait for clk_period*10;
        reset <= '1';
        
        write_en <= '1';
        data_in <= one;
        wait for clk_period*5;
        write_en <= '0';
        wait for clk_period*5;
        data_in <= two;
        write_en <= '1';
        wait for clk_period*5;

        write_en <= '0';
        wait for clk_period*5;

        write_en <= '1';
        data_in <= two;
        wait for clk_period*5;
        write_en <= '0';
        wait for clk_period*5;
        write_en <= '1';
        wait for clk_period*5;
        write_en <= '0';

        wait;
    end process;
    
end;
