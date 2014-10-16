	-- TestBench Template 

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

library ieee_proposed;
use ieee_proposed.fixed_pkg.all;

ENTITY tb_sigmoid IS
END tb_sigmoid;

  ARCHITECTURE behavior OF tb_sigmoid IS 

  -- Component Declaration
	COMPONENT sigmoid
		Port (
		x : in  ufixed (7 downto -8);
		test : in ufixed(7 downto -8);
		y : out ufixed(7 downto -8));
	END COMPONENT;

	SIGNAL s1 :  ufixed(7 downto -8);
	SIGNAL s2 :  ufixed(7 downto -8);
	SIGNAL s3 :  ufixed(7 downto -8);
				 

  BEGIN

  -- Component Instantiation
          my_sigmoid : sigmoid PORT MAP(
                  x => s1,
                  test => s2,
						y => s3
          );


  --  Test Bench Statements
     tb : PROCESS
     BEGIN

        wait for 100 ns; -- wait until global set/reset completes
			s1 <= "0000000010000000";
			s2 <= "0000000010000000";
        -- Add user defined stimulus here

        wait; -- will wait forever
     END PROCESS tb;
  --  End Test Bench 

  END;
