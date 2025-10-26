---
layout: post
title: 
date: 2025-04-28
category: f15-se2
---

todo:
1. create minimal executable with libc, compare dseg with binary image of libc data extracted from start.exe (will need support for comparing with bins in mzdiff)
2. define 3 data segments in start.map (data1, libc data, data2) and ignore libc data in comparison, compare 2 remaining areas separately
3. implement linkmap as target map, show symbols from target exe around mismatch as well

the fact that the exe mostly runs even with a completely different layout is testament to the effectiveness of the reconstruction

had to add slibce to libs in linker args, otherwise it was linked after the final piece of game data (revisit this to make sure), difference between load libs and regular libs

examples of simple data differences, fixed name entry

var attributes, problems with libc data

order of libc objects linkage does not appear to depend on the order of usage in the file (looking at LINK output and also mapfile)
header inclusion does not constitute usage
disconnected functions still contribute to usage

my start is missing a bunch of libc functions, probably because it doesn't have some routines that were in the original but not called