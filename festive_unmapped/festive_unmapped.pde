//Adapted from the Fadecandy example "strip64_unmapped" (RAINBOW FADE!!!)
//I assume it was written by Micah Scott, https://github.com/scanlime/

//From the original description:

// Demonstration that pokes colors into the LEDs directly instead
// of mapping them to pixels on the screen. You may want to do this
// if you have your own mapping scheme that doesn't fit well with
// a 2D display.

//My modifications were to make this more festive, used in some lights strung across the ceiling to dispel some of the innate
//dungeon-like character of my office. I was aiming for something that would be colourful, provide enough brightness to work by,
//produce an overall warm light tone (de-emphasizing blues) and where the shifting would be smooth so as not to be too distracting.

//This is using eight 5 metre strands of WS2812B LEDs connected to a FadeCandy with default (0-511) addressing. It's being run
//off of an old Mac because that's what was conveniently available, but this should run on a Raspberry Pi just fine for home use.

OPC opc;

//Overriding the default colour balance, which on my chains is pretty harshly cold. These values
//warm it up a bit.
float gamma = 2.5;
float red = 1.0;
float green = 0.8;
float blue = 0.5;

//Range of values for HSB scale (0 to pixelInterval). Changing this affects pretty much everything
//(as the modulo to determine intervals caclulations are different) and requires adjusting the
//other setup values below.
float pixelInterval = 512;
int framesPerSecond = 120;
int frameCounter = 0;

//A distributed dimming/twinkling effect, not following a wave driven by the timer.
int twinkleInterval = 7; //how many LEDs between twinkles in a set
int twinkleOffset = 3; //how much each twinkle set is offset from the previous
int twinkleStart = twinkleOffset; //Start the first twinkle this far ahead of the start of the address space. (this will change)
float twinkleSeconds = 2; //time spent dimming, then brightening
float twinkleDim = .8; //factor brightness reduction

//Propagation speed of hue waves; multiplier of millisecond count.
float hueSpd = 0.06;

//Wavenumber (inverse of wavelength) of hue waves/cycles per pixel interval.
float hueWavNum = 1;

//Propagation speed of saturation waves; multiplier of millisecond count.
float satSpd = 0.15;

//Wavenumber (inverse of wavelength) of saturation waves per pixel interval.
float satWavNum = 25;

//Vertical translation of saturation waves. Raises/lowers all saturation values.
//Negative makes a wide region of desaturation with a short peak of saturation.
// Values of -1 to +1 will make sense, multiplied by the
float satVertTrans = -125;

void setup()
{
  opc = new OPC(this, "127.0.0.1", 7890);
  opc.setColorCorrection(gamma, red, green, blue);
  frameRate(framesPerSecond);
  colorMode(HSB, pixelInterval);
}

void draw()
{

  for (int i = 0; i < 512; i++) {
    //Set some defaults, in case we want to comment out any of the waves.
    //Sets brightness to 100%.
    float brightness = 512 * pixelInterval; //overridden by twinkling
    float saturation = .15 * pixelInterval; //overridden by desaturation (white) waves
    float hue = i % pixelInterval; //overridden by hue cycles

    //****************
    //Twinkling effect

    //Reset twinkling counter if a cycle has elapsed, and snap back the start address if it's too far forward
    if (frameCounter >= (framesPerSecond * twinkleSeconds)) { //One cycle per twinkleSeconds period, counted in frames
      frameCounter = 0;
      twinkleStart += twinkleOffset; //Move the start address by the offset
      if (twinkleStart >= twinkleInterval) { //If the start offset is the size (or larger) of the interval...
        twinkleStart %= twinkleInterval; //...use the modulus of the interval to find a new start offset within the first interval,
        //otherwise there will be a growing wall of non-twinkling at the start of the address space, eventually consuming the whole space
      }
    }
    //Twinkling brightness adjustments
    if (i % twinkleInterval==twinkleStart) { //Select a group of LED addresses spaced at intervals, with a starting offset
      if (frameCounter < (framesPerSecond * twinkleSeconds/2)) { //Dimming for first half of the cycle
        //A brightness reduction of the max dimming * framecount as a fraction of half of the frames per cycle (max dimming mid-cycle)
        brightness -= twinkleDim * pixelInterval * frameCounter/(framesPerSecond * twinkleSeconds/2);
      } else { //Returning to full brightness for the second half
        //A brightness reduction that flips. Half of the cycle is subtracted from the frameCounter (because we're counting frames post-midpoint)
        //and then a fraction is made of 1 minus that new count as a fraction of half of the frames per cycle.
        brightness -= twinkleDim * pixelInterval * (1-(frameCounter-(framesPerSecond * twinkleSeconds/2)))/(framesPerSecond * twinkleSeconds/2);
      }
    }
    frameCounter++; //increment after twinkle adjusment

    //***********************************
    //Hue cycle effect (aka RAINBOW FADE)

    //This is just a continuous rainbow fading of all pixels
    hue = (millis() * hueSpd + i * hueWavNum) % pixelInterval;

    //****************************
    //White chasing pattern effect

    //Desaturation waves move through the rainbow background. This is an absolute-value line function, repeating on intervals.
    //Think of it like this: \/\/\/\/\/
    //The vertical translation allows this function to produce saturation alues above 100% or below 0%. I use a negative translation to create a
    //region of white that is a few pixels wide, to make the effect more noticeable. The eye naturally tries to track the coloured portions
    //rather than the desaturated expanses.
    saturation = abs(pixelInterval - (2 * ((millis() * satSpd + i * satWavNum) % pixelInterval))) + satVertTrans;

    //Some leftover attempts at producing a sharp brightness-reduction wave
    //brightness = 100 - ((millis() * 0.02 + i * 3 ) % 100) * ((millis() * 0.02 + i * 3 ) % 100)/100;

    //The 511-i sets the wave direction in reverse, which *visually* makes the waves appear to
    //emanate from the FadeCandy outwards
    opc.setPixel(511-i, color(hue , saturation , brightness ));
  }

  // When you haven't assigned any LEDs to pixels, you have to explicitly
  // write them to the server. Otherwise, this happens automatically after draw().
  opc.writePixels();
}