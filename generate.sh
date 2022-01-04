#!/bin/bash

git submodule update --init --recursive
zig translate-c -Ilibs\raylib\src -I libs\raylib\external -Ilibs\raylib\src\external\glfw\include libs/raylib/src/raylib.h &> libs/raylib.zig
zig translate-c -Ilibs\raylib\src -I libs\raylib\external -Ilibs\raylib\src\external\glfw\include libs/raylib/src/rlgl.h &> libs/rlgl.zig
zig translate-c -Ilibs\raylib\src -I libs\raylib\external -Ilibs\raylib\src\external\glfw\include libs/nbnet/nbnet.h -lc &> libs/nbnet.zig
cd libs/cimgui/generator && luajit generator.lua gcc "internal" glfw opengl2 opengl3 && cd ../../../