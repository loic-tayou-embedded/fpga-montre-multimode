-- CHRONO.vhd
-- ---------------------------------------

LIBRARY ieee;
  USE ieee.std_logic_1164.ALL;
  USE ieee.numeric_std.ALL;

-- ---------------------------------------
    Entity CHRONO is
-- ---------------------------------------
	Generic (
				Fclock : positive := 50E6;
				FTick  : positive := 1E3;
				N      : positive := 1000
	);
	port( 
			CLK        : in  std_logic;
			RST        : in  std_logic;
			START      : in  std_logic;
			UNITIES    : out std_logic_vector(3 downto 0);
			TENS       : out std_logic_vector(3 downto 0);
			HUNDREDS   : out std_logic_vector(3 downto 0);
			THOUSNDS   : out std_logic_vector(3 downto 0)
	);
end CHRONO;

-- ---------------------------------------
    Architecture CHRONO_RTL of CHRONO is
-- ---------------------------------------

signal Tick1ms, rst_FDIV, sig_rst_FDIV : std_logic;

-- -------------------------------------

begin

sig_rst_FDIV <= RST or rst_FDIV;

FDIV_pm :	entity work.FDIV
			Generic map(Fclock => Fclock, FTick => FTick)
			Port map(  
						CLK     => CLK,
						RST     => sig_rst_FDIV,
						Tick1ms => Tick1ms
			);

BCD_COUNTER_pm :	entity work.BCD_COUNTER
					generic map(N => N) 
					port map( 
								CLK      => CLK,
								RST      => RST,
								TICK1MS  => Tick1ms,
								START    => START,
								rst_FDIV => rst_FDIV,
								UNITIES  => UNITIES,
								TENS     => TENS,
								HUNDREDS => HUNDREDS,
								THOUSNDS => THOUSNDS
					);
					

end CHRONO_RTL;

