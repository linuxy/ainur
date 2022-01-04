# ainur
A simple zig gamedev template for raylib+imgui, nbnet and zlm

Builds against zig 0.9.0-dev.1561+5ebdc8c46

Verified building for Windows 11 and Void Linux using the following packages:

```
libX11-devel-1.7.2_3
libXcursor-devel-1.2.0_1
libXrandr-devel-1.5.2_1
libXinerama-devel-1.1.4_1
libXi-devel-1.7.10_1
```

Building
```
[nobody@void ainur]$ ./generate.sh
[nobody@void ainur]$ zig build
COPY: example/assets/public-sans.ttf to zig-out/bin/public-sans.ttf
COPY: example/assets/RobotoMono-Regular.ttf to zig-out/bin/RobotoMono-Regular.ttf
[nobody@void ainur]$ ./zig-out/bin/example
```
