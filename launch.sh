#!/bin/bash

if [ ! -d "enigma-swing/build/jarsfolder" ]; then
    ./gradlew copyDeps
fi
./addsyms.sh
cd enigma-swing/build/jarsfolder
java -cp $(../../../collectcp.sh) cuchaz.enigma.gui.Main
