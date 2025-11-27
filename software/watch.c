#include "watch.h"

//----------------------
// Variables globales
//----------------------
#define timer_0_base ((volatile unsigned int *) TIMER_0_BASE)
#define keys_base ((volatile unsigned int *) KEYS_BASE)
#define ledg_base ((volatile unsigned int *) LEDG_BASE)
#define alarm_bell_0_base ((volatile unsigned int *) ALARM_BELL_0_BASE)
#define chrono_0_base ((volatile unsigned int *) CHRONO_0_BASE)
#define start_chrono_base ((volatile unsigned int *) START_CHRONO_BASE)
#define hexs_base ((volatile unsigned int *) HEXS_BASE) 
#define switches_base ((volatile unsigned int *) SWITCHES_BASE)

volatile uint8_t tick_1s_flag        = 0;
volatile uint8_t keys_rising_flags   = 0;
volatile uint8_t keys_interrupt_flag = 0;

watch_mode_t g_mode;
horloge_t    g_horloge;
chrono_t     g_chrono;
minuterie_t  g_minut;

//----------------------
// ISR du timer 1 s
//----------------------
void timer_isr(void* context, alt_u32 id)
{
    // Clear du timer (bit TO dans STATUS)
    IOWR_ALTERA_AVALON_TIMER_STATUS(timer_0_base, 0);

    // Signale qu'une seconde est passée
    tick_1s_flag = 1;
}

//----------------------
// ISR pour les touches
//----------------------
void keys_isr(void* context, alt_u32 id)
{
    // Lire le registre d'edge capture pour savoir quelle touche a été pressée
    alt_u32 edge_capture = IORD_ALTERA_AVALON_PIO_EDGE_CAP(keys_base);
    
    // Clear le registre d'edge capture en écrivant la valeur 1 pour chaque
    IOWR_ALTERA_AVALON_PIO_EDGE_CAP(keys_base, 0xF);
    
    // Activer le flag pour traitement dans le main et stocker l'état des touches pour le traitement
    keys_rising_flags   = (edge_capture & 0xF);
	keys_interrupt_flag = 1;
}

//----------------------
// Init du timer à 1 s (50 MHz -> période = 49 999 999)
//----------------------
void timer_init_1s(void)
{
    uint32_t period = 49999999; // 50e6 * 1s - 1

    // Charger la période
    IOWR_ALTERA_AVALON_TIMER_PERIODL(timer_0_base, period & 0xFFFF);
    IOWR_ALTERA_AVALON_TIMER_PERIODH(timer_0_base, period >> 16);

    // Enregistrer l'ISR
    alt_ic_isr_register(
        TIMER_0_IRQ_INTERRUPT_CONTROLLER_ID,
        TIMER_0_IRQ,
        (alt_isr_func) timer_isr,
        NULL,
        0
    );

	IOWR_ALTERA_AVALON_TIMER_CONTROL(
        timer_0_base,
        ALTERA_AVALON_TIMER_CONTROL_START_MSK  |
        ALTERA_AVALON_TIMER_CONTROL_CONT_MSK |
        ALTERA_AVALON_TIMER_CONTROL_ITO_MSK
    );
}

//----------------------
// Init des interruptions pour les touches
//----------------------
void keys_interrupt_init(void)
{
    // Clear le registre d'edge capture
    IOWR_ALTERA_AVALON_PIO_EDGE_CAP(keys_base, 0xF);
    
    // Activer les interruptions pour tous les bits (KEY0-3)
    IOWR_ALTERA_AVALON_PIO_IRQ_MASK(keys_base, 0xF);
    
    // Enregistrer l'ISR
    alt_ic_isr_register(
        KEYS_IRQ_INTERRUPT_CONTROLLER_ID,
        KEYS_IRQ,
        keys_isr,
        NULL,
        0
    );
}


//----------------------
// Init globale de la montre
//----------------------
void watch_init(void)
{
    g_mode = MODE_HORLOGE;
	IOWR_ALTERA_AVALON_PIO_DATA(ledg_base, 0X1);

    g_horloge.heures      = 12;
    g_horloge.minutes     = 30;
    g_horloge.secondes    = 0;

    g_chrono.running      = 0;
	g_chrono.chrono_actif = 0;

    g_minut.heures        = 0;
	g_minut.minutes       = 0;
    g_minut.secondes      = 0;
    g_minut.running       = 0;
    g_minut.alarm_active  = 0;

    timer_init_1s();
	keys_interrupt_init();
}

