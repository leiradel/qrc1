# qrc1

A QR Code version 1 generator written in Z80 assembly.

## Source Code

The generator is in the `src/qrc1.asm` file. It doesn't output anything by itself, it only encodes the given message. To actually see something, some platform specific code must be written that takes the encoded message and translates it to pixels on the screen.

In the `src/zx81/zx81.asm` file there is code that plots the encoded message onto the ZX81 screen. The assembly file also contains a BASIC program that takes care of user input reading, poking the message into the appropriate memory location for the encoder to do its job, and calling into the machine code routine that will encode the message and draw it onto the screen.

There's also a C version at `src/c/qrc1.c`, which I wrote only to validate that I could really read the original JavaScript that encodes the message (available in the second issue of the [Paged Out!](https://pagedout.institute/) magazine).


## Limitations

The generator is hardcoded to QR Code version 1, binary data encoding, ECC level M, and mask 0. While I think a generator capable of encoding messages with any combination of the QR Code capabilities is possible for the Z80, the amount of memory would make it too expensive to embed into other programs that may want to generate them.

Even with those limits, the generated QR Code has 14 bytes worth of data which makes it practical for a range of applications.

## License

MIT, enjoy.
