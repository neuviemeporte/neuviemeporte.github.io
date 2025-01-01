---
layout: post
title: Improvements in tooling
category: other
---
<small>(_This post is part of a [series]({% link category/f15-se2.html %}) on the subject of my hobby project, which is recreating the C source code for the 1989 game [F-15 Strike Eagle II]({% post_url 2022-06-05-origins %}) by reverse engineering the original binaries._)</small>

This is a small update to let anyone interested know that I've not abandoned the project, but it's been on a short hiatus. I'm getting back into it, albeit slowy, so I thought I would write up what I have been up to in the meantime.

Back around August of 2024, I "finished" the reconstruction of the C code for the first executable of F15 (START.EXE). I left the assembly routines mostly as they were, except for replacing all the hardcoded offsets with references to specific symbols, to make the executable independent of the data layout, so that it would link and run with customizations (particularly instrumentation for debugging). If successful, this would be a great milestone.

Unfortunately, the reconstructed binary does not work inside the game. It freezes with a black screen when starting up, before even showing the first splashscreen. I did some initial debugging, and the problem seems to be around decoding of the first splash screen image, but the results were inconclusive and I was getting a little bit burned out, so I decided to shift gears and spend some time on improving my [tooling](https://github.com/neuviemeporte/mzretools). In this post, I'm going to focus on the improvements I implemented recently.

The official excuse was that the `mzdiff` tool which I am using for comparing my reconstruction executable ("target") to the original ("reference") does not go into some assembly routines, specifically those which are not seen being called while walking the code. This is the case with some routines that are being called indirectly, like the timer interrupt handler - there is no way to figure out that in the walker. If it does not go into these routines, it does not compare them, and any discrepancies in those low-level routines would make the reconstruction fail.

There is no problem from the reference executable's side, because the map file generated by the other tool, `mzmap` has been also manually tweaked by me to spell out all the missing routines, and where they are located, so `mzdiff` can go into it. But the tool doesn't know what the corresponding address is in the target executable if it didn't see a call it could derive the relationship from. So I implemented some search capabilities.

Actually, I'm lying. I started implementing the capability, then got bogged down with the implementation details, left it for a month, forgot what I was supposed to do next, found it hard to get back into, then spent a couple months in a loop of shame and guilt. But it's done now, barely 4 months later.

# Missed routines scrape-up, target opcode search 

After the main comparison loop runs out of locations to compare, I am scanning the map of the reference executable for "missed" routines (i.e. ones that have not been compared) and insert them into the queue again for the main loop to visit. When it notices it does not have an address in the target, it will initiate the search, looking for corresponding instruction opcodes from the reference in the executable. It starts with a single instruction, and keeps adding more until there's just a single, unambigous candidate. Because the layouts of the executables differ, any offsets present in the instructions need to be erased and replaced with "wildcard bytes", otherwise they would not have been found in the target. 

Obviously, if a candidate location for comparison cannot be found, it follows that the routine is not present in the target and the comparison fails.

# Going into the weeds, rollback capability

The other big improvement came from a [bug report](https://github.com/neuviemeporte/mzretools/issues/3) I got on GitHub. Apparently, the `mzmap` tool fails for Duke Nukem 1 and Bio Menace. The symptom was an assertion failure in the instruction decoder. That in itself isn't a big surprise, the tool only supports 8086 instructions in segmented real mode, and that isn't probably going to change soon (perhaps when I start digging into protected-mode Microprose games). But upon closer inspection, it turned out it was going into an apparent data block in the middle of a routine, consisting of a bunch of zeros, followed by an odd `0xff`, where the assert happened.

I can't really avoid this in a tool which is just a static code walker. The instruction preceeding the data block is a function call, which probably doesn't return in the real world, so the CPU never goes into the data (or maybe the "data" is rewritten with legitimate code at runtime), but my tool has no way of knowing that. So what I did is change the assertion into an exception that is caught it the comparison loop. If it finds an invalid instruction, it will "rollback", or mark the entire block from the location the instruction scanning started at as "bad", then continue with the next location as if nothing happened. I'm happy to say this works pretty well and is going to vastly increase the range of games the tool can work with.

To make the rollback a little less rough on the outcome, I also increased the scan granularity, i.e. made the scan blocks smaller, so that in case of a rollback, it will not mark an entire routine as bad, which could be perfectly fine. Until now, I would scan an entire routine, until I encountered an unconditional jump or a return. Now, every branch, including conditional jumps and calls incurs a scan break, with the destination past the branch added to the search queue separately, as a separate block of the routine.

# Boring bugfixes

Beside those new features, I also implemented a bunch of fixes for reported issues. All of this goodness is included in version [0.9.2](https://github.com/neuviemeporte/mzretools/releases/tag/v0.9.2), and already merged into the master branch.

# Did it help?

Why, of course not. The feature worked fine, but there aren't any meaningful differences in the unreachable routines for F15's `START.EXE`. So, it's back to debugging, but at least I've managed to dig myself out of a hole and do a bunch of useful improvements to the tooling. 

The next post is going to focus on the difficulties I've encountered while trying to make the reconstruction runnable. For now, Happy New Year!

