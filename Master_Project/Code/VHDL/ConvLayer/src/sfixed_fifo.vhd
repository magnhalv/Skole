library IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

library ieee_proposed;
use ieee_proposed.fixed_float_types.all;
use ieee_proposed.fixed_pkg.all;
use ieee_proposed.float_pkg.all;


entity sfixed_fifo is
	Generic (
		constant INT_WIDTH : natural := 16;
        constant FRAC_WIDTH : natural := 16;
		constant FIFO_DEPTH	: natural := 128
	);
	Port ( 
		clk		 : in  std_logic;
		reset	 : in  std_logic;
		write_en : in  std_logic;
        layer_nr : in  natural;
		data_in	 : in  sfixed(INT_WIDTH-1 downto -FRAC_WIDTH);
		data_out : out sfixed(INT_WIDTH-1 downto -FRAC_WIDTH)
	);
end sfixed_fifo;

architecture Behavioral of sfixed_fifo is

    type FIFO_Memory is array (0 to FIFO_DEPTH - 1) of sfixed(INT_WIDTH-1 downto -FRAC_WIDTH);
    signal Memory : FIFO_Memory;
    signal index : natural range 0 to FIFO_DEPTH - 1;
    signal looped : boolean;
    signal LAYER_DEPTH : natural;
    
    
begin

    set_layer_depth : process(layer_nr)
    begin
        if layer_nr = 1 then
            LAYER_DEPTH <= FIFO_DEPTH;
        else
            LAYER_DEPTH <= 25;
        end if;
    end process;
    
    out_value : process(looped, Memory, index)
    begin
        if looped then
            data_out <= Memory(index);
        else
            data_out <= (others => '0');
        end if;
    end process;
	
	fifo_proc : process (clk, reset)
	begin
        if reset = '0' then
            index <= 0;
            looped <= false;
        elsif rising_edge(clk) then				
            if (write_en = '1') then
                if looped then
                    Memory(index) <= resize(data_in + Memory(index), INT_WIDTH-1, -FRAC_WIDTH);
                else
                    Memory(index) <= data_in;
                end if;
                
                if index = LAYER_DEPTH-1 then
                    index <= 0;
                    looped <= true;
                else
                    index <= index+1;
                end if;
            end if;
        end if;
	end process;
		
end Behavioral;
