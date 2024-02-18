#!/bin/bash

./addsyms.sh
cd enigma-swing/build/jarsfolder
java -cp $(../../../collectcp.sh) cuchaz.enigma.gui.Main
