# qrc1

A QR Code version 1 generator written in Z80 assembly.

## Source Code

The generator is in the `src/qrc1.asm` file. It doesn't output anything by itself, it only encodes the given message. To actually see something, some platform specific code must be written that takes the encoded message and translates it to pixels on the screen.

`src/qrc1.asm` should assemble with virtually any Z80 assembler since it doesn't use anything but quite standard features found everywhere. If you do find issues when assembling `src/qrc1.asm` please let me know and I'll try to fix them.

## Using

1. Implement the following routines for your platform:
    * `qrc_pixel_left`: move the current pixel cursor to the left
    * `qrc_pixel_right`: move the current pixel cursor to the right
    * `qrc_pixel_up`: move the current pixel cursor up
    * `qrc_pixel_down`: move the current pixel cursor down
    * `qrc_set_pixel`: set (make black) the current pixel
        * These routines are free to use `A`, `C`, `H`, and `L`. `A` is changed by the caller so it should be used only for temporary values, but `C`, `H`, and `L` are **not** changed and can be used for persistent values.
1. Set the byte at `qrc1_message` to the message length (maximum 14 bytes)
1. Write the message bytes after the length
1. Call `qrc1_encmessage` to encode the message
1. Set `C`, `H`, and `L` to represent the top-left pixel of the QR Code in the screen (platform dependent)
1. Call `qrc1_print`

## Examples

### ZX81

In the `src/zx81/zx81.asm` file there is code that plots the encoded message onto the ZX81 screen. It must be used together with `src/zx81/zx81.bas`, which takes care of user input reading, poking the message into the appropriate memory location for the encoder to do its job, and calling into the machine code routine that will encode the message and draw it onto the screen.

The Makefile in the `src/zx81` folder uses [zasm](https://k1.spdns.de/Develop/Projects/zasm/) to assemble the assembly file, and [zxtext2p](http://freestuff.grok.co.uk/zxtext2p/index.html) to convert the BASIC file to a `.p` file. A Lua script will orchestrate everything and produce the final `.p` file to use with an emulator. Just go into `src/zx81` and run `make`.

> `zxtext2p` has been slightly changed to auto-run the generated program at the first BASIC line.

## Limitations

The generator is hardcoded to QR Code version 1, binary data encoding, ECC level M, and mask 0. While I think a generator capable of encoding messages with any combination of the QR Code capabilities is possible for the Z80, the amount of memory would make it too expensive to embed into other programs that may want to generate them.

Even with those limits, the generated QR Code has 14 bytes worth of data which makes it practical for a range of applications.

## Etc

There's a C version at `src/c/qrc1.c`, which I wrote only to validate that I could really understand the original JavaScript that encodes the message (available in the second issue of the [Paged Out!](https://pagedout.institute/) magazine).

## License

MIT, enjoy.
