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

