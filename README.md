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

I've realized that by just making offsetDelta overflow I may have glossed over some bigger issue and should look into it once more
The same goes for labels, there might be other underlying errors
the class is com/google/common/eventbus/g, stack map table starts at 5561, ends at 5638
stack map table declares 5 entries and there are 5 of them but delta offset is 0xffff

## What was done so far

ignore class version (adjust it according to features used later)

ignore variables when there are more of them than code declares (adjust stack and locals sizes as a better solution, adjust values in
code after parsing all of it later)

parse stack map table ignoring whatever can't be parsed (mostly excessive 0xff bytes, remove bytes that prevent normal parsing and
adjust stack map table size later)
the frames are visited before next call to readstackmapframe, perhaps I should be scanning parsable frames without returning?

right now I just add arbitrary number of labels, what to do about those? do I add nops? do I adjust the label to not breach
code boudaries? or are there underlying error and those offsets shouldn't exist in the first place?

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

