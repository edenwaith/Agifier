# Agifier
Convert an image to look like an 8-bit image from an AGI-era 1980s Sierra On-Line computer game.  This project consists of two parts: a command line tool (`agi_image_converter`) which is written in Objective-C, and a plug-in for the [Acorn](https://flyingmeat.com/acorn/) image editor.  The script and plug-in produce similar, but not identical results.  The script generates double-width pixels like in an AGI-style Sierra game (e.g. King's Quest 1-3, Space Quest 1-2) and adheres to a proper 16 color EGA palette.  The Acorn plug-in produces a closer color match and the pixels are not double-width, but are pixelated and the image is reduced to 200 pixels in height.

**Original**  
!["Original High Sierra Image"](images/High-Sierra-Small.jpg "Original High Sierra Image")

**Modified by `agi_image_converter` script**  
!["Modified High Sierra Image - agi_image_converter script"](images/High-Sierra_agi.png "Modified High Sierra Image - agi_image_converter script")

**Modified by Agifier Acorn Plug-In**  
!["Modified High Sierra Image - Agifier Plug-In"](images/High-Sierra_Closer_EGA_Colors.png "Modified High Sierra Image - Agifier Plug-In")


## AGI Image Converter Script

The `agi_image_converter` is a command-line utility for the Mac written in Objective-C.  It will take the given image and convert it, and then generate a new image with `_agi.png` appended to the file name taken from the original image.

To compile: `gcc -w -framework Foundation -framework AppKit -framework QuartzCore agi_image_converter.m -o agi_image_converter`

To run: `./agi_image_converter path/to/image.png`

## Acorn Plug-In

The Agifier project was built with Xcode 11 on macOS Mojave.  The `Agifier.acplugin` file can be copied to `~/Library/Application Support/Acorn/Plug-Ins` to work with Acorn.  The Agifier plug-in is available in the **Filter > Stylize > Agifier** menu.

