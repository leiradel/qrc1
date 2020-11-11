// https://github.com/leiradel/qrc1

#include <stdint.h>
#include <stddef.h>
#include <string.h>

// An encoded message and it's checkerboard mask.
typedef struct {
    uint8_t bytes[16];
    uint8_t mask[16];
}
qrc1_Message;

// The ECC level M for the message.
typedef struct {
    uint8_t bytes[10];
}
qrc1_Ecc;

// The format info with the ECC level and mask number.
typedef struct {
    uint8_t bytes[15];
}
qrc1_FormatInfo;

// A stream of bits to read the message and the mask.
typedef struct {
    uint8_t const* bytes;
    uint8_t bit;
}
qrc1_Bitstream;

// A pixel cursor in a 1 bpp image.
typedef struct {
    uint8_t* byte;
    uint8_t bit;
}
qrc1_Cursor;

// A QR Code 1 bpp image.
typedef struct {
    uint8_t bytes[21 * 3];
}
qrc1_QRCode;

static void qrc1_encmessage(uint8_t const* const data, size_t const length, qrc1_Message* message) {
    // Maximum message size is 14 because we need 4 bits for the encoding
    // type, 4 bits for the end of message mark, and 8 bits for the message
    // length.
    size_t const maxlen = 14;
    size_t const len = length > maxlen ? maxlen : length;

    // Use byte encoding (0b0100 << 4), the length high nibble is always 0
    // since len <= 14.
    message->bytes[0] = 0x40;
    // Length low nibble.
    message->bytes[1] = ((uint8_t)len & 15) << 4;

    // Copy the data taking care of the correct nibbles; the second byte
    // already has the length high nibble.
    for (size_t i = 0; i < len; i++) {
        message->bytes[i + 1] |= data[i] >> 4;
        message->bytes[i + 2] = (data[i] & 15) << 4;
    }

    // The last data nibble was written to the high nibble of the last message
    // byte, so the last byte already has a zeroed low nibble which is the
    // end of message indicator.

    // Pad the unused bytes of the message alternating 0xec and 0x11.
    {
        uint8_t padding = 0xec;

        for (size_t i = len; i < 14; i++, padding ^= 0xfd) {
            message->bytes[i + 2] = padding;
        }
    }

    // The checkerboard mask, with bits corresponding to the message bits. The
    // first nibble is 0 because it corresponds to the encoding type in the
    // encoded message (0b0100, byte encoding) which is not masked.
    static uint8_t const mask[16] = {
        0x09, 0x99, 0x99, 0x66, 0x66, 0x66, 0x99, 0x99,
        0x99, 0x66, 0x66, 0x66, 0x99, 0x99, 0x99, 0x96
    };

    // Set the bits for the message bits where the mask must be applied, which
    // excludes the encoding and the end mark

    // Copy the mask to the destination, and zero the four bits that
    // correspond to the end of message mark in the encoded message which
    // are not masked.
    memcpy(message->mask, mask, 16);
    message->mask[len + 1] &= 0xf0;
}

// Galois Field multiplication, it's a black box.
static uint8_t qrc1_gfmul(uint16_t x, uint8_t y, uint16_t const mod) {
    uint8_t r = 0;
    
    while (y != 0) {
        if (y & 1) {
            r ^= (uint8_t)x;
        }
        
        y >>= 1;
        x <<= 1;
        
        if (x > 255) {
            x ^= mod;
        }
    }
    
    return r;
}

// Polynomial modulus, it's also a black box.
static void qrc1_polymod(uint8_t* const a,
                         size_t const lena,
                         uint8_t const* const b,
                         size_t const lenb,
                         uint16_t const mod) {

    // Zero the part of A that will contain the modulus.
    memset(a + lena, 0, lenb - 1);
    size_t const maxlena = lena + lenb - 1;

    // Perform the modulus.
    for (size_t i = 0; i < lena; i++) {
        uint8_t const f = a[i];

        for (size_t j = 0; j < (maxlena - i); j++) {
            a[i + j] ^= qrc1_gfmul(j < lenb ? b[j] : 0, f, mod);
        }
    }
}

// Evaluates the ECC leve M for the encoded message.
static void qrc1_messageecc(qrc1_Message const* const message, qrc1_Ecc* const ecc) {
    // Append 10 zeroes to the message to open space for the ECC.
    uint8_t msg[26];
    memcpy(msg, message->bytes, 16);
    memset(msg + 16, 0, 10);

    // Pre-calculated polynomial for ECC level M.
    static uint8_t const generator[11] = {1, 216, 194, 159, 111, 199, 94, 95, 113, 157, 193};

    // Evaluate the ECC and copy to the destination.
    qrc1_polymod(msg, 16, generator, 11, 285);
    memcpy(ecc->bytes, msg + 16, 10);
}

