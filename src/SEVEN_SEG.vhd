-- SevenSeg.vhd
-- ------------------------------

library IEEE;
  use IEEE.std_logic_1164.all;
  use IEEE.numeric_std.all;

-- ------------------------------
    Entity SEVEN_SEG is
-- ------------------------------
  port( 
		Data   : in  std_logic_vector(3 downto 0);
		Segout : out std_logic_vector(6 downto 0) 
	);  
end entity SEVEN_SEG;

-- -----------------------------------------------
    Architecture COMB of SEVEN_SEG is
-- ------------------------------------------------

type LUT is array(0 to 9) of std_logic_vector(6 downto 0);

signal myLut : LUT := ("1000000", "1111001", "0100100", "0110000", "0011001", "0010010", "0000010", "1111000", "0000000", "0010000");

-- ------------------------------------------------

begin

Segout <= myLut(to_integer(unsigned(Data)));
	
end architecture COMB;