//----------------------
// Mise à jour de l'horloge / chrono / minuterie
// appelée à chaque seconde
//----------------------
void update_all_time_1s(void)
{
    //----- 1) Horloge : toujours en marche -----
    g_horloge.secondes++;
    if (g_horloge.secondes >= 60) {
        g_horloge.secondes = 0;
        g_horloge.minutes++;
        if (g_horloge.minutes >= 60) {
            g_horloge.minutes = 0;
            g_horloge.heures++;
            if (g_horloge.heures >= 24) {
                g_horloge.heures = 0;
            }
        }
    }

    //----- 2) Minuterie -----
    if (g_minut.running) {

        if (g_minut.heures == g_horloge.heures && g_minut.minutes == g_horloge.minutes && g_minut.secondes == g_horloge.secondes) {
            g_mode = MODE_MINUTERIE;
			IOWR_ALTERA_AVALON_PIO_DATA(ledg_base, 0X4);
			// Fin du compte à rebours
            g_minut.running      = 0;
            g_minut.alarm_active = 1;

            // Démarrage de ALARM_BELL / CHENILLIARD
            IOWR_ALTERA_AVALON_PIO_DATA(alarm_bell_0_base, g_minut.alarm_active);

        }
    }
}

//----------------------
// Conversion (minutes, secondes) vers 4 digits BCD
// MM:SS -> d3 d2 d1 d0
//----------------------
static void encode_mmss(uint8_t minutes, uint8_t secondes,
                        uint8_t* d3, uint8_t* d2,
                        uint8_t* d1, uint8_t* d0)
{
    *d3 = minutes / 10;
    *d2 = minutes % 10;
    *d1 = secondes / 10;
    *d0 = secondes % 10;
}

//----------------------
// Conversion HH:MM au format 4 digits
//----------------------
static void encode_hhmm(uint8_t heures, uint8_t minutes,
                        uint8_t* d3, uint8_t* d2,
                        uint8_t* d1, uint8_t* d0)
{
    *d3 = heures / 10;
    *d2 = heures % 10;
    *d1 = minutes / 10;
    *d0 = minutes % 10;
}

//----------------------
// Mise à jour de l'affichage
//----------------------
void update_display(void)
{
    uint8_t d3 = 0, d2 = 0, d1 = 0, d0 = 0;
	IOWR_ALTERA_AVALON_PIO_DATA(start_chrono_base, g_chrono.chrono_actif);

    switch (g_mode) {
    case MODE_HORLOGE:
        encode_hhmm(g_horloge.heures, g_horloge.minutes, &d3, &d2, &d1, &d0);
        break;

    case MODE_CHRONO:
        IOWR_ALTERA_AVALON_PIO_DATA(chrono_0_base, g_chrono.running);
        break;

    case MODE_MINUTERIE:
        encode_hhmm(g_minut.heures, g_minut.minutes, &d3, &d2, &d1, &d0);
        break;
    }
	
	IOWR_ALTERA_AVALON_PIO_DATA(hexs_base, ((d3 << 12) + (d2 << 8) + (d1 << 4) + d0));

}

