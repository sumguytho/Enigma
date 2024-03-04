# Enigma

A tool for deobfuscation of Java bytecode. Forked from <https://bitbucket.org/cuchaz/enigma>, copyright Jeff Martin.

## License

Enigma is distributed under the [LGPL-3.0](LICENSE).

Enigma includes the following open-source libraries:

- A [modified version](https://github.com/FabricMC/procyon) of [Procyon](https://bitbucket.org/mstrobel/procyon) (Apache-2.0)
- A [modified version](https://github.com/FabricMC/cfr) of [CFR](https://github.com/leibnitz27/cfr) (MIT)
- [Guava](https://github.com/google/guava) (Apache-2.0)
- [SyntaxPane](https://github.com/Sciss/SyntaxPane) (Apache-2.0)
- [FlatLaf](https://github.com/JFormDesigner/FlatLaf) (Apache-2.0)
- [jopt-simple](https://github.com/jopt-simple/jopt-simple) (MIT)
- [ASM](https://asm.ow2.io/) (BSD-3-Clause)

## Usage

Pre-compiled jars can be found on the [fabric maven](https://maven.fabricmc.net/cuchaz/enigma-swing/).

### Launching the GUI

`java -jar enigma.jar`

### On the command line

`java -cp enigma.jar cuchaz.enigma.command.Main`

## Dependecies

 - java-17-openjdk-devel
 - java-17-openjdk-jmods

## Launching

Before this abomination can be launched the project needs to be build and dependencies copied to
a fixed folder:
```
./gradlew build
./gradlew copyDeps
```

Another prerequisite is that asm and asm-tree should be build before launcing.

Once all of that has been done:
```
./launch.sh
```

## Other notes

it seems that the stack map frame indicates more labels then there is bytecode of code
which is what causes crash for the h file thing

then the asm says class version 49 and below should use f_new and the h thing doesn't
the se 5 documentation isn't available online anymore so who even knows what's up with it
actually, using wayback machine for 2012 it's possible to see that at some point the specs
were se5/se6, perhaps they are not that different (but then what is?)
https://web.archive.org/web/20120309032418/http://docs.oracle.com/javase/specs/jvms/se5.0/html/ClassFile.doc.html

## What was encountered so far

com/google/common/util/concurrent/d$a had some issue, didn't save. hmmm.

it's very weird, com/google/common/collect/SortedLists.class has class version 49.0 but uses StackMapTable attributes
which were only added in java 6 (50.0)

besides, the table is said to start at 1690 and end at 1706 but the last entry is full_stack at 1705 which has 15 stack entries
and even if it didn't full_stack would never fit in one byte
either full_stack had different meaning or it's a bogus byte and should be ignored, then next attribute name index starts
at byte offset 1706, which would be RuntimeVisibleParameterAnnotations, after that comes Signature which seems to be valid,
the mystery is solved, I guess

sometimes the stack_map_frame entries are padded with 0xff which wouldn't be an issue if it wasn't for this stupid word,
"sometimes"
com/threerings/renderer/q has padding at 2073 (map starts at 2048)

it seems that full_frame entries are padded with 0xff to the nearest 2 boundary

and there it is, com/google/common/util/concurrent/c has full_frame start at 2143, unpadded

perhaps the jvm parser is implemented as non-deterministic fsm which just skips sequence points at which parsing is
impossible which is why it can be either padded or not

com/google/common/cache/CacheBuilder, stack_map_frame at 6551, how is it supposed to be parsed? are 0x3f (63)
and 0x01 valid frames? or do I just ignore them as well?

com/threerings/editor/swing/TreeEditorPanel died next, offset: 15623, stack map table starts at 15592, ends at 15683
it ignores the maxLocals set by code attribute, it declares 6 locals but uses 7 in some frame at some point

com/google/common/util/concurrent/d$c fails at reference resolution, not stack map table related since its code doesn't have it (yet?)
it seems that the locals for some method don't exist, perhaps, this is because I drop variable info that doesn't fit in
the table size of numLocals but probably not
actually, it was me who introduced this bug, I just used local and stack arrays in FrameNode ctor even when they were null
clinit method of this class uses same1 frame as first frame reference

when exporting the jar new problem emerged: some inner class doesn't have outer class (null)
some class is com/threerings/tudey/config/TagConfig
so, TagConfig says com/threerings/tudey/config/a is its inner class and doesn't provide outer class for it and Enigma has a problem
with this
from my understanding this may mean that com/threerings/tudey/config/TagConfig and com/threerings/tudey/config/a may have been in the
same source file which Enigma deems an error for some reason
another possibility pointed out py JVMS is that it can also be either an anonymous or a nested class
to me this seems like an error on Enigma's part
com/threerings/tudey/config/a also has InnerClasses entry in which it points to itself with outer class being null

the class is com/google/common/eventbus/g, stack map table starts at 5561, ends at 5638
stack map table declares 5 entries and there are 5 of them but delta offset is 0xffff

I've realized that by just making offsetDelta overflow I may have glossed over some bigger issue and should look into it once more
The same goes for labels, there might be other underlying errors

when trying to import exported pcode jar there is an error in com/google/common/io/e, stack map table for method aH starts at 707
which seems to be an invalid frame
I think there are 2 errors at play, something got exported / imported wrong + my check doesn't check that there are 6912 local variable
which just can't fit in the file
it seems the borked class has StackMap attribute instad of StackMapTable that the original had, must have something to do with ClassWriter
it had to do with version, if I deduce version from attributes used then it's all ok, I guess I no longer need to comment out that class
warning thing

I can't run exported pcode, it has some error in com/threerings/opengl/e, when calling createSnapshot:
```
Error: A JNI error has occurred, please check your installation and try again
Exception in thread "main" java.lang.VerifyError: Instruction type does not match stack map
Exception Details:
  Location:
    com/threerings/opengl/e.createSnapshot(Z)Ljava/awt/image/BufferedImage; @127: iload_3
  Reason:
    Type 'java/awt/image/BufferedImage' (current frame, locals[1]) is not assignable to integer (stack map, locals[1])
  Current Frame:
    bci: @127
    flags: { }
    locals: { 'com/threerings/opengl/e', 'java/awt/image/BufferedImage', integer, integer, integer, 'java/nio/ByteBuffer', '[B' }
    stack: { }
  Stackmap Frame:
    bci: @127
    flags: { }
    locals: { 'com/threerings/opengl/e', integer, integer, integer, integer, 'java/nio/ByteBuffer', 'java/awt/image/ComponentColorModel', 'java/awt/image/BufferedImage', '[B', integer }
    stack: { }
  Bytecode:
    0x0000000: 2ab4 0075 b600 df3d 2ab4 0075 b600 e23e
    0x0000010: 1b99 0007 07a7 0004 0659 3604 1c68 1d68
    0x0000020: b800 e83a 0503 031c 1d1b 9900 0911 1908
    0x0000030: a700 0611 1907 1114 0119 05b8 00f0 bb00
    0x0000040: f259 1103 e8b8 00f8 1b03 1b99 0007 06a7
    0x0000050: 0004 0403 b700 fb4c bb00 fd59 2b03 1c1d
    0x0000060: 1504 01b8 0103 0301 b701 0659 4cb6 010a
    0x0000070: b601 10c0 0112 b601 163a 061d 0464 3e1d
    0x0000080: 9b00 1b19 0519 061d 1c68 1504 681c 1504
    0x0000090: 68b6 011c 5784 03ff a7ff e72b b0       
  Stackmap Table:
    append_frame(@24,Integer,Integer)
    same_locals_1_stack_item_frame(@25,Integer)
    full_frame(@51,{Object[#2],Integer,Integer,Integer,Integer,Object[#234]},{Integer,Integer,Integer,Integer})
    full_frame(@54,{Object[#2],Integer,Integer,Integer,Integer,Object[#234]},{Integer,Integer,Integer,Integer,Integer})
    full_frame(@82,{Object[#2],Integer,Integer,Integer,Integer,Object[#234]},{Uninitialized[#62],Uninitialized[#62],Object[#244],Integer,Integer})
    full_frame(@83,{Object[#2],Integer,Integer,Integer,Integer,Object[#234]},{Uninitialized[#62],Uninitialized[#62],Object[#244],Integer,Integer,Integer})
    full_frame(@127,{Object[#2],Integer,Integer,Integer,Integer,Object[#234],Object[#242],Object[#253],Object[#280],Integer},{})
    chop_frame(@155,1)

        at java.lang.Class.getDeclaredMethods0(Native Method)
        at java.lang.Class.privateGetDeclaredMethods(Class.java:2701)
        at java.lang.Class.privateGetMethodRecursive(Class.java:3048)
        at java.lang.Class.getMethod0(Class.java:3018)
        at java.lang.Class.getMethod(Class.java:1784)
        at sun.launcher.LauncherHelper.validateMainClass(LauncherHelper.java:670)
        at sun.launcher.LauncherHelper.checkAndLoadMain(LauncherHelper.java:652)
```
this is due to the fact that I drop locals and stack variables that don't fit in preallocated buffers

can't compile java sources with remapped jar, the issue is that com/google/inject/a/a inherits itself, javac can't handle cyclic inheritance
for interfaces, import tree:
[loading <spiral>/code/projectx-pcode.jar(/com/threerings/crowd/chat/client/a$c.class)]
[loading <spiral>/code/projectx-pcode.jar(/com/threerings/crowd/chat/data/a.class)]
[loading <spiral>/code/projectx-pcode.jar(/com/threerings/crowd/client/l.class)]
[loading <spiral>/code/projectx-pcode.jar(/com/threerings/presents/dobj/j.class)]
[loading <spiral>/code/projectx-pcode.jar(/com/google/inject/a/a.class)]
I disassembled this class, removed its signature attribute, assembled it and just inserted in my mapped jar, and it worked, the mod manager
compiled successfully

Enigma doesn't let me apply reverse mapping to mods because the required classes aren't there, are there actually any obstacles that prevent
the inverse mappings? even then, I can just feed mods along with pcode to unmap classes
manual unmapping by adding mapped mod to mapped pcode worked, so at least there's this fallback method
this proves the concept, the only question left is world build to see whether there are other compile errors to be had

Upon further inspection it seems that the labels going out of reach obfuscation is pretty blunt: it always occurs on the last frame and
the frame type is always 63, besides, there is always free space between previous frame and the alleged new one. What this means is
that the fix is as easy as just lowering frame type to a value such that the delta would point at bytecode end.
Edit: it wasn't always exactly 63 but it was always same_frame as last stack map frame that generates offset_delta beyond the bytecode
which is fixed trivially (just remove the frame altogether).

I would get an "Arguments can't fit into locals in class file" exception at commit 368619c4761e3e872401861c99dd707dc1cf72d9 (it's 
64810e85fba2b59145ebf42c40de20735ce6d8de now) but it went away after I did clean + build, although it took multiple clean + build
iterations which was weird

after adding maxStack and maxLocals calculation I get
Exception in thread "main" java.lang.NoSuchMethodError: com.samskivert.swing.RuntimeAdjust$a.a(Lcom/samskivert/swing/RuntimeAdjust$a;)I
        at com.samskivert.swing.RuntimeAdjust$a.compareTo(SourceFile:489)
        at com.samskivert.util.c.a(SourceFile:384)
        at com.samskivert.util.SortableArrayList.b(SourceFile:79)
        at com.samskivert.swing.RuntimeAdjust$a.<init>(SourceFile:510)
        at com.samskivert.swing.RuntimeAdjust$b.<init>(SourceFile:151)
        at com.threerings.projectx.client.ProjectXApp.<clinit>(SourceFile:2247)
I've checked and it really did disappear
WARNING: no tokens found for com/samskivert/swing/RuntimeAdjust$a.a(Lcom/samskivert/swing/RuntimeAdjust$a;)I's declaration in com/samskivert/swing/RuntimeAdjust
if I make a separate jar with just the adjuster the method is there, the method is in the tree for the pcode as well, but it won't show
declaration and it says there are no tokens for it in the console, it just vanishes somewhere in the insides of enigma
the log output for method a is silent for some reason
because it reports 0 attributes
it reports 0 attributes even for the jar with just this class, will the original jar run with exported version? perhaps, this is caused by
some other error
try import export from original and from runtimeadjust only, sees if substituting original with either works
I now output the descriptor and can see that I was wrong, it's the other method that has no implementation and is at 0 attributes, the one
that disappears does have a code attribute
anyway, recaf also uses asm but it can import pcode and it doesn't lose this method, how is that?
with this in mind I don't think it makes to try class permutations anymore, the question is what exactly is fed to the decompiler? how come
this method is present in jar with just those classes alone but not in a bigger jar?

I found it, decompilers obtain source code through org.benf.cfr.reader.apiunreleased.ClassFileSource2 interface which in turn uses
AsmUtil.nodeToBytes which uses ClassWriter to translate ClassNode from asm back to bytecode, here are some logs for full pcode:
[CFR] Providing source, bytesLen=2761, path=com/samskivert/swing/RuntimeAdjust.class
[CFR] Providing source, bytesLen=3211, path=com/samskivert/swing/RuntimeAdjust$a.class
here are some logs for runtimeadjust only:
[CFR] Providing source, bytesLen=2761, path=com/samskivert/swing/RuntimeAdjust.class
[CFR] Providing source, bytesLen=3211, path=com/samskivert/swing/RuntimeAdjust$a.class
Perhaps, it would make sense to permutate classes and try launching pcode...
also, `javap -v` shows the method missing in source code is still present in exported pcode which is very bad, it means I probably broke
something big time
diff for `javap -v` of both classes is empty
jd-gui shows method code for the original jar but not for the exported one
this might be it, no idea what do about it, next step is to note differences in how java loads this class for original vs. exported jar
or to diff output against original content and substitute differing classes back in until something changes

## What was done so far

ignore class version (adjust it according to features used later)

parse stack map table ignoring whatever can't be parsed (mostly excessive 0xff bytes, remove bytes that prevent normal parsing and
adjust stack map table size later)
the frames are visited before next call to readstackmapframe, perhaps I should be scanning parsable frames without returning?

disable check in EnigmaProject for outer class being null in inner class entries in InnerClasses attribute which seems to be a bug
in Enigma since JVMS states that sometimes the outer class must be null

let the offsetDelta overflow in readStackMapFrame, but should it? maybe it should never be 0xffff in the first place.
if there are multiple frames for a single offset, are those duplicates the JVMS mentions? what do I do about those?
what can I do:
 - move frames with offsetDelta 0xffff to the begining, so that they are the first ones to apply (which would make sense for
 the case of com/google/common/eventbus/g where the first frame would be chop)
 - allow offsetDelta to overflow, essentially ignoring it, seems like an easy one but wouldn't it count as a duplicate
 that the JVMS swears to avoid?
 - remove the frame. it might be a bogus frame introduced by the obfuscator
TODO: check https://asm.ow2.io/developer-guide.html for stack map clarifications, perhaps, this needs more intricate fixing
there are local variable mismatches even without the 0xffff delta meaining it won't solve the issue altogether, which also means
I can leave it as is right now, although I might have to merge them in the future if I don't want to keep using my own copy of asm
the least aggressive thing we can do is immediately grow current frame as much as possible ignoring all frames that chop current one,
this might not work if there are chop frames with non-zero delta ahead though
ultimately, the best solution would be to do whatever the JVM does
now that I think about it, not chopping the frame is definitely not safe, we might a new local variable in the wrong place

deducing class version from attributes used in class file header and in code attribute

TODO: make a "world" class that would import everything from pcode so that we can see whether there are no surprise problems to be discovered
can't make whatever public classes there are to pull their dependencies, maybe I'll come back to that later
A better test would be to run the modified pcode, that would mean nothing has been lost in the process. What is more, I need this
functionality anyway because what good is deobfuscation if inversing it (obfuscating the names in mods) would break it in the process?

I am now parsing class signatures to eliminate cyclic references and there are indeed only like 2 classes from com.google.inject
that do this stuff, both are in interfaces, this suggests that not even jvm will accept cyclic inheritance

I now traverse stack map frames, including implicit one, and record the maximum maxStack and maxLocals encountered instead of adding
arbitrary numbers (this is done instead of culling locals and stack that didn't fit in the original buffers)

the labels beyond bytecode are longer an issue, their only source were the same_frame stack map frames that generated offset_delta
breahing the bytecode boundaries

