#include <stdio.h>
#include <stdint.h>

/*---------------------------------------------------------------------------*/
/* z80.h config and inclusion */
#define CHIPS_IMPL
//#define CHIPS_ASSERT(c)
#include "z80.h"
/*---------------------------------------------------------------------------*/

/*---------------------------------------------------------------------------*/
/* stb_image_write config and inclusion */
#define STB_IMAGE_WRITE_IMPLEMENTATION
#define STBIW_ASSERT(x)
#define STB_IMAGE_WRITE_STATIC
#include "stb_image_write.h"
/*---------------------------------------------------------------------------*/

#include "debug.h"

#define MAX_SIZE   177
#define MAX_LENGTH 256

#define CMD_PORT        0xde
#define CMD_PIXEL_LEFT  0
#define CMD_PIXEL_RIGHT 1
#define CMD_PIXEL_UP    2
#define CMD_PIXEL_DOWN  3
#define CMD_SET_PIXEL   4
#define CMD_MESSAGE     5
#define CMD_PRINT_WORD  6

typedef struct {
    // CPU
    z80_t z80;
    int done;
    uint8_t mem[65536];

    // Terminal
    int is_writing, byte_count;
    char message[MAX_LENGTH];
    uint8_t bytes[2];

    // QR Code
    uint8_t pixels[MAX_SIZE][MAX_SIZE];
    int x, y;
}
State;

static uint64_t tick(int const num_ticks, uint64_t pins, void* const userdata) {
    State* const state = (State*)userdata;

    state->done = (pins & Z80_HALT) != 0;

    if (pins & Z80_MREQ) {
        uint16_t const address = Z80_GET_ADDR(pins);

        if (pins & Z80_RD) {
            Z80_SET_DATA(pins, state->mem[address]);
        }
        else if (pins & Z80_WR) {
            state->mem[address] = Z80_GET_DATA(pins);
        }
    }
    else if (pins & Z80_IORQ) {
        uint16_t const address = Z80_GET_ADDR(pins);

        if ((address & 0xff) == CMD_PORT && (pins & Z80_WR) != 0) {
            uint8_t const data = Z80_GET_DATA(pins);

            if (state->is_writing != 0) {
                if (data != 0) {
                    if (state->is_writing < MAX_LENGTH) {
                        state->message[state->is_writing++ - 1] = data;
                    }
                }
                else {
                    state->message[state->is_writing - 1] = 0;
                    state->is_writing = 0;
                    printf("%s\n", state->message);
                }
            }
            else if (state->byte_count != 0) {
                state->bytes[state->byte_count-- - 1] = data;

                if (state->byte_count == 0) {
                    uint16_t word = 0;

                    for (int i = 0; i < 2; i++) {
                        word = word << 8 | state->bytes[i];
                    }

                    printf("0x%04x (%u)\n", word, word);
                }
            }
            else {
                switch (data) {
                    case CMD_PIXEL_LEFT:  state->x--; break;
                    case CMD_PIXEL_RIGHT: state->x++; break;
                    case CMD_PIXEL_UP:    state->y--; break;
                    case CMD_PIXEL_DOWN:  state->y++; break;
                    case CMD_MESSAGE:     state->is_writing = 1; break;
                    case CMD_PRINT_WORD:  state->byte_count = 2; break;

                    case CMD_SET_PIXEL: {
                        if (state->x >= 0 && state->x < MAX_SIZE && state->y >= 0 && state->y < MAX_SIZE) {
                            state->pixels[state->y][state->x] = 0;
                        }
                        else {
                            fprintf(stderr, "invalid pixel coordinates: %d, %d\n", state->x, state->y);
                        }

                        break;
                    }

                }
            }
        }
    }

    return pins;
}

static void setup(State* const state) {
    z80_init(&state->z80, &(z80_desc_t){
        .tick_cb = tick,
        .user_data = state
    });

    state->done = 0;
    memcpy(state->mem, debug_bin, debug_bin_len);

    state->is_writing = state->byte_count = 0;

    memset(state->pixels, 0xff, sizeof(state->pixels));
    state->x = state->y = 0;
}

static void run(State* const state) {
    while (!state->done) {
        z80_exec(&state->z80, 1000);
    }
}

static void finish(State* const state) {
    if (stbi_write_png("debug.png", MAX_SIZE, MAX_SIZE, 1, state->pixels, MAX_SIZE) == 0) {
        fprintf(stderr, "error writing png\n");
    }
}

int main() {
    State state;
    setup(&state);

    run(&state);

    finish(&state);
    return 0;
}
