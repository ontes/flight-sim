# Super-Realistic Flight Simulator
A game made for fun and also as an university project. Coded in Zig using almost no libraries (except system APIs and included stb_image).

## How To Build
Download Zig version 0.9.1 (https://ziglang.org/download/) (**version does matter!**)  
Run `zig build -Drelease-fast run` to compile and run the app  
You can remove `-Drelease-fast` for a debug build, or remove `run` to just compile it (the executable is in `zig-out/bin`)  
If you want to run the executable, you have to run it alongside the `assets` folder  
***NOTE:** Only Linux and Windows 64bit are supported and decent GPU is required*

## Controls
W,S,A,D - control the plane  
F - toggle headlights  
E - toggle camera orientation  
scrolling - change camera position

## Objective
I've placed presents in the capital cities. Fly over them with the plane to collect them. At the bottom of the screen is a progress bar.

## Additional Credits
Earth Textures - https://visibleearth.nasa.gov/collection/1484/blue-marble  
Water Normal Texture - https://www.cadhatch.com/seamless-water-textures  
Plane Model - https://sketchfab.com/3d-models/low-poly-plane-76230052903540e9aeb46b7db35329e4  
Present Models - https://kenney.nl/assets/holiday-kit  
Coordinates of Capital Cities - https://www.jasom.net/list-of-capital-cities-with-latitude-and-longitude/  
PNG Loading - https://github.com/nothings/stb
