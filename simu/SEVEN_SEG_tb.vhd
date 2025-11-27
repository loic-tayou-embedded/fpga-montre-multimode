-- SEVEN_SEG_tb.vhd
-- ---------------------------------------------------

LIBRARY ieee;
  USE ieee.std_logic_1164.ALL;
  USE ieee.numeric_std.ALL;

entity SEVEN_SEG_tb is
end entity;

architecture TEST of SEVEN_SEG_tb is

signal Data   : std_logic_vector(3 downto 0); 
signal Segout : std_logic_vector(6 downto 0);

type LUT is array(0 to 9) of std_logic_vector(6 downto 0);
signal myLut : LUT := ("1000000", "1111001", "0100100", "0110000", "0011001", "0010010", "0000010", "1111000", "0000000", "0010000");

begin


	SEVEN_SEG_pm : 	entity work.SEVEN_SEG
					port map ( 	
							Data   => Data,
							Segout => Segout
					);

	process 
	begin
	  for i in 0 to 9 loop
		Data <= std_logic_vector(to_unsigned(i,4));
		wait for 5 ns;
		assert Segout = myLut(to_integer(unsigned(Data))) report "error in SEVEN_SEG or in SEVEN_SEG_tb (myLut)"  severity warning;
	  end loop;

	  wait;
	end process;

end architecture;
