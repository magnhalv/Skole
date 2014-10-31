library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

use work.custom_type_pkg.all;

entity max_pool_controller is
	generic (
		nof_units : positive := 14
	);
	
	port ( 
		clk 			: in std_logic;
		valid_input	: in std_logic;
		read_unit	: out bit_array(nof_units-1 downto 0);
		write_unit	: out bit_array(nof_units-1 downto 0)
	);
end max_pool_controller;

architecture Behavioral of max_pool_controller is

begin


end Behavioral;

