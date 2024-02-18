#!/bin/bash

asm_rel_path="../asm"
symlinks_path="enigma-swing/build/jarsfolder"

if [ ! -d "$symlinks_path" ]; then
    echo "Directory $symlinks_path doesn't exist, copy dependencies first"
    exit 1
fi

enigma=$(find enigma-swing/build/libs/ -iname "enigma-swing-?.?.?+local.jar")
enigma_base=$(basename "$enigma")
enigma_symlink_path="$symlinks_path/$enigma_base"
if [ ! -L "$enigma_symlink_path" ]; then
    echo "Creating symlink $enigma_symlink_path"
    ln -s ../libs/$enigma_base $enigma_symlink_path
fi
asm_path=$(readlink -f $PWD/$asm_rel_path)
if [ ! -e "$asm_path" ]; then
    echo "Path $asm_path doesn't exist, clone and build asm and asm-tree first"
    exit 1
fi
asm_name="asm-9.4.jar"
if [ -f "$symlinks_path/$asm_name" ]; then
    echo "Removing $symlinks_path/$asm_name"
    rm "$symlinks_path/$asm_name"
fi
asm_built_path=$(find $asm_path/asm/build/libs/ -iname "asm*.jar")
asm_built_name=$(basename $asm_built_path)
if [ ! -L "$symlinks_path/$asm_built_name" ]; then
    echo "Adding a symlink to $asm_built_path"
    ln -s "$asm_built_path" "$symlinks_path/$asm_built_name"
fi
asm_tree_name="asm-tree-9.4.jar"
if [ -f "$symlinks_path/$asm_tree_name" ]; then
    echo "Removing $symlinks_path/$asm_tree_name"
    rm "$symlinks_path/$asm_tree_name"
fi
asm_tree_built_path=$(find $asm_path/asm-tree/build/libs/ -iname "asm-tree*.jar")
asm_tree_built_name=$(basename $asm_tree_built_path)
if [ ! -L "$symlinks_path/$asm_tree_built_name" ]; then
    echo "Adding a symlink to $asm_tree_built_path"
    ln -s "$asm_tree_built_path" "$symlinks_path/$asm_tree_built_name"
fi
