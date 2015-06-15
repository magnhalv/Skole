library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity conv_controller is
	generic (	
		IMAGE_DIM 	: Natural := 3;
		KERNEL_DIM 	: Natural := 2
	);
	port (
		clk 				: in  std_logic;
		conv_en 			: in  std_logic;
        layer_nr            : in Natural;
		output_valid 	    : out std_logic
	);
end conv_controller;

architecture Behavioral of conv_controller is

	signal row_num 				: Natural range 0 to IMAGE_DIM := 0;
	signal column_num 			: Natural range 0 to IMAGE_DIM := 0;
	signal reached_valid_row 	: std_logic;
	
	signal conv_en_buf	: std_logic;
	
	signal output_valid_buf			: std_logic;

    signal curr_img_dim : natural; 

begin

    set_img_dim : process(layer_nr)
    begin
        if layer_nr = 0 then
            curr_img_dim <= IMAGE_DIM;
        elsif layer_nr = 1 then
            curr_img_dim <= (IMAGE_DIM-KERNEL_DIM+1)/2;
        else
            curr_img_dim <= (((IMAGE_DIM-KERNEL_DIM+1)/2)-KERNEL_DIM+1)/2;
        end if;
    end process;

	count_pixels : process (clk)
	begin
		if rising_edge(clk) then
			conv_en_buf <= conv_en;
			if conv_en = '1' then
				if (column_num = curr_img_dim and row_num = curr_img_dim) then
					row_num <= 1;
					column_num <= 1;
					reached_valid_row <= '0';
				
				else
					if (column_num = curr_img_dim) then
						column_num <= 1;
						row_num <= row_num + 1;
					else
						column_num <= column_num + 1;
					end if;
					
					if (row_num = KERNEL_DIM) then
						reached_valid_row <= '1';
					end if;
				end if;
			else
				row_num <= 1;
				column_num <= 0;
				reached_valid_row <= '0';
			end if;
		end if;
	end process;
	
	is_output_valid : process(clk)
	begin
		if rising_edge(clk) then
			if conv_en_buf = '1'
			and reached_valid_row = '1' 
			and (column_num >= KERNEL_DIM-1 and column_num < curr_img_dim) then
				output_valid <= '1';
			else 
				output_valid <= '0';
			end if;
		end if;
	end process;

end Behavioral;

