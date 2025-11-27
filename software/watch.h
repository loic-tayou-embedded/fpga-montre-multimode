#ifndef WATCH_H
#define WATCH_H

#include <stdio.h>
#include <stdint.h>
#include <stddef.h>
#include "system.h"
#include "sys/alt_irq.h"
#include "altera_avalon_timer_regs.h"
#include "altera_avalon_pio_regs.h"


//----------------------
// Types et états
//----------------------
typedef enum {
    MODE_HORLOGE   = 0,
    MODE_CHRONO    = 1,
    MODE_MINUTERIE = 2
} watch_mode_t;

typedef struct {
    uint8_t heures;
    uint8_t minutes;
    uint8_t secondes;
} horloge_t;

typedef struct {
    uint8_t running;        // 0/1
	uint8_t chrono_actif;        // 0/1
} chrono_t;

typedef struct {
    uint8_t heures;
    uint8_t minutes;
	uint8_t secondes;
    uint8_t running;        // 0/1
    uint8_t alarm_active;   // 0/1
} minuterie_t;

//----------------------
// Variables globales
//----------------------
extern volatile uint8_t tick_1s_flag;
extern volatile uint8_t keys_interrupt_flag;
extern watch_mode_t g_mode;
extern horloge_t    g_horloge;
extern chrono_t     g_chrono;
extern minuterie_t  g_minut;

//----------------------
// Prototypes
//----------------------
void watch_init(void);
void timer_init_1s(void);
void timer_isr(void* context, alt_u32 id);
void keys_isr(void* context, alt_u32 id);
void update_all_time_1s(void);
void update_display(void);
void handle_keys_and_switches(void);

#endif
