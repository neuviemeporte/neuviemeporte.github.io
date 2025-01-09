---
layout: post
title: The first reconstructed executable is playable!
date: 2025-01-09
category: f15-se2
---
<small>(_This post is part of a [series]({% link category/f15-se2.html %}) on the subject of my hobby project, which is recreating the C source code for the 1989 game [F-15 Strike Eagle II]({% post_url 2022-06-05-origins %}) by reverse engineering the original binaries._)</small>

This is just a short update to share a significant milestone: the first reconstructed executable (`START.EXE`) is now playable in the original game.

I "finished" the reconstruction a few months ago, meaning all of the code that was generated from C source has been transcribed back into identical C. I left the assembly routines as is (meaning as generated from the IDA liisting), except for some variables having meaningful names, and some comments, both carried over from research done in IDA. Also, the contents of the data segment have been (and still are) generated from assembly. I am not sure how the reconstruction will behave after these are moved back to C, but probably there will be some fallout in the form of bugs to fix. I have strived to replace all hard-baked offsets with references to symbols, but still something might have slipped through the cracks.

In any case, I was pretty surprised that the reconstruction did not run given that the code was "identical", as attested by my `mzdiff` tool. But the thing is, the tool cannot tell for instructions like `mov ax, 0x1234` if the immediate value is some computational constant, or an offset of a variable, so it does not consider immediate value differences as straight-up mismatches, period. This has the potential to backfire badly, and after I had fixed the big problem with the incorrect value being set for the data segment [in the previous post]({% post_url 2025-01-01-unstart2 %}), most problems turned out to have been caused by typos where I put an incorrect immediate value, and `mzdiff` ignored the difference. These were usually small numbers, so I actually put in a silly heuristic into the latest `mzdiff` to highlight instructions differing on immediate values in bright red as a warning if the value of the immediate is less than `0xff`. It actually came pretty handy and I was able to find a bunch more that needed resolving.

In short, I managed to solve a bunch of problems, some were caused by bugs in `mzdiff` which didn't catch some edge cases of differing instructions (these were also fixed in the tooling repo), but most were immediate value mismatches, or remaining numerical values of data segment variables which were supposed to be actually pointers to other variables.

Some of the issues I resolved:

* crashing upon entering the pilot select screen - caused by a wrong `do..while` loop
* memory corruption from the routine to clear the screen overwriting the game code instead of video memory
* keyboard input other than enter not working on the pilot select screen
* wrong location of blinking cursor on pilot select screen
* mission generation routine freezing, stuck in an infinite loop - caused by an invalid read size from a terrain (`.3dt`) file
* crashing after displaying the generated mission, just before termination and entering the flight engine, again caused by the clear screen routine

| ![a glitch on the roster screen](/images/start_glitch.webp){: .center-image } |
| :--: |
| One of the glitches I ran into on the pilot select screen |
{: .imgcaption }

After all that, the reconstructed executable let me pick a pilot and scenario, the mission was generated and displayed, the executable terminated cleanly and the loader executed the mission in the flight engine. Which is pretty great.

However, I can still see some problems when in flight:

* the map MFD in the cockpit looks somewhat broken, has strange colors
* some HUD symbology has incorrect colors also
* the missile count is 1/4/0, which is pretty strange
* exiting the flight engine with Alt-Q displays a libc error message about a null pointer assignment

All of these can be fixed later, but in addition, there is still work to be done on the reconstruction front:

* all of the routines which were originally written in assembly need porting over to C
* the data segment is still generated from assembly and needs porting to C
* the code still contains placeholder routine and variable names for places where the intent of the code is not understood, so it needs more research and experimentation. 

The research part should be much easier now, since the code can be instrumented, and I already have a bunch of trace logs implemented and working both from C and assembly -- use the `make debug` target to build a version with traces enabled, these are written to `f15.log` in the game directory. Also, there's probably a bunch of research that can be carried over from [debugcom's findings](https://github.com/debugcom/Hacking-F117A) on the mission generator in F19/F117, and the [source code leak for F14](https://github.com/alekasm/f14) could provide insights also.

I will be going back to `START.EXE` at some point, but for now I am eager to jump into the next executable, `EGAME.EXE` which is really the meat of the game. However, since it's bound to contain a bunch of duplicate routines with `START.EXE`, I'm going to be switching gears for a while and going back to the tooling, where I plan to implement a new tool for identifying similar routines in different executables, in the hope it will save me some time, especially when I get to the final `END.EXE` which I expect to mostly consist of routines shared with `START.EXE`, since all it does is show some backgrounds, sprites and text.

As always, I will share updates of new developments once something significant happens.