// Evaluates the format info, this could be hardcoded since we only support
// ECC level M and the checkerboard mask, but it's useful to have it here and
// be able to generate other format infos if necessary.
static void qrc1_formatinfo(qrc1_FormatInfo* const fmtinfo) {
    // Create the format info: 0b00 for ECC level M, 0b000 for the
    // checkerboard mask, 10 zeroed bytes for the ECC of the format info.
    static uint8_t const info[5] = {0, 0, 0, 0, 0};
    memcpy(fmtinfo->bytes, info, 5);
    memset(fmtinfo->bytes + 5, 0, 10);

    // Polynomial for the format info ECC.
    static uint8_t const generator[11] = {1, 0, 1, 0, 0, 1, 1, 0, 1, 1, 1};

    // Evaluate the ECC, the modulus argument is not important for
    // qrc1_polymod here because both polynomials only have 0 and 1 in them.
    qrc1_polymod(fmtinfo->bytes, 5, generator, 11, 0 /*1335*/);

    // Put back the ECC level and the mask index (qrc1_polymod zeroes them).
    memcpy(fmtinfo->bytes, info, 5);

    // Apply the format info mask.
    for (size_t i = 0; i < 15; i++) {
        static uint8_t const mask[15] = {1, 0, 1, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 1, 0};
        fmtinfo->bytes[i] ^= mask[i];
    }
}

// Returns the next bit from the bit stream.
static uint8_t qrc1_getbit(qrc1_Bitstream* const bs) {
    uint8_t const bit = -((*bs->bytes & bs->bit) != 0);
    bs->bit >>= 1;

    if (bs->bit == 0) {
        bs->bit = 0x80;
        bs->bytes++;
    }

    return bit;
}

// Moves the cursor one pixel to the left.
static void qrc1_cursorleft(qrc1_Cursor* const cursor) {
    cursor->bit <<= 1;

    if (cursor->bit == 0) {
        cursor->bit = 0x01;
        cursor->byte -= 1;
    }
}

// Moves the cursor one pixel to the right.
static void qrc1_cursorright(qrc1_Cursor* const cursor) {
    cursor->bit >>= 1;

    if (cursor->bit == 0) {
        cursor->bit = 0x80;
        cursor->byte += 1;
    }
}

// Moves the cursor one pixel up.
static void qrc1_cursorup(qrc1_Cursor* const cursor) {
    cursor->byte -= 3;
}

// Moves the cursor one pixel down.
static void qrc1_cursordown(qrc1_Cursor* const cursor) {
    cursor->byte += 3;
}

// Set the current pixel depending on the mask.
static void qrc1_setblock(qrc1_Cursor const* const cursor, uint8_t const mask) {
    *cursor->byte |= cursor->bit & mask;
}

// Draws one nibble from the given bitstream, using the given mask, moving up.
static void qrc1_nibbleup(qrc1_Cursor* const cursor, qrc1_Bitstream* const bits, qrc1_Bitstream* const mask) {
    qrc1_setblock(cursor, qrc1_getbit(bits) ^ qrc1_getbit(mask));
    qrc1_cursorleft(cursor);
    qrc1_setblock(cursor, qrc1_getbit(bits) ^ qrc1_getbit(mask));
    qrc1_cursorup(cursor); qrc1_cursorright(cursor);
    qrc1_setblock(cursor, qrc1_getbit(bits) ^ qrc1_getbit(mask));
    qrc1_cursorleft(cursor);
    qrc1_setblock(cursor, qrc1_getbit(bits) ^ qrc1_getbit(mask));
    qrc1_cursorup(cursor); qrc1_cursorright(cursor);
}

// Draws one nibble from the given bitstream, using the given mask, moving down.
static void qrc1_nibbledown(qrc1_Cursor* const cursor, qrc1_Bitstream* const bits, qrc1_Bitstream* const mask) {
    qrc1_setblock(cursor, qrc1_getbit(bits) ^ qrc1_getbit(mask));
    qrc1_cursorleft(cursor);
    qrc1_setblock(cursor, qrc1_getbit(bits) ^ qrc1_getbit(mask));
    qrc1_cursordown(cursor); qrc1_cursorright(cursor);
    qrc1_setblock(cursor, qrc1_getbit(bits) ^ qrc1_getbit(mask));
    qrc1_cursorleft(cursor);
    qrc1_setblock(cursor, qrc1_getbit(bits) ^ qrc1_getbit(mask));
    qrc1_cursordown(cursor); qrc1_cursorright(cursor);
}

