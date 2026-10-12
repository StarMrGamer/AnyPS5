#!/bin/bash
cd /home/faky/anyps5-homebrew/PPSA21564/run
export LD_LIBRARY_PATH=./libs:$LD_LIBRARY_PATH
export APS5_RAYTRACING=miss
./app.elf "$@"
