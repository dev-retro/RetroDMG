#!/bin/bash

METAL_FILES=`ls ./Sources/RetroDMGApp/platforms/macOS/Shaders/*.metal`

for path in $METAL_FILES
do
	FILE_NAME=${path%.*}
	xcrun -sdk macosx metal -c $path -o ${FILE_NAME}.air
done

AIR_FILES=`ls ./Sources/RetroDMGApp/platforms/macOS/Shaders/*.air`

for path in $AIR_FILES
do
  xcrun metal-ar r default.metalar $path
done

xcrun -sdk macosx metallib default.metalar -o Sources/RetroDMGApp/default.metallib

rm default.metalar

for path in $AIR_FILES
do
  rm $path
done