-- FDIV.vhd
-- ---------------------------------------

LIBRARY ieee;
  USE ieee.std_logic_1164.ALL;
  USE ieee.numeric_std.ALL;

-- ---------------------------------------
    Entity FDIV is
-- ---------------------------------------
	Generic (
				Fclock : positive := 50E6;
				FTick  : positive := 1E3
	);
    Port (     
			CLK : In  std_logic;
            RST : In  std_logic;  
            Tick1ms : Out std_logic 
	);
end FDIV;

-- ---------------------------------------
    Architecture FDIV_RTL of FDIV is
-- ---------------------------------------

constant Divisor_ms : positive := Fclock  / FTick;
signal Count     : integer range 0 to Divisor_ms;

signal Tick1ms_i  : std_logic;


-- -------------------------------------

begin

Tick1ms  <= Tick1ms_i;


process (RST,CLK)
begin
  if RST='1' then
    Count     <= 0;     
    Tick1ms_i  <= '0';
    
  elsif rising_edge (CLK) then
    Tick1ms_i  <= '0';

    if Count < Divisor_ms-1 then
      Count <= Count + 1;
    else
      Count <= 0;
      Tick1ms_i <= '1';
    end if;
  end if;
end process;

end FDIV_RTL;