// Generate the QR Code for the given encoded message, ECC, and format info.
static void qrc1_generate(qrc1_Message const* const message,
                          qrc1_Ecc const* const ecc,
                          qrc1_FormatInfo const* const fmtinfo,
                          qrc1_QRCode* const qrcode) {

    // The fixed blocks of a QR Code version 1.
    static uint8_t const fixed[21 * 3] = {
        0xfe, 0x03, 0xf8, // #######.  ......##  #####...
        0x82, 0x02, 0x08, // #.....#.  ......#.  ....#...
        0xba, 0x02, 0xe8, // #.###.#.  ......#.  ###.#...
        0xba, 0x02, 0xe8, // #.###.#.  ......#.  ###.#...
        0xba, 0x02, 0xe8, // #.###.#.  ......#.  ###.#...
        0x82, 0x02, 0x08, // #.....#.  ......#.  ....#...
        0xfe, 0xab, 0xf8, // #######.  #.#.#.##  #####...
        0x00, 0x00, 0x00, // ........  ........  ........
        0x02, 0x00, 0x00, // ......#.  ........  ........
        0x00, 0x00, 0x00, // ........  ........  ........
        0x02, 0x00, 0x00, // ......#.  ........  ........
        0x00, 0x00, 0x00, // ........  ........  ........
        0x02, 0x00, 0x00, // ......#.  ........  ........
        0x00, 0x80, 0x00, // ........  #.......  ........
        0xfe, 0x00, 0x00, // #######.  ........  ........
        0x82, 0x00, 0x00, // #.....#.  ........  ........
        0xba, 0x00, 0x00, // #.###.#.  ........  ........
        0xba, 0x00, 0x00, // #.###.#.  ........  ........
        0xba, 0x00, 0x00, // #.###.#.  ........  ........
        0x82, 0x00, 0x00, // #.....#.  ........  ........
        0xfe, 0x00, 0x00, // #######.  ........  ........
    };

    // Overwrite the image with the fixed part.
    memcpy(qrcode->bytes, fixed, 21 * 3);

    // Draw the format info.
    qrc1_Cursor cursor;
    cursor.byte = qrcode->bytes + 8 * 3;
    cursor.bit = 0x80;

    for (int i = 0; i < 6; i++) {
        qrc1_setblock(&cursor, -fmtinfo->bytes[i]);
        qrc1_cursorright(&cursor);
    }

    qrc1_cursorright(&cursor);
    qrc1_setblock(&cursor, -fmtinfo->bytes[6]);
    qrc1_cursorright(&cursor);
    qrc1_setblock(&cursor, -fmtinfo->bytes[7]);
    qrc1_cursorup(&cursor);
    qrc1_setblock(&cursor, -fmtinfo->bytes[8]);
    qrc1_cursorup(&cursor);

    for (int i = 0; i < 6; i++) {
        qrc1_cursorup(&cursor);
        qrc1_setblock(&cursor, -fmtinfo->bytes[i + 9]);
    }

    cursor.byte = qrcode->bytes + 20 * 3 + 1;
    cursor.bit = 0x80;

    for (int i = 0; i < 7; i++) {
        qrc1_setblock(&cursor, -fmtinfo->bytes[i]);
        qrc1_cursorup(&cursor);
    }

    for (int i = 0; i < 5; i++) {
        qrc1_cursorup(&cursor);
        qrc1_cursorright(&cursor);
    }

    for (int i = 0; i < 8; i++) {
        qrc1_setblock(&cursor, -fmtinfo->bytes[i + 7]);
        qrc1_cursorright(&cursor);
    }

    // Draw the encoded message using the mask.
    qrc1_Bitstream bs;
    bs.bit = 0x80;
    bs.bytes = message->bytes;

    qrc1_Bitstream mask;
    mask.bit = 0x80;
    mask.bytes = message->mask;

    cursor.byte = qrcode->bytes + 21 * 3 - 1;
    cursor.bit = 0x08;

    for (int i = 0; i < 6; i++) {
        qrc1_nibbleup(&cursor, &bs, &mask);
    }

    qrc1_cursordown(&cursor); qrc1_cursorleft(&cursor); qrc1_cursorleft(&cursor);

    for (int i = 0; i < 6; i++) {
        qrc1_nibbledown(&cursor, &bs, &mask);
    }

    qrc1_cursorup(&cursor); qrc1_cursorleft(&cursor); qrc1_cursorleft(&cursor);

    for (int i = 0; i < 6; i++) {
        qrc1_nibbleup(&cursor, &bs, &mask);
    }

    qrc1_cursordown(&cursor); qrc1_cursorleft(&cursor); qrc1_cursorleft(&cursor);

    for (int i = 0; i < 6; i++) {
        qrc1_nibbledown(&cursor, &bs, &mask);
    }

    qrc1_cursorup(&cursor); qrc1_cursorleft(&cursor); qrc1_cursorleft(&cursor);

    for (int i = 0; i < 7; i++) {
        qrc1_nibbleup(&cursor, &bs, &mask);
    }

    qrc1_cursorup(&cursor);
    qrc1_nibbleup(&cursor, &bs, &mask);

    // Draw the ECC using the mask.
    static uint8_t const eccmask[10] = {0x66, 0x99, 0x96, 0x66, 0x66, 0x66, 0x99, 0x99, 0x66, 0x99};

    bs.bit = 0x80;
    bs.bytes = ecc->bytes;

    mask.bit = 0x80;
    mask.bytes = eccmask;

    qrc1_nibbleup(&cursor, &bs, &mask);
    qrc1_nibbleup(&cursor, &bs, &mask);
    qrc1_cursordown(&cursor); qrc1_cursorleft(&cursor); qrc1_cursorleft(&cursor);

    qrc1_nibbledown(&cursor, &bs, &mask);
    qrc1_nibbledown(&cursor, &bs, &mask);
    qrc1_nibbledown(&cursor, &bs, &mask);
    qrc1_cursordown(&cursor);

    for (int i = 0; i < 7; i++) {
        qrc1_nibbledown(&cursor, &bs, &mask);
    }

    cursor.byte = qrcode->bytes + 12 * 3 + 1;
    cursor.bit = 0x80;

    qrc1_nibbleup(&cursor, &bs, &mask);
    qrc1_nibbleup(&cursor, &bs, &mask);
    qrc1_cursordown(&cursor); qrc1_cursorleft(&cursor); qrc1_cursorleft(&cursor);
    qrc1_cursorleft(&cursor);

    qrc1_nibbledown(&cursor, &bs, &mask);
    qrc1_nibbledown(&cursor, &bs, &mask);
    qrc1_cursorup(&cursor); qrc1_cursorleft(&cursor); qrc1_cursorleft(&cursor);

    qrc1_nibbleup(&cursor, &bs, &mask);
    qrc1_nibbleup(&cursor, &bs, &mask);
    qrc1_cursordown(&cursor); qrc1_cursorleft(&cursor); qrc1_cursorleft(&cursor);

    qrc1_nibbledown(&cursor, &bs, &mask);
    qrc1_nibbledown(&cursor, &bs, &mask);
}