//----------------------
// Gestion des KEY et SW
//----------------------
void handle_keys_and_switches(void)
{
    // Récupérer les événements d'appui vus par l'ISR
    uint8_t rising      = keys_rising_flags ;
    keys_rising_flags   = 0;  // on consomme les événements

    uint16_t sw         = IORD_ALTERA_AVALON_PIO_DATA(switches_base);
	
	uint8_t heures, minutes;
	printf("rising = %d,  keys_rising_flags  = %d\n",rising, keys_rising_flags );

    //---------------- KEY0 : reset "soft" ----------------
	if (rising == 0) {
        // aucun bouton pressé depuis le dernier tour -> on ne fait rien
        return;
    }
    if (rising & 0x1) {
        // Remise à zéro des compteurs, mode HORLOGE
		printf("KEY0 pressed - Reset\n");
        g_mode = MODE_HORLOGE;

        g_horloge.heures      = 12;
        g_horloge.minutes     = 30;
        g_horloge.secondes    = 0;

        g_chrono.running      = 0;
		g_chrono.chrono_actif = 0;

        g_minut.heures        = 0;
		g_minut.minutes       = 0;
        g_minut.secondes      = 0;
        g_minut.running       = 0;
        g_minut.alarm_active  = 0;

        // Arret de ALARM_BELL / CHENILLIARD
        IOWR_ALTERA_AVALON_PIO_DATA(alarm_bell_0_base, g_minut.alarm_active);
		// Arret du chrono
        IOWR_ALTERA_AVALON_PIO_DATA(chrono_0_base, g_chrono.running);
		IOWR_ALTERA_AVALON_PIO_DATA(start_chrono_base, g_chrono.chrono_actif);
    }

    //---------------- KEY1 : changement de mode ----------------
    if (rising & 0x2) {
		printf("KEY1 pressed - Changement mode\n");
        if (g_mode == MODE_HORLOGE){
            g_mode = MODE_CHRONO;
			IOWR_ALTERA_AVALON_PIO_DATA(ledg_base, 0X2);
		}else if (g_mode == MODE_CHRONO){
            g_mode = MODE_MINUTERIE;
			IOWR_ALTERA_AVALON_PIO_DATA(ledg_base, 0X4);
		}else{
			g_mode = MODE_HORLOGE;
			IOWR_ALTERA_AVALON_PIO_DATA(ledg_base, 0X1);
		}
		g_chrono.chrono_actif = g_mode == MODE_CHRONO ? 1 : 0;
		g_chrono.running      = 0;
    }

    //---------------- KEY2 : start/stop suivant le mode ----------------
    if (rising & 0x4) {
		printf("KEY2 pressed - Start/Stop\n");
        if (g_mode == MODE_CHRONO) {
            g_chrono.running = !g_chrono.running;
        } else if (g_mode == MODE_MINUTERIE) {
            if (!g_minut.alarm_active) {
                // toggle start/stop si pas en alarme
                if (g_minut.running) {
                    g_minut.running = 0;
                } else {
                        g_minut.running = 1;
                }
            }
        }
    }

    //---------------- KEY3 : clear / config / stop alarme ----------------
    if (rising & 0x8) {
		printf("KEY3 pressed - Clear/Config\n");
        if (g_mode == MODE_CHRONO) {
            // Clear du chrono
            g_chrono.running  = 0;
			IOWR_ALTERA_AVALON_PIO_DATA(chrono_0_base, (~g_chrono.running) << 1);
        } else if (g_mode == MODE_MINUTERIE) {
            if (g_minut.alarm_active) {
                // Stop de l'alarme
                g_minut.alarm_active = 0;
                // Arret de ALARM_BELL / CHENILLIARD
				IOWR_ALTERA_AVALON_PIO_DATA(alarm_bell_0_base, g_minut.alarm_active);
				printf("g_mode == MODE_MINUTERIE\n");
            } else if (!g_minut.running) {
                // Configuration de la minuterie par les SW
                // SW[9:5] = heures, SW[4:0] = minutes
                heures  = (sw >> 5) & 0x1F;
				minutes = sw & 0x1F;
                if (heures >= 24) heures = 00; // clamp
				if (minutes > 59) minutes = 59; // clamp

                g_minut.heures   = heures;
				g_minut.minutes  = minutes;
                g_minut.secondes = 0;
            }
        } else if (g_mode == MODE_HORLOGE) {
			// Configuration de l'horloge par les SW
			// SW[9:5] = heures, SW[4:0] = minutes
			heures  = (sw >> 5) & 0x1F;
			minutes = sw & 0x1F;
			if (heures >= 24) heures = 00; // clamp
			if (minutes > 59) minutes = 59; // clamp

			g_horloge.heures   = heures;
			g_horloge.minutes  = minutes;
			g_horloge.secondes = 0;
		}
    }

}

//----------------------
// main()
//----------------------
int main(void)
{
   watch_init();
	
    while (1) {
        if (tick_1s_flag) {
            tick_1s_flag = 0;
            update_all_time_1s();  // mettre à jour horloge/chrono/minuterie
            update_display();      // envoyer les 4 digits au 7segments
        }
		
		if(keys_interrupt_flag){
			keys_interrupt_flag = 0;
			handle_keys_and_switches();
		}
		
    }

    return 0;
}
