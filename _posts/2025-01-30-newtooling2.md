---
layout: post
title: New tools prevent repeat work, provide better game data insight
date: 2025-01-29
category: f15-se2
---
<small>(_This post is part of a [series]({% link category/f15-se2.html %}) on the subject of my hobby project, which is recreating the C source code for the 1989 game [F-15 Strike Eagle II]({% post_url 2022-06-05-origins %}) by reverse engineering the original binaries._)</small>

I guess you could say I am procrastinating with moving onto the next executable to reconstruct after my recent success with making `START.EXE` runnable, but I had a couple ideas for the tooling which I wanted to check out first. So here's a brief summary of what's available in [mzretools 0.9.7](https://github.com/neuviemeporte/mzretools).

I already [fixed]({% post_url 2024-12-31-newtooling %}) a bunch of bugs that would likely limit my tools' robustness when working on `EGAME.EXE`, and together with these new features, I think I'm in a good place to take on the new work. Also, changing gears once in a while to work on algorithmic stuff in a modern codebase helps me keep from burning out on the ancient assembly opcodes.

# mzdup

With the way the game is structured with the 3 main executables for the main stages of the game, I'm pretty sure there must be at least *some* code duplication between them. They are avoiding most of it by putting the common graphics/sound/input routines into [overlays]({% post_url 2023-07-12-overlays %}) and dynamically loading in the code at runtime, but these are mostly low-level operations for things like drawing a sprite or a string at a particular screen location. Meanwhile, the code for [loading the sprite data](https://github.com/neuviemeporte/f15se2-re/blob/main/src/start4.asm#L1534) and [setting up the overlays](https://github.com/neuviemeporte/f15se2-re/blob/main/src/start4.asm#L938) themselves is present out in the open in `START.EXE`, and I'm pretty sure `EGAME.EXE` will need to do pretty much the same thing. The next executable is going to be challenging due to its larger size and the kind of thing it does (3D rendering and projection math), so I'm going to milk the work that I already did for the first one as much as I can.

The task then is to find duplicate routines from `START` in `EGAME`. Obviously, I cannot just search for the binary data because the offsets encoded in the 8086 assembly instructions are going to be different, and I won't find anything longer that a couple instructions. Also, there is no guarantee that the routines even contain the exact same instructions - the code might have been tweaked between linking one executable vs the other. They might even have used a different assembler which used a different encoding for the instructions, who knows?

I am aware that this is a solved problem because of the existence of [FLIRT](https://docs.hex-rays.com/user-guide/signatures/flirt) in IDA, but for one, generating FLIRT signatures from binaries requires the paid version of IDA which I don't have, and it would require me to go into a Win XP VM which I use to run IDA. I wanted the experience to be more streamlined. Also, it seemed like an interesting challenge which I figured I could pull off, which is as good excuse as any in my book. 😉

The first problem is similar to what I encountered when initially implementing `mzdiff`; I needed to compare instructions between two divergent executables that I wanted to make identical, so I have some facilities implemented to strip out the offsets from parsed instructions. The instructions are also represented in an abstract way in my code, each belonging to a "class" that is more or less equivalent to an assembly mnemonic (`mov`/`cmp`/`call`). So it wasn't difficult to format the instructions of a routine into a string of abstract "signatures" which are just the optional segment override prefix, the class, and the operand types (mem/reg/immediate) [fused together](https://github.com/neuviemeporte/mzretools/commit/cf92f11137f384afdd998f65460d850fa57b0f21#diff-679ea22dfd0ffd35b16186f70f94d92c84f8db9fc28ecca2bb51573071944fceR658) to form a 32bit "character" of the string I will be searching for.

The second problem is kind of brainy. Basically, I need to calculate the [edit distance](https://en.wikipedia.org/wiki/Edit_distance) (from now on, "ED") between the two strings formed by the signatures generated from the instructions of two routines to tell me how many instructions need to be modified to make the routines identical. However, I was never good at implementing fancy algorithms from descriptions in research papers, and dynamic programming is always giving me the willies. So I ended up ["borrowing"](https://github.com/roy-ht/editdistance) the implementation from somebody else. Thanks!

Now it's just a matter of brute forcing the solution, trying to match every routine from my "known" executable against every potential entrypoint location in the "unknown" one. I have some simple heuristics to avoid calculating the ED between routines which differ too much by the instruction count as to immediately tell that the ED will not fill below the maximum difference threshold. Also, the ED routine will interrupt the calculation as soon as it determines that the threshold will not be satisfied. That's about as much as I can bother with in terms of optimization. I implemented a new tool called `mzdup` as a thin frontend for calling the appropriate analysis routine, so let's give it a spin:

<pre>
🔵 walk and discover routines and data in egame.exe first, I know main() is at 0x10 from looking in IDA
ninja@RYZEN:f15se2-re$ mzmap ../ida/egame.exe:0x10 map/egame.map # 
Loading executable ../ida/egame.exe at segment 0x1000
Analyzing code within extents: 1000:0000-3000:8f6f/028f70
Done analyzing code, examined 6013 locations
DEBUG: Dumping visited map of size 0x28f70 starting at 0x10000 to routines.visited
Building routine map from search queue contents: 393 routines over 5 segments
🔴 need to take a look at this...
ERROR: Unable to find a segment for routine map offset 0x32740, ignoring remainder 
Saving routine map (routines = 393) to map/egame.map, reversing relocation by 0x1000
Please review the output file (map/egame.map), assign names to routines/segments
You may need to resolve inaccuracies with routine block ranges manually; this tool is not perfect
🔵 search for duplicates of routines from start.exe in egam.exe
ninja@RYZEN:f15se2-re$ mzdup ../ida/start.exe map/start.map ../ida/egame.exe map/egame.map
🔴 and again
ERROR: Unable to find a segment for routine map offset 0x32740, ignoring remainder
Searching for duplicates of 255 routines among 393 candidates, minimum instructions: 15, maximum distance: 1
Found duplicates for 39 (unique 39) routines out of 255 routines, ignored 139
Saving routine map (routines = 393) to map/egame.map.dup, reversing relocation by 0x1000
🔵 initial look at results, the tool adds the 'duplicate' annotation to the routine along with an informative comment before it
ninja@RYZEN:f15se2-re$ cat map/egame.map.dup | grep duplicate
# Routine routine_264 is a potential duplicate of routine <b>sub_154A1</b>, block 1000:1d6e-1000:1e0d/0000a0 differs by 0 instructions
routine_264: Code1 NEAR 1d6e-1e0d R1d6e-1e0d duplicate
# Routine routine_3 is a potential duplicate of routine <b>installCBreakHandler</b>, block 1000:3bec-1000:3c0e/000023 differs by 0 instructions
routine_3: Code1 NEAR 3bec-3c0e R3bec-3c0e duplicate
# Routine routine_34 is a potential duplicate of routine <b>setTimerIrqHandler</b>, block 1000:3c78-1000:3cb5/00003e differs by 0 instructions
routine_34: Code1 NEAR 3c78-3cb5 R3c78-3cb5 duplicate
# Routine routine_63 is a potential duplicate of routine <b>sub_119D4</b>, block 1000:3df2-1000:3e59/000068 differs by 0 instructions
routine_63: Code1 NEAR 3df2-3e86 R3df2-3e59 U3e5a-3e5a R3e5b-3e86 duplicate
# Routine routine_94 is a potential duplicate of routine <b>sub_11A69</b>, block 1000:3e87-1000:3eb0/00002a differs by 0 instructions
routine_94: Code1 NEAR 3e87-3edb R3e87-3eb0 U3eb1-3eb1 R3eb2-3edb duplicate
# Routine routine_85 is a potential duplicate of routine <b>openFile</b>, block 1000:ddc4-1000:de1a/000057 differs by 0 instructions
routine_85: Code1 NEAR ddc4-de1a Rddc4-de1a Rdf80-dfbb duplicate
# Routine routine_93 is a potential duplicate of routine <b>fileClose</b>, block 1000:de72-1000:de92/000021 differs by 0 instructions
routine_93: Code1 NEAR de72-de92 Rde72-de92 duplicate
# Routine routine_61 is a potential duplicate of routine <b>showPicFile</b>, block 1000:e0aa-1000:e11b/000072 differs by 0 instructions
routine_61: Code1 NEAR e0aa-e11b Re0aa-e11b duplicate
# Routine routine_90 is a potential duplicate of routine <b>decodePicRow</b>, block 1000:e262-1000:e28b/00002a differs by 0 instructions
routine_90: Code1 NEAR e262-e28b Re262-e28b duplicate
# Routine routine_111 is a potential duplicate of routine <b>picReadDataAndMakeDict</b>, block 1000:e28c-1000:e2d2/000047 differs by 0 instructions
routine_111: Code1 NEAR e28c-e2d2 Re28c-e2d2 duplicate
# Routine routine_280 is a potential duplicate of routine <b>picMakeDict</b>, block 1000:e2d3-1000:e308/000036 differs by 0 instructions
routine_280: Code1 NEAR e2d3-e308 Re2d3-e308 duplicate
# Routine routine_192 is a potential duplicate of routine <b>dictionaryLookup</b>, block 1000:e382-1000:e430/0000af differs by 0 instructions
[...]
</pre>

The default maximum ED of one is pretty strict, but I found that when using a higher threshold, like 5, especially with a lower minimum routine length threshold (10), I was getting a bunch of false positives from tiny functions. Fiddling with these values might yield more results, but this is just a demonstration of the concept.

Out of the 39 duplicates found, most are libc functions. But it did find the Ctrl-Break handler, the timer interrupt handler, a bunch of the `.PIC` graphical format-related decoding functions as expected. Also, some routines whose purpose I don't even know yet from `START` have been identified (`sub_...`) in `EGAME`. I will merge the `egame.map.dup` file with the `egame.map` file (or replace the latter outright after confirming everything else looks fine) and mark the relevant routines in my IDA project. It's not a whole lot, but it's something.

The error visible in the mapping stage happens because the code walker was unable to discover the data segment, and after it's done walking all the code paths and starts calculating which regions of the executable's load module belong to which routines, it reaches the boundaries of the current code segment (remember, segments are max 64kB under DOS), and doesn't have a segment where it can put that location, so it ignores the rest of the address space. It does not influence the routine discovery much, because we're in the data segment already and there's no more code past that, but it is something that will need addressing because it means no variables from the data segment will be discovered. For now, the tooling has very limited capabilities of discovering segments, basically it can only recognize a data or stack segment when seeing a `mov` to the `DS` or `SS` registers from either an immediate, or another register with a known value. It worked fine for `START` but in this case, establishing the data segment happened in CRT0 code with `mov di, 0x1234 - mov ss, di - push ss - pop ds`, and I don't trace pushes or pops. At some point, I'm going to have to implement actual 8086 instruction execution, but that's a lot of work that I don't want to get into right now. Or I could let the user specify the segments manually, but where would be the fun in that? 😉

# mzptr

While fixing the [multitude of bugs]({% post_url 2025-01-09-start-runs %}) that prevented `START` from working, some of them predictably turned out to be variables which I thought were straight numeric values, that actually ended up being pointers to different variables. Since the layout of the reconstruction differs from the original, the hard-baked pointers don't match after rebuilding, and stuff breaks. I found and resolved a bunch of them, but that gave me an idea of trying to do it semi-automatically. Essentially, if I knew where the variables were, I could just brute force search the raw contents of the data segment for numbers which match the offsets of known variables. Sure, I'm bound to get some false positives, but maybe also catch some pointers that flew under the radar?

The biggest challenge here was actually "knew where the variables were". I am identifying memory operands while comparing with `mzdiff`, but `mzmap` did not take note of data while walking the executable, so it was a fair bit of development effort as well as refactoring (`RoutineMap` became `CodeMap` as it doesn't only track routines anymore) to get it done. Now, the map file that `mzmap` spits out will also contain found memory operand offsets as potential variable locations. Next, it was a matter of implementing the search. I'm scanning the data segment(s) byte by byte, extracting a 16bit value at every location by swapping the little-endian bytes, and comparing it with all the offsets of all the known variables - nothing subtle. In the future, the search could be extended to the code segment for any lingering pointers that could have been put there with assembly.

Meanwhile, the new utility `mzptr` serves as a frontend for this capability. The useful feature it has is that it will sort the found references by the found count, with the idea being that variables with fewer matches are more likely to be genuine pointers. That's because a variable located at an offset which is a small or non-distinct value like `0x0800` is very likely to spawn multiple false positives at many locations, whereas a value like `0x7fc3` if more likely to be represented once, or not at all. Additionally, within the same match count, variables are sorted by the offset at which they were found, which lets me spot sequential arrays of pointers. So again, let's try it out:

```
ninja@RYZEN:f15se2-re$ mzptr ../ida/start.exe map/start.map
Search complete, found 528 potential references, unique: 132
Printing reference counts per variable, counts higher than 1 or 2 are probably false positives due to a low/non-characteristic offset
word_16BE2/16b5:0092/016be2: 1 reference @ Data1:0xa8
page1Num/16b5:0530/017080: 1 reference @ Data1:0x546
page2Num/16b5:0548/017098: 1 reference @ Data1:0x55e
unk_170B0/16b5:0560/0170b0: 1 reference @ Data1:0x576
🔵 an array of string pointers here
aLibya/16b5:00c2/016c12: 1 reference @ Data1:0x578
aVietnam/16b5:00d5/016c25: 1 reference @ Data1:0x57c
aMiddleEast/16b5:00dd/016c2d: 1 reference @ Data1:0x57e
aOtherAreas/16b5:00e9/016c39: 1 reference @ Data1:0x580
🔵 same here
aAcrossTheLineO/16b5:00f5/016c45: 1 reference @ Data1:0x582
aKeepingTheSeaL/16b5:0110/016c60: 1 reference @ Data1:0x584
aAmericaSLonges/16b5:012b/016c7b: 1 reference @ Data1:0x586
aEaglesVsMigs/16b5:0145/016c95: 1 reference @ Data1:0x588
aInsertYourScen/16b5:0154/016ca4: 1 reference @ Data1:0x58a
🔵 and here
aRookie/16b5:016e/016cbe: 1 reference @ Data1:0x58c
aPilot/16b5:0175/016cc5: 1 reference @ Data1:0x58e
aVeteran/16b5:017b/016ccb: 1 reference @ Data1:0x590
aAce/16b5:0183/016cd3: 1 reference @ Data1:0x592
aDemo/16b5:0187/016cd7: 1 reference @ Data1:0x594
aGetOffToAGoodS/16b5:018c/016cdc: 1 reference @ Data1:0x596
aForTheCasualPl/16b5:01a4/016cf4: 1 reference @ Data1:0x598
aForMoreSerious/16b5:01ba/016d0a: 1 reference @ Data1:0x59a
aTheUltimateCha/16b5:01d3/016d23: 1 reference @ Data1:0x59c
aLetSSeeWhatThi/16b5:01ea/016d3a: 1 reference @ Data1:0x59e
aNc/16b5:020b/016d5b: 1 reference @ Data1:0x5a0
aCe/16b5:020e/016d5e: 1 reference @ Data1:0x5a2
aJp/16b5:0211/016d61: 1 reference @ Data1:0x5a4
aNa/16b5:0214/016d64: 1 reference @ Data1:0x5a6
aNorthCape/16b5:0217/016d67: 1 reference @ Data1:0x5a8
aCentralEurope/16b5:0222/016d72: 1 reference @ Data1:0x5aa
aDesertStorm/16b5:0231/016d81: 1 reference @ Data1:0x5ac
[...]
🔴 these are all bogus; small, non-distinctive offset values
aPersianGulf/16b5:00c8/016c18: 8 references
crt0_end/16b5:0041/016b91: 8 references
fileHandle/16b5:4600/01b150: 15 references
aMsRunTimeLibra/16b5:0008/016b58: 20 references
unk_16B56/16b5:0006/016b56: 34 references
aOnc_2/16b5:0700/017250: 39 references
unk_16B57/16b5:0007/016b57: 45 references
byte_16B54/16b5:0004/016b54: 87 references
crt0_16B52/16b5:0002/016b52: 118 references
```

It found quite a lot of potential locations, but only 132 unique references, with the bulk of the overall 528 count being false positives for variables with non-distinct offsets, like `crt0_16B52` located at offset `ds:0002` (and there are a lot of 2's in the data segment). But the single-instance references at the top of the listing are actually genuine, so I checked every single location in the data segment to make sure they weren't hardcoded to the numeric value of the offset, which is a bit tedious, but still infinitely better than trying to figure it out when debugging. I didn't actually find any missed references, just one case of the opposite, where a numeric value was replaced with an offset to a variable that should not have been. 

Another neat thing to see is how the references form arrays of pointers at some location, like the names of the scenarios (Libya, Vietnam, ...) starting at `Data1:0578` or the difficulty levels (Rookie, Pilot, ...) at `Data1:058c`.

# Conclusion

Admittedly, the results are not groundbreaking, but this was something that I just needed to check out of curiosity. I was unable to fix the remaining bugs in `START` this way either, so it means it's up for a new round of debugging in the near future. Anyway, I think this work will pay dividens in the future because:

1. I expect `END.EXE` (the debriefing stage which mostly just shows static images) to be more similar to `START` than `EGAME` is, so I expect to find a fair amount of duplication there,
2. I will need to find pointers in both `EGAME` and `END`, so `mzptr` will see its share of work (once I can get the data segment discovery to work),
3. The tools project is not only about F-15 SE2 and this could come useful to somebody working on a different project,
4. The other Microprose flight games on this engine (F-19/F-117) are likely going to contain some duplication, so being able to find matching routines is going to go a long way towards supporting them some day.