#include <stdlib.h>
#include <stdio.h>

int main(int const argc, char const* const argv[]) {
    if (argc != 2) {
        return EXIT_FAILURE;
    }

    // Encode the message.
    qrc1_Message message;
    qrc1_encmessage(argv[1], strlen(argv[1]), &message);

    // Evaluate the message ECC.
    qrc1_Ecc ecc;
    qrc1_messageecc(&message, &ecc);

    // Encode the format info along with its ECC.
    qrc1_FormatInfo fmtinfo;
    qrc1_formatinfo(&fmtinfo);

    // Draw the resulting QR Code.
    qrc1_QRCode qrcode;
    qrc1_generate(&message, &ecc, &fmtinfo, &qrcode);

    // Output the QR Code.
    for (int y = 0; y < 3; y++) {
        for (int x = 0; x < 54; x++) {
            printf("\u2588");
        }

        printf("\n");
    }

    for (int y = 0; y < 21; y++) {
        printf("\u2588\u2588\u2588\u2588\u2588\u2588");

        for (int x = 0; x < 3; x++) {
            uint8_t const b = qrcode.bytes[y * 3 + x];

            for (uint8_t m = 0x80; m != 0; m >>= 1) {
                printf("%s", b & m ? "  " : "\u2588\u2588");
            }
        }

        printf("\n");
    }

    for (int y = 0; y < 3; y++) {
        for (int x = 0; x < 54; x++) {
            printf("\u2588");
        }

        printf("\n");
    }

    return EXIT_SUCCESS;
}
