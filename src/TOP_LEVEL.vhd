-- TOP_LEVEL.vhd
-- ------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.all; 

-- ------------------------------
    Entity TOP_LEVEL is
-- ------------------------------
	PORT
	(
		CLOCK_50    :  IN  STD_LOGIC;
		KEY		 	:  IN  STD_LOGIC_VECTOR(3 downto 0);
		SW    		:  IN  STD_LOGIC_VECTOR(9 downto 0);
		LEDR        :  OUT  STD_LOGIC_VECTOR(7 downto 0);
		LEDG        :  OUT  STD_LOGIC_VECTOR(2 downto 0);
		HEX0 			:  OUT  STD_LOGIC_VECTOR(6 downto 0);
		HEX1 			:  OUT  STD_LOGIC_VECTOR(6 downto 0);
		HEX2 			:  OUT  STD_LOGIC_VECTOR(6 downto 0);
		HEX3 			:  OUT  STD_LOGIC_VECTOR(6 downto 0);
		DRAM_DQ  	: INOUT STD_LOGIC_VECTOR(15 DOWNTO 0);
		DRAM_ADDR	: OUT   STD_LOGIC_VECTOR(11 DOWNTO 0);
		DRAM_BA_0, DRAM_BA_1 			   : OUT STD_LOGIC;
		DRAM_CAS_N, DRAM_RAS_N, DRAM_CLK : OUT STD_LOGIC;
		DRAM_CKE, DRAM_CS_N, DRAM_WE_N   : OUT STD_LOGIC;
		DRAM_UDQM, DRAM_LDQM             : OUT STD_LOGIC
	);
END entity;

-- -----------------------------------------------
    Architecture TOP_LEVEL_RTL of TOP_LEVEL is
-- ------------------------------------------------

component nios_system is
	port(
			clk_clk             : in    std_logic                     := 'X';             -- clk
			reset_reset_n       : in    std_logic                     := 'X';             -- reset_n
			sdram_addr          : out   std_logic_vector(11 downto 0);                    -- addr
			sdram_ba            : out   std_logic_vector(1 downto 0);                     -- ba
			sdram_cas_n         : out   std_logic;                                        -- cas_n
			sdram_cke           : out   std_logic;                                        -- cke
			sdram_cs_n          : out   std_logic;                                        -- cs_n
			sdram_dq            : inout std_logic_vector(15 downto 0) := (others => 'X'); -- dq
			sdram_dqm           : out   std_logic_vector(1 downto 0);                     -- dqm
			sdram_ras_n         : out   std_logic;                                        -- ras_n
			sdram_we_n          : out   std_logic;                                        -- we_n
			sdram_clk_clk       : out   std_logic;                                        -- clk
			keys_export         : in    std_logic_vector(3 downto 0)  := (others => 'X'); -- export
			hexs_export         : out   std_logic_vector(15 downto 0);                    -- export
			switches_export     : in    std_logic_vector(9 downto 0) := (others => 'X'); -- export
			start_chrono_export : out   std_logic_vector(7 downto 0);                     -- export
			alarm_bell_export   : out   std_logic_vector(31 downto 0);                    -- export
			chrono_export       : out   std_logic_vector(31 downto 0);                    -- export
			ledg_export         : out   std_logic_vector(7 downto 0)                      -- export
	);
end component nios_system;
 
SIGNAL DQM : STD_LOGIC_VECTOR(1 DOWNTO 0);
SIGNAL BA  : STD_LOGIC_VECTOR(1 DOWNTO 0);

SIGNAL digit_MM_1, digit_MM_2, digit_HH_1, digit_HH_2 : std_logic_vector(3 downto 0);
SIGNAL pio_cmd_HEX                     : std_logic_vector(15 downto 0);
SIGNAL etat_systeme, start_chrono      : std_logic_vector(7 downto 0);
SIGNAL cmd_chenillard, cmd_chronometre : std_logic_vector(31 downto 0);

-- ------------------------------------------------	

BEGIN 

	DRAM_BA_0  <= BA(0);
	DRAM_BA_1  <= BA(1);
	DRAM_UDQM  <= DQM(1);
	DRAM_LDQM  <= DQM(0);
	
	digit_MM_1 <= cmd_chronometre(3 downto 0) when start_chrono(0) = '1' else pio_cmd_HEX(3 downto 0);
	digit_MM_2 <= cmd_chronometre(7 downto 4) when start_chrono(0) = '1' else pio_cmd_HEX(7 downto 4);
	digit_HH_1 <= cmd_chronometre(11 downto 8) when start_chrono(0) = '1' else pio_cmd_HEX(11 downto 8);
	digit_HH_2 <= cmd_chronometre(15 downto 12) when start_chrono(0) = '1' else pio_cmd_HEX(15 downto 12);
	
	LEDR       <= cmd_chenillard(7 downto 0);
	LEDG       <= etat_systeme(2 downto 0);  

	u0 : 	component nios_system
			port map (
						clk_clk         	=> CLOCK_50,       				   --      clk.clk
						reset_reset_n   	=> KEY(0),         				   --    reset.reset_n
						sdram_addr      	=> DRAM_ADDR,      				   --     sdram.addr
						sdram_ba        	=> BA,        					   --          .ba
						sdram_cas_n     	=> DRAM_CAS_N,     				   --          .cas_n
						sdram_cke       	=> DRAM_CKE,       				   --          .cke
						sdram_cs_n      	=> DRAM_CS_N,      			       --          .cs_n
						sdram_dq        	=> DRAM_DQ,        				   --          .dq
						sdram_dqm       	=> DQM,
						sdram_ras_n     	=> DRAM_RAS_N,
						sdram_we_n      	=> DRAM_WE_N,
						sdram_clk_clk   	=> DRAM_CLK,                       -- sdram_clk.clk
						alarm_bell_export => cmd_chenillard,                 -- alarm_bell.export
						chrono_export    	=> cmd_chronometre,                --     chrono.export
						ledg_export      	=> etat_systeme,                   --       keys.export
						keys_export       => KEY,
						hexs_export       => pio_cmd_HEX,                    --       hexs.export
						switches_export   => SW,
						start_chrono_export => start_chrono
			);

	SEVEN_SEG_MM_1 : 	Entity work.SEVEN_SEG
						port map( 
									Data   => digit_MM_1,
									Segout => HEX0
						);

	SEVEN_SEG_MM_2 : 	Entity work.SEVEN_SEG
						port map( 
									Data   => digit_MM_2,	
									Segout => HEX1
						);

	SEVEN_SEG_HH_1 : 	Entity work.SEVEN_SEG
						port map( 
									Data   => digit_HH_1,	
									Segout => HEX2
						);
							
	SEVEN_SEG_HH_2 : 	Entity work.SEVEN_SEG
						port map( 
									Data   => digit_HH_2,	
									Segout => HEX3
						);
					
END architecture;