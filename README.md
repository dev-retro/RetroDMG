# RetroDMG
RetroDMG allows for developers to implement Nintendo Gameyboy gaming into their own application. RetroDMG is part of the Retro project.

## Components
RetroDMG currently consists of a Swift library that implements the Ninetendo Gameboy. It also has a basic application that allows to run the library. While the application will allow the running of ROMs it doesn't provide all the feature a general emulator.

## What is the Retro project
The Retro project provides open source emulated platform libraries for developers.

These platform libraries provide a consistent and developer friendly way to play games for Retro Platforms. 

# Contributing
RetroDMG and the Retro project are open to contribution either open a issue or draft PR in the relevant Github repo or join the discord [here](https://discord.gg/ts3AcnjQmP) to discuss.

Currently MacOS is the only supported platform for development, however linux is being actively worked on. Both Xcode and Visual Studio Code are supported for development.

## Xcode 
load the swift package and run either the `RetroDMGApp` or `RetroDMGApp (Release)` schemes

## Visual Studio Code
### Pre-requisites 
- Xcode (currently required for metal shader compilation)
- Swift either via Xcode or through Swiftly 

To run use either the `Debug RetroDMGApp (Full Build)` or `Release RetroDMGApp (Full Build)` launch configurations



## C FFI

RetroDMG exposes a small, stable C ABI for non-Swift consumers.

- Header: `FFI/RetroDMGFFI.h`
- Symbols are exported from the dynamic library product `RetroDMG`.

Quick example (C):

```c
#include "RetroDMGFFI.h"

int main(void) {
	uint64_t h = retrodmg_create();
	char *name = retrodmg_name(h);
	// ... use name
	retrodmg_string_free(name);

	// load ROM bytes, e.g. from file
	// retrodmg_load_rom(h, romData, romLen);

	retrodmg_start(h);

	int pixels = 160*144;
	int32_t *fb = (int32_t*)malloc(sizeof(int32_t)*pixels);
	retrodmg_viewport_copy(h, fb, pixels);
	free(fb);

	retrodmg_destroy(h);
	return 0;
}
```

Build steps (macOS, fish shell):

```fish
swift build -c release
```

Link your app against the produced `libRetroDMG.dylib` and include `FFI/RetroDMGFFI.h`.

