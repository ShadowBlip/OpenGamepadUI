
.PHONY: build
build:
	# Does -I/usr/include/libevdev-1.0
	#g++ -static -L/usr/lib $(shell pkg-config --cflags libevdev) evdev.cpp
	g++ evdev.cpp -levdev -I/usr/include/libevdev-1.0
