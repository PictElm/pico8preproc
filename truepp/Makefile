all: truepp
run: truepp
	./truepp 0.0.5 ../hidden/versions/0.0.5/bin/pico-8/pico8 ../tests/some.p8.lua
.PHONY: all run

truepp: main.c 3rd/xed/obj/libxed.a
	$(CC) main.c -o truepp -L3rd/xed/obj -lxed -I3rd/xed/obj/wkit/include/xed

3rd/xed/obj/libxed.a:
	(cd 3rd/xed; ./mfile.py)
