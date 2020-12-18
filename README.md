# qrc1

QR Code versions 1 and 11 generators written in Z80 assembly.

## Source Code

The generators are in the `src/qrc1.asm` and `src/qrc11.asm` file. They don't output anything by themselves, they only encode the given message. To actually see something, some platform specific code must be written that takes the encoded message and translates it to pixels on the screen.

The assembly files should assemble with virtually any Z80 assembler since it doesn't use anything but quite standard features found everywhere. If you do find issues when assembling please let me know and I'll try to fix them.

## Using

### Version 1

1. Implement the following routines for your platform:
    * `qrc_pixel_up`: move the current pixel cursor up
    * `qrc_pixel_down`: move the current pixel cursor down
    * `qrc_pixel_left`: move the current pixel cursor to the left
    * `qrc_pixel_right`: move the current pixel cursor to the right
    * `qrc_invert_pixel`: invert the current pixel
        * These routines are free to use `A`, `C`, `H`, `L`, and `IX`. `A` is changed by the caller so it should be used only for temporary values, but `C`, `H`, `L`, and `IX` are **not** changed and can be used for persistent values. Do not change any other registers.
1. Set the byte at `qrc1_message` to the message length (maximum 14 bytes)
1. Write the message bytes after the length
1. Call `qrc1_encmessage` to encode the message
1. Make sure the screen area that will receive the pixels for the QR Code is filled with white pixels (platform dependent)
1. Set `C`, `H`, `L`, and `IX` to represent the top-left pixel of the QR Code in the screen (platform dependent)
1. Call `qrc1_print`

### Version 11

1. Implement the same routines for your platform as the version 1
1. Set the byte at `qrc11_message + 1` to the message length (maximum 14 bytes, **notice the `+1`**)
1. Write the message bytes after the length
1. Call `qrc11_encmessage` to encode the message
1. Make sure the screen area that will receive the pixels for the QR Code is filled with white pixels (platform dependent)
1. Set `C`, `H`, `L`, and `IX` to represent the top-left pixel of the QR Code in the screen (platform dependent)
1. Call `qrc11_print`

## Examples

### ZX81

![https://cutt.ly/QRC1](https://raw.githubusercontent.com/leiradel/qrc1/master/qrc1.png)

In the `src/zx81/zx81.asm` file there is code that plots the encoded message onto the ZX81 screen. It must be used together with `src/zx81/zx81.bas`, which takes care of user input reading, poking the message into the appropriate memory location for the encoder to do its job, and calling into the machine code routine that will encode the message and draw it onto the screen.

The Makefile in the `src/zx81` folder uses [Pasmo](http://pasmo.speccy.org/) to assemble the assembly file, and [zxtext2p](http://freestuff.grok.co.uk/zxtext2p/index.html) to convert the BASIC file to a `.p` file. A [Lua](https://www.lua.org/) script will orchestrate everything and produce the final `.p` file to use with an emulator. Just go into `src/zx81` and run `make`.

Notice that the program must run in FAST mode, as it uses the `IY` register. While it would be possible not to use it, at the expense of performance, there's not really much to see on the screen while the message is encoded and the barcode printed onto the screen.

> `zxtext2p` has been slightly changed to auto-run the generated program at the first BASIC line.

### ZX Spectrum

![https://cutt.ly/QRC1](https://raw.githubusercontent.com/leiradel/qrc1/master/qrc1zxs.png)

Similarly to the ZX81, `src/spectrum/zxs1.asm` has code to encode and plot messages as QR Code version 1 for the ZX Spectrum. The `src/spectrum/zxs1.bas` file has a loader for the binary part of the program, and BASIC commands that will read the message, poke it to the appropriate memory location, and call the encoder and plotter.

[zmakebas](https://github.com/z00m128/zmakebas) was used to convert the BASIC program to a `.tap` file, and a Lua script will take care of building everything and producing the final tape.

There are three different plotters for the ZX Spectrum, each one using a different size for the barcode modules: 1x1 square pixels, 2x2, and 4x4. It can be easily selected by commenting and uncommenting the appropriate lines at the top of `src/spectrum/zxs1.asm`.

![https://cutt.ly/QRC1](https://raw.githubusercontent.com/leiradel/qrc1/master/qrc11.png)

`src/spectrum/zxs11.asm` and `src/spectrum/zxs11.bas` implement code to plot messages as QR Code version 11, it works just as the version 1 above.

## Limitations

The generators are hardcoded to QR Code versions 1 and 11, binary data encoding, ECC level M, and mask 0. While I think a generator capable of encoding messages with any combination of the QR Code capabilities is possible for the Z80, the amount of memory would make it too expensive to embed into other programs that may want to generate them.

Even with those limits, the generated QR Code version 1 has 14 bytes worth of data which makes it practical for a range of applications. If 14 bytes are not enough, version 11 provides a capacity of up to 251 bytes.

## Etc

There's a C version at `etc/qrc1.c`, which I wrote only to validate that I could really understand the original JavaScript that encodes the message (available in the second issue of the [Paged Out!](https://pagedout.institute/) magazine).

There's also a modified version of **zxtext2p** that will auto-run the generated program starting at the first line.

## Links

* [ISO/IEC18004](https://www.swisseduc.ch/informatik/theoretische_informatik/qr_codes/docs/qr_standard.pdf)
* [Paged Out! magazine issue #2](https://pagedout.institute/download/PagedOut_002_beta2.pdf) (page 20)
* [Website for the article published on PagedOut!](https://www.quaxio.com/an_artisanal_qr_code.html)
* [Thonky QR Code Tutorial](https://www.thonky.com/qr-code-tutorial/)
* [Wikipedia QR Code article](https://en.wikipedia.org/wiki/QR_code)

## License

MIT, enjoy.
