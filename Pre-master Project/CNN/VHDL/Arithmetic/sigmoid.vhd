----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    12:45:47 10/15/2014 
-- Design Name: 
-- Module Name:    sigmoid - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;


-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

library ieee_proposed;
use ieee_proposed.fixed_pkg.all;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity sigmoid is
	Port (
		x : in  ufixed (7 downto -8);
		test : in ufixed(7 downto -8);
		y : out ufixed(7 downto -8));
end sigmoid;
 
architecture Behavioral of sigmoid is
	signal temp : ufixed(15 downto -16);
	signal temp2: ufixed(7 downto -8);
begin
	temp <= x*test;
	y <= resize(temp, temp2);

end Behavioral;

