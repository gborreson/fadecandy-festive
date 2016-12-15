# fadecandy-festive
Processing sketches to produce a colourful &amp; calming festive effect on strands of LEDs connected to a FadeCandy controller, suitable
for holiday lights. I have it running on 512 WS2812B LEDs strung above my office.

## festive_unmapped
Unmapped (directly addressed) colourful display that can be adjusted to fit any size of LED address space.

Supports the following effects:

1. Hue shifting, either in a continuous (all hue in cycle) or in a defined-range of hues mapped to a sin wave.
2. Waves of desaturation (white) faded evenly and moving through the strands.
3. Twinkling effects, which can be presented as distributed winking/dimming of individual LEDs or a wave of dimming, depending on offsets.
