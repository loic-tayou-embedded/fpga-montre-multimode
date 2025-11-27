-- CHENILLIARD.vhd
-- ---------------------------------------

library IEEE;
  use IEEE.std_logic_1164.ALL;
  use IEEE.numeric_std.ALL;


---------------------------------------
entity CHENILLIARD is
---------------------------------------
	generic(N : positive := 250); 
	port( 
			CLK      : in  std_logic;
			RST      : in  std_logic;
			START    : in  std_logic;
			TICK1MS  : in  std_logic;
			rst_FDIV : out  std_logic;
			LED      : out std_logic_vector(7 downto 0)
	);
end entity CHENILLIARD;


---------------------------------------
architecture CHENILLIARD_RTL of CHENILLIARD is
---------------------------------------

constant NB_MOTIF : positive := 9;
type lut is array (Natural range 0 to NB_MOTIF-1) of std_logic_vector(7 downto 0);
constant MOTIF_CHENILLIARD : lut := (X"00", X"01", X"03", X"07", X"0F", X"1F", X"3F", X"7F", X"FF"); 
signal cnt       : Natural range 0 to NB_MOTIF-1;
signal tick_N1ms : Natural := 0;
signal etat      : Natural range 0 to 1 := 0;

-- -------------------------------------

begin

process(RST,CLK)
begin
	if(RST = '1') then
		cnt       <= 0;
		etat      <= 0;
		tick_N1ms <= 0;
		LED       <= (others => '0');
		rst_FDIV  <= '1';
	elsif(rising_edge(CLK)) then
		if(START = '1') then
			rst_FDIV <= '0';
			if (TICK1MS = '1') then
				if(tick_N1ms = N - 1) then
					tick_N1ms <= 0;
					case etat is
						when 0 =>
							LED <= MOTIF_CHENILLIARD(cnt);
							if(cnt = NB_MOTIF-1) then
								etat <= 1;
							else
								cnt <= cnt + 1;
							end if;
						when 1 =>
							LED <= not MOTIF_CHENILLIARD(cnt);
							if(cnt = 0) then
								etat <= 0;
							else
								cnt <= cnt - 1;
							end if;
					end case;
				else
					tick_N1ms <= tick_N1ms + 1;
				end if;
			end if;
		else
			rst_FDIV  <= '1';
			cnt       <= 0;
			etat      <= 0;
			LED       <= (others => '0');
			tick_N1ms <= 0;
		end if;
	end if;
end process;

end architecture CHENILLIARD_RTL;

