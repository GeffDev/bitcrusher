# Bitcrusher
Currently only works on signed 16 bit uncompressed WAV files.
Only shifts the bit depth by fixed numbers.

## How to build
`zig build -Doptimize=ReleaseFast`

## How to run
`./bitcrush <file_name> <output_file_name> <bit_depth_shifter>`