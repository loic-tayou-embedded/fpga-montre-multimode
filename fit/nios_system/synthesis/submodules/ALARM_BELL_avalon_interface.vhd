LIBRARY ieee;
USE ieee.std_logic_1164.all;

ENTITY ALARM_BELL_avalon_interface IS
	Generic(
				Fclock : positive := 50E6;
				FTick  : positive := 1E3;
				N      : positive := 250
	);
	PORT( 
			clock      : IN STD_LOGIC; 
			resetn     : IN STD_LOGIC;
			read       : IN STD_LOGIC;
			write      : IN STD_LOGIC;
			chipselect : IN STD_LOGIC;
			writedata  : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
			byteenable : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
			readdata   : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
			Q_export   : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
	);
END ALARM_BELL_avalon_interface;

ARCHITECTURE CHRONO_avalon_interface_RTL OF ALARM_BELL_avalon_interface IS

SIGNAL local_byteenable : STD_LOGIC_VECTOR(3 DOWNTO 0);  -- byteenable synchronisé
SIGNAL to_alarm_bell    : STD_LOGIC_VECTOR(31 DOWNTO 0);
SIGNAL from_alarm_bell  : STD_LOGIC_VECTOR(31 DOWNTO 0);
SIGNAL writedata_reg    : STD_LOGIC_VECTOR(31 DOWNTO 0);   -- Registre pour synchroniser writedata
SIGNAL readdata_reg     : STD_LOGIC_VECTOR(31 DOWNTO 0);    -- Registre pour synchroniser readdata
SIGNAL byteenable_reg   : STD_LOGIC_VECTOR(3 DOWNTO 0);   -- Registre pour synchroniser byteenable

BEGIN

	-- Processus de synchronisation
    PROCESS (clock, resetn)
    BEGIN
        IF resetn = '0' THEN
            writedata_reg  <= (OTHERS => '0');
            readdata_reg   <= (OTHERS => '0');
            byteenable_reg <= "0000";  -- Valeur par défaut au reset
        ELSIF rising_edge(clock) THEN
            -- Synchronisation de writedata et byteenable
            IF (chipselect = '1' AND write = '1') THEN
                writedata_reg  <= writedata;
                byteenable_reg <= byteenable;
            END IF;
            
            -- Synchronisation de readdata
            IF (chipselect = '1' AND read = '1') THEN
                readdata_reg <= from_alarm_bell;
            END IF;
        END IF;
    END PROCESS;
	
	-- Assignations
    to_alarm_bell    <= writedata_reg;
    local_byteenable <= byteenable_reg;  -- Utilisation de la version synchronisée


    ALARM_BELL_pm :	entity work.ALARM_BELL
					generic map(Fclock => Fclock, FTick => FTick, N => N)
					PORT MAP (
								CLK      => clock,
								RST      => not resetn,
								START    => to_alarm_bell(0),
								LED      => from_alarm_bell(7 downto 0)
					);

    -- Sortie readdata synchronisée
    readdata <= readdata_reg;
    
    -- Q_export reste une sortie combinatoire
    Q_export <= from_alarm_bell;

END CHRONO_avalon_interface_RTL;
