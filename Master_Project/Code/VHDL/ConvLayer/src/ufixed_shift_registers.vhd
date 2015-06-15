----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 02/13/2015 12:34:48 PM
-- Design Name: 
-- Module Name: shift_registers - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
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

library ieee_proposed;
use ieee_proposed.fixed_float_types.all;
use ieee_proposed.fixed_pkg.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Natural values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity sfixed_shift_registers is
    generic (
        NOF_REGS : Natural := 8;
        INT_WIDTH : Natural := 8;
        FRAC_WIDTH : Natural := 8
    );
    port (
        clk : in std_logic;
        reset : in std_logic;
        we : in std_logic;
        output_reg : in Natural;
        data_in : in sfixed(INT_WIDTH-1 downto -FRAC_WIDTH);
        data_out : out sfixed(INT_WIDTH-1 downto -FRAC_WIDTH)
    );
    

end sfixed_shift_registers;

architecture Behavioral of sfixed_shift_registers is

    component sfixed_buffer
        generic (
            INT_WIDTH : Natural := INT_WIDTH;
            FRAC_WIDTH : Natural := FRAC_WIDTH
        );
        port (
            clk : in std_logic;
            reset : in std_logic;
            we : in std_logic;
            data_in : in sfixed(INT_WIDTH-1 downto -FRAC_WIDTH);
            data_out : out sfixed(INT_WIDTH-1 downto -FRAC_WIDTH)
        );
    end component;
    
    type sfixed_array is array (NOF_REGS-1 downto 0) of sfixed(INT_WIDTH-1 downto -FRAC_WIDTH);
    
    signal shift_reg_values : sfixed_array; 

begin

    set_output : process(output_reg, shift_reg_values)
    begin
        if output_reg >= 0 then
            data_out <= shift_reg_values(output_reg);
        elsif output_reg = 0 then
            data_out <= data_in;
        else
            data_out <= shift_reg_values(0);
        end if;
    end process;
    
    gen_regs_loop : for reg in 0 to NOF_REGS-1 generate
    begin
    
        first_reg : if reg = 0 generate
        begin
            shift_reg : sfixed_buffer port map (
                clk => clk,
                reset => reset,
                we => we,
                data_in => data_in,
                data_out => shift_reg_values(reg)
            );
        end generate;
        
        other_regs : if reg > 0 generate
        begin
            shift_reg : sfixed_buffer port map (
                clk => clk,
                reset => reset,
                we => we,
                data_in => shift_reg_values(reg-1),
                data_out => shift_reg_values(reg)
            );
        end generate;
    
    end generate;

    
end Behavioral;

