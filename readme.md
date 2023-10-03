# Stvff's Image Splicer
![SIS logo, consists of three boxes with the letters in them](/sis_logo.png "SIS logo, consists of three boxes with the letters in them")

See [my HMN project page](https://handmade.network/p/434/stvff-s-image-splicer/) for updates and videos of the program in use.\
Often, I want to or add an image to an image, crop an image to a very specific size in a specific way,
or do something to an image that I consider trivial, but that most basic image editors don't provide in the way I would really like it to be.\
MS Paint did a lot of things really well in my opinion, but it sometimes misses out on those few extra things, Krita is a nice fully-featured editor,
but somewhat slow, and has a lot of options directly in your face, that aren't all very clear.

Why complain about vaguely defined things, when you have the power to try to make exactly the thing you want? In this case, I've never made a proper app/program with full graphical
user interface, so maybe all these other developers are running into some fundamental UX/UI problem, that I just haven't realized.\
So, for 2023's [Wheel Reinvention Jam](https://handmade.network/jam/2023), I started making this image splicer/editor utility program.

## Building
The only dependencies are [Odin](https://odin-lang.org/) (and its core and vendor libraries) and git. To build SIS, first clone the repository:
```
$ git clone https://www.github.com/StevenClifford/sis
```
Then, in the directory that was created, run Odin like so:
```
$ odin build . -o:speed -no-bounds-check
```
This should have produced an executable called `sis` or `sis.exe`. If there is a problem, feel very free to open an issue here on Github.

## Usage of the program, and current implemented features
The program only works on [.qoi](https://qoiformat.org/) image files (I recommend [ImageMagick](https://imagemagick.org/script/download.php) for doing simple conversions), that you give to SIS via the command line:\
```
$ sis image1.qoi image2.qoi image3.qoi #any amount of images
```
This opens those images, and puts the first image and the bottom, the second image above that, etc.\
On the left, you'll see the layer bins. You can move layers by clicking the arrows on the bins. Clicking on the "position" button opens a position input window.
This position is with respect to the topleft of the image on the first layer.\
Clicking the "Save" button in the top left will create an image the size of the first layer, at the offset of the first layer.
In other words, it uses the first layer as a sort of 'window', and draws all the images inside it in order. It writes the result to `sis_result.qoi`

Currently, this is everything SIS does. It is still very limited (and unfinished) in many ways, but it is in the correct direction of where I want it to go.

## Goals
- images on top of images on top of an optional background
- resize, rotate, translate(, maybe transform)
- a good history for undo, and having good control over what 'edits' are done exactly
- everything can be done fully with both mouse-only and keyboard-only
- every setting must have the option of an editable value (as opposed to, for example, only a slider)
- no million buttons overwhelming UI
- support for at least png, jpg and qoi

After those, the following:
- drawing functions
  - straight lines
  - curves (bezier, radius)
  - basic shapes (rectangle, circle, etc)
  - fill bucket
  - free-form selection
  - text
- a port to android (this is not really a feature, but it is extremely desirable)

Everything will be incredibly rough around the corners, but I at least want something on the table for my own sake, and for others to look at.\
\
I also hope to think of a better name at some point.
