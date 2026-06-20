[1mdiff --git a/_posts/2024-02-28-elephant.md b/_posts/2024-02-28-elephant.md[m
[1mindex afbde1b..7b9da13 100644[m
[1m--- a/_posts/2024-02-28-elephant.md[m
[1m+++ b/_posts/2024-02-28-elephant.md[m
[36m@@ -244,7 +244,7 @@[m [mThe former comment applies to a global symbol used to execute `longjmp()` in `aw[m
 [m
 ## Great, now what?[m
 [m
[31m-Now, how do we go about figuring out if any of this code is actually present in _F15 II_, and if so, where? Fortunately, I [recently developed]({% post_url 2025-01-30-newtooling2 %}) some tooling for extracting routine signatures from binaries and locating them in other binaries, which I orignally used to see if any work I did for _F-15 II_'s `START.EXE` would carry over to `EGAME.EXE`. This time, I will use it to search for bits of `F14.EXE` in `EGAME.EXE`. I am a bit lucky here. Despite _Fleet Defender_'s relatively late release date of 1994, the game does not appear to use protected mode, or much 32-bit code either (except for a few minor sections in assembly files, still in real mode). It's kind of surprising given that by that was the year _Doom II_ came out, but for better or worse, _Fleet Defender_ seems to run 16bit real mode code. If it had been rewritten to use protected mode, the code would likely be mostly useless to me.[m
[32m+[m[32mNow, how do we go about figuring out if any of this code is actually present in _F15 II_, and if so, where? Fortunately, I [recently developed]({% post_url 2025-01-30-newtooling2 %}) some tooling for extracting routine signatures from binaries and locating them in other binaries, which I orignally used to see if any work I did for _F-15 II_'s `START.EXE` would carry over to `EGAME.EXE`. This time, I will use it to search for bits of `F14.EXE` in `EGAME.EXE`. I am a bit lucky here. Despite _Fleet Defender_'s relatively late release date of 1994, the game does not appear to use protected mode, or much 32-bit code either (except for a few minor sections in assembly files, still in real mode). It's kind of surprising given that was the year _Doom II_ came out, but for better or worse, _Fleet Defender_ seems to run 16bit real mode code. If it had been rewritten to use protected mode, the code would likely be mostly useless to me.[m
 [m
 The first thing I need to do then is build the code. There is a DOS-era makefile included in the source tree, but I ended up making my own to have a bit more control over the build process and integrate well with my tooling for wrapping MS C. Incidentally, _Fleet Defender_ seems to have been compiled by MSC 7.0, but I need to build it with MSC 5.1 to have the code matching _F-15 II_ as closely as possible. For that, I had to do a couple tweaks to the code, mostly with large, statically initalized arrays defined within functions that MSC 5.1 did not like, but it was a simple matter of moving them up to global scope. I also had to exclude some C files which used inline assembly which is not supported in MSC 5.1, but there were only a few and they contained a minuscule amount of code.[m
 [m
[1mdiff --git a/_posts/2025-03-06-back-egame.md b/_posts/2025-03-06-back-egame.md[m
[1mindex d9f24c3..3b16157 100644[m
[1m--- a/_posts/2025-03-06-back-egame.md[m
[1m+++ b/_posts/2025-03-06-back-egame.md[m
[36m@@ -34,7 +34,7 @@[m [mNew comparison location 0000:0010/000010, queue size = 0[m
 Reached end of routine block @ 0000:0146/000146[m
 Completed comparison of routine main, no more reachable blocks[m
 New comparison location 0000:0688/000688, queue size = 13[m
[31m---- Now @0000:0688/000688, routine 0000:0688-0000:06e0[000059]: routine_14 [near], block 000688-00069a[000013], target @0000:015f/00015f[m
[32m+[m[32m--- Now @0000:0688/000688, routine 0000:0688-0000:06e0[00005N9]: routine_14 [near], block 000688-00069a[000013], target @0000:015f/00015f[m
 <r>0000:0688/000688: push bp                          != 0000:015f/00015f: ret</r> [m
 ERROR: Instruction mismatch in routine <r>routine_14</r> at 0000:0688/000688: push bp != 0000:015f/00015f: ret[m
 [...][m
[36m@@ -64,4 +64,241 @@[m [mSo, as expected, `main()` was matched, and the comparison failed on `routine_14`[m
 [m
 Additional good news is that the duplicate search functionality developed in the tooling was not a total waste, even if the results were not earth-shattering. Upon repeating the signatures search from `START.EXE` for `EGAME.EXE` with improved routine boundaries and smaller routines included, it detected 11% of `EGAME.EXE` as duplicate of code that I already reconstructed before, although that does include the libc functions, so it's really just 11-7=4%. Together with the lousy 3% it found as coming from the leaked _Fleet Defender_ codebase, that's 4+3=7% that I don't need to do, or at least not from scratch. It's a rough approximation, but you could say I'm about 7(duplicates from `START.EXE` and _Fleet Defender_)+7(libc)=14% done without really doing much. 😉 I'm pretty sure some routines will turn up as unreachable, same as it was with `START.EXE`, so that could further limit the extent of the reconstruction. But there's no way around it, the bulk of the work is still ahead of me. Still, it's not as daunting as first starting out because I know much more about how the game works, I have the layout of some common structures and overlay call jump table down, so it's "just" a matter of going through all the opcodes and writing the correct C code.[m
 [m
[31m-This is it for now, I'll update when I come across something interesting, or if I hit a significant milestone.[m
\ No newline at end of file[m
[32m+[m[32mThis is it for now, I'll update when I come across something interesting, or if I hit a significant milestone.[m
[32m+[m
[32m+[m
[32m+[m[32m```[m
[32m+[m[32mseg000:0B54		    mov	    si,	[bp+var_6][m
[32m+[m[32mseg000:0B57[m
[32m+[m[32mseg000:0B57 loc_10B57:[m
[32m+[m[32mseg000:0B57		    sub	    si,	3[m
[32m+[m[32mseg000:0B5A		    mov	    di,	[bp+var_8][m
[32m+[m[32mseg000:0B5D		    sub	    di,	3[m
[32m+[m[32mseg000:0B60		    mov	    ax,	6[m
[32m+[m[32mseg000:0B63		    push    ax[m
[32m+[m[32mseg000:0B64		    push    ax[m
[32m+[m[32mseg000:0B65		    push    di[m
[32m+[m[32mseg000:0B66		    push    si[m
[32m+[m[32mseg000:0B67		    mov	    al,	byte_3C5A0[m
[32m+[m[32mseg000:0B6A		    cbw[m
[32m+[m[32mseg000:0B6B		    push    ax[m
[32m+[m[32mseg000:0B6C		    push    di[m
[32m+[m[32mseg000:0B6D		    push    si[m
[32m+[m[32mseg000:0B6E		    mov	    ax,	2[m
[32m+[m[32mseg000:0B71		    push    ax[m
[32m+[m[32mseg000:0B72		    call    far	ptr gfx_jump_2a[m
[32m+[m
[32m+[m[32mgfx_copyRect(2, b - 3, c - 3, byte_3C5A0, b - 3, c - 3, 6, 6);[m
[32m+[m
[32m+[m[32m0000:0b54/000b54: mov si, [bp-0x06]                != 0000:0715/000715: mov ax, [bp-0x06][m
[32m+[m[32mERROR: Instruction mismatch in routine updateFrame at 0000:0b54/000b54: mov si, [bp-0x06] != 0000:0715/000715: mov ax, [bp-0x06][m
[32m+[m[32m--- Context information for up to 20 additional instructions of routine updateFrame after mismatch location:[m
[32m+[m[32m0000:0b57/000b57: sub si, 0x3                      != 0000:0718/000718: sub ax, 0x3[m
[32m+[m[32m0000:0b5a/000b5a: mov di, [bp-0x08]                != 0000:071b/00071b: mov si, ax[m
[32m+[m[32m0000:0b5d/000b5d: sub di, 0x3                      != 0000:071d/00071d: mov ax, [bp-0x08][m
[32m+[m[32m0000:0b60/000b60: mov ax, 0x6                      != 0000:0720/000720: sub ax, 0x3[m
[32m+[m[32m0000:0b63/000b63: push ax                          != 0000:0723/000723: mov di, ax[m
[32m+[m[32m0000:0b64/000b64: push ax                          != 0000:0725/000725: mov ax, 0x6[m
[32m+[m[32m0000:0b65/000b65: push di                          != 0000:0728/000728: push ax[m
[32m+[m[32m0000:0b66/000b66: push si                          != 0000:0729/000729: push ax[m
[32m+[m[32m0000:0b67/000b67: mov al, [0x9cf0]                 != 0000:072a/00072a: push di[m
[32m+[m[32m0000:0b6a/000b6a: cbw                              != 0000:072b/00072b: push si[m
[32m+[m[32m0000:0b6b/000b6b: push ax                          != 0000:072c/00072c: mov al, [0x9ffe][m
[32m+[m[32m0000:0b6c/000b6c: push di                          != 0000:072f/00072f: cbw[m
[32m+[m[32m0000:0b6d/000b6d: push si                          != 0000:0730/000730: push ax[m
[32m+[m[32m0000:0b6e/000b6e: mov ax, 0x2                      != 0000:0731/000731: push di[m
[32m+[m[32m0000:0b71/000b71: push ax                          != 0000:0732/000732: push si[m
[32m+[m[32m0000:0b72/000b72: call far 0x228b0f90              != 0000:0733/000733: mov ax, 0x2[m
[32m+[m[32m0000:0b77/000b77: add sp, 0x10                     != 0000:0736/000736: push ax[m
[32m+[m[32m0000:0b7a/000b7a: sub ax, ax                       != 0000:0737/000737: call far 0x226f0f90[m
[32m+[m[32m0000:0b7c/000b7c: push ax                          != 0000:073c/00073c: add sp, 0x10[m
[32m+[m[32m0000:0b7d/000b7d: mov ax, 0x4                      != 0000:073f/00073f: sub ax, ax[m
[32m+[m
[32m+[m[32mint FAR CDECL gfx_copyRect(int srcPage, int srcX, int srcY, int dstPage, int dstX, int dstY, int width, int height); /* slot 0x2a: copyRect between pages */[m
[32m+[m
[32m+[m
[32m+[m[32mseg000:0CEA		    mov	    ax,	0FFFCh[m
[32m+[m[32mseg000:0CED		    cwd                               ; dx:ax = ffff fffc[m
[32m+[m[32mseg000:0CEE		    add	    ax,	word ptr commData     ; [commData] = 0[m
[32m+[m[32mseg000:0CF2		    adc	    dx,	0                     ; no change[m
[32m+[m[32mseg000:0CF5		    mov	    cx,	0Ch[m
[32m+[m[32mseg000:0CF8		    shl	    dx,	cl                    ; dx = f000[m
[32m+[m[32mseg000:0CFA		    add	    dx,	word ptr commData+2   ; [commData+2] = 1554, dx = 554[m
[32m+[m[32mseg000:0CFE		    mov	    es,	dx[m
[32m+[m[32mseg000:0D00		    mov	    bx,	ax[m
[32m+[m[32mseg000:0D02		    cmp	    word ptr es:[bx], 0CA01h  ; es:bx = 554:fffc[m
[32m+[m[32mseg000:0D07		    jnz	    short loc_10D11[m
[32m+[m[32mseg000:0D09		    cmp	    word ptr es:[bx+2],	3B9Ah ; magic checksum: 0x3b9aca01[m
[32m+[m[32mseg000:0D0F		    jz	    short loc_10D20[m
[32m+[m
[32m+[m[32m0000:08ab/0008ab: mov ax, [0xa104] ; commData[m
[32m+[m[32m0000:08ae/0008ae: mov dx, [0xa106][m
[32m+[m[32m0000:08b2/0008b2: sub ax, 0x4[m
[32m+[m[32m0000:08b5/0008b5: sbb dx, 0x0[m
[32m+[m[32m0000:08b8/0008b8: mov es, dx[m
[32m+[m[32m0000:08ba/0008ba: mov bx, ax[m
[32m+[m[32m0000:08bc/0008bc: cmp word es:[bx], 0x3b9a[m
[32m+[m[32m0000:08c1/0008c1: jnz 0x8cb (0xa down)[m
[32m+[m[32m0000:08c3/0008c3: cmp word es:[bx+0x02], 0xca01[m
[32m+[m[32m0000:08c9/0008c9: jz 0x8da (0x11 down)[m
[32m+[m
[32m+[m[32m        if (*(int far *)((char far *)commData - 4) != (int)0xca01 ||[m
[32m+[m[32m            *(int far *)((char far *)commData - 2) != 0x3b9a) {[m
[32m+[m
[32m+[m[32mif (*((int32 huge *)commData - 1) != 0x3b9aca01) {[m
[32m+[m
[32m+[m
[32m+[m
[32m+[m[32mregister spill:[m
[32m+[m
[32m+[m[32m// reconstructed[m
[32m+[m[32mvoid sub_160D3(int *arg_0) {[m
[32m+[m[32m    while (*arg_0 != -1) {[m
[32m+[m[32m        gfx_jump_21(((uint8 *)word_3419C)[*arg_0++]);[m
[32m+[m[32m        sub_2171A();[m
[32m+[m[32m        arg_0 += 2;[m
[32m+[m[32m        while (*arg_0 != -1) {[m
[32m+[m[32m            var_351 = arg_0[-2];[m
[32m+[m[32m            var_353 = arg_0[-1];[m
[32m+[m[32m            var_352 = *arg_0++;[m
[32m+[m[32m            var_354 = *arg_0++;[m
[32m+[m[32m            sub_2189C();[m
[32m+[m[32m        }[m
[32m+[m[32m        sub_21704();[m
[32m+[m[32m        arg_0++;[m
[32m+[m[32m    }[m
[32m+[m[32m}[m
[32m+[m
[32m+[m
[32m+[m[32m// problematic[m
[32m+[m[32mint sub_11841() {[m
[32m+[m[32m    int p;[m
[32m+[m[32m    int a;[m
[32m+[m
[32m+[m[32m    if (word_336F6 != -1) {[m
[32m+[m[32m        for (p = 0; p < 8; p++) {[m
[32m+[m[32m            ((struct struc_9 *)stru_33402)[p].field_4 += 0x0a;[m
[32m+[m[32m            ((struct struc_9 *)stru_33402)[p].field_2 += ((struct struc_9 *)stru_33402)[p].field_4 >> 9;[m
[32m+[m[32m            *(((char *)&((struct struc_9 *)stru_33402)[p].field_6) + 1) += 6;[m
[32m+[m[32m        }[m
[32m+[m[32m        if (!((char)word_336E8 & 0x0f)) {[m
[32m+[m[32m            a = (word_336E8 >> 4) & 7;[m
[32m+[m[32m            ((struct struc_9 *)stru_33402)[a].field_0 = *(int16 *)((char *)stru_3AA5E + word_336F6 * 16);[m
[32m+[m[32m            ((struct struc_9 *)stru_33402)[a].field_2 = *(int16 *)((char *)stru_3AA5E + word_336F6 * 16 + 2);[m
[32m+[m[32m            ((struct struc_9 *)stru_33402)[a].field_4 = 0x80;[m
[32m+[m[32m            ((struct struc_9 *)stru_33402)[a].field_6 = sub_1D200(0x100) << 8; // pointer reloaded into si[m
[32m+[m[32m            word_33442 = a;[m
[32m+[m[32m        }[m
[32m+[m[32m    }[m
[32m+[m[32m}[m
[32m+[m
[32m+[m
[32m+[m[32mWARNING: Unable to determine location of routine sub_11841 in target executable. Last resort pattern searching found likely location 0000:7f95/007f95, but it may be completely wrong so false negative or positive is possible![m
[32m+[m[32m--- Now @0000:1841/001841, routine 0000:1841-0000:18d4[000094]: sub_11841 [near] [complete], block 001841-0018d4[000094], target @0000:7f95/007f95[m
[32m+[m[32m0000:1841/001841: push bp                          == 0000:7f95/007f95: push bp[m
[32m+[m[32m0000:1842/001842: mov bp, sp                       == 0000:7f96/007f96: mov bp, sp[m
[32m+[m[32m0000:1844/001844: sub sp, 0x4                      =~ 0000:7f98/007f98: sub sp, 0xc[m
[32m+[m[32m0000:1847/001847: push di                          == 0000:7f9b/007f9b: push di[m
[32m+[m[32m0000:1848/001848: push si                          == 0000:7f9c/007f9c: push si[m
[32m+[m[32m0000:1849/001849: cmp word [0xe46], 0xff           ~~ 0000:7f9d/007f9d: cmp word [0xe8a], 0x0 ; var_116 / ?[m
[32m+[m[32m0000:184e/00184e: jz 0x18cf (0x81 down)            ~= 0000:7fa2/007fa2: jz 0x7fad (0xb down)[m
[32m+[m[32m0000:1850/001850: mov word [bp-0x02], 0x0          != 0000:7fa4/007fa4: mov ax, [0xe76][m
[32m+[m
[32m+[m[32mninja@RYZEN:f15se2-re$ grep sub_11841 build/egame.map[m
[32m+[m[32m 0000:327A       _sub_11841[m
[32m+[m
[32m+[m[32mninja@RYZEN:f15se2-re$ mzdiff --verbose --loose bin/egame.exe:0x1841 build/egame.exe:0x327a[m
[32m+[m[32mComparing code between reference (entrypoint 0000:1841/001841) and target (entrypoint 0000:327a/00327a) executables[m
[32m+[m[32mNew comparison location 0000:1841/001841, queue size = 0[m
[32m+[m[32m--- Comparing reference @ 0000:1841/001841 to target @0000:327a/00327a[m
[32m+[m[32mWARNING: Unable to find target entrypoint for routine unknown[m
[32m+[m[32m0000:1841/001841: push bp                          == 0000:327a/00327a: push bp[m
[32m+[m[32m0000:1842/001842: mov bp, sp                       == 0000:327b/00327b: mov bp, sp[m
[32m+[m[32m0000:1844/001844: sub sp, 0x4                      == 0000:327d/00327d: sub sp, 0x4[m
[32m+[m[32m0000:1847/001847: push di                          == 0000:3280/003280: push di[m
[32m+[m[32m0000:1848/001848: push si                          == 0000:3281/003281: push si[m
[32m+[m[32m0000:1849/001849: cmp word [0xe46], 0xff           ~= 0000:3282/003282: cmp word [0xe88], 0xff[m
[32m+[m[32m0000:184e/00184e: jz 0x18cf (0x81 down)            != 0000:3287/003287: jnz 0x328c (0x5 down)[m
[32m+[m[32mERROR: Instruction mismatch in routine unknown at 0000:184e/00184e: jz 0x18cf != 0000:3287/003287: jnz 0x328c[m
[32m+[m[32m--- Context information for up to 10 additional instructions of routine unknown after mismatch location:[m
[32m+[m[32m0000:1850/001850: mov word [bp-0x02], 0x0          != 0000:3289/003289: jmp 0x3314 (0x8b down)[m
[32m+[m[32m0000:1855/001855: jmp short 0x185a (0x5 down)      != 0000:328c/00328c: mov word [bp-0x02], 0x0[m
[32m+[m[32m0000:1857/001857: inc [bp-0x02]                    != 0000:3291/003291: jmp short 0x3296 (0x5 down)[m
[32m+[m[32m0000:185a/00185a: cmp word [bp-0x02], 0x8          != 0000:3293/003293: inc [bp-0x02][m
[32m+[m[32m0000:185e/00185e: jge 0x187f (0x21 down)           != 0000:3296/003296: cmp word [bp-0x02], 0x8[m
[32m+[m[32m0000:1860/001860: mov si, [bp-0x02]                != 0000:329a/00329a: jge 0x32bb (0x21 down)[m
[32m+[m[32m0000:1863/001863: mov cl, 0x3                      != 0000:329c/00329c: mov si, [bp-0x02][m
[32m+[m[32m0000:1865/001865: shl si, cl                       != 0000:329f/00329f: mov cl, 0x3[m
[32m+[m[32m0000:1867/001867: add word [si+0x0b56], 0xa        != 0000:32a1/0032a1: shl si, cl[m
[32m+[m[32m0000:186c/00186c: mov ax, [si+0x0b56]              != 0000:32a3/0032a3: add word [si+0x0b98], 0xa[m
[32m+[m
[32m+[m[32mninja@RYZEN:f15se2-re$ mzdiff --verbose --loose bin/egame.exe:0x1850 build/egame.exe:0x328c --map map/egame.map --tmap build/egame.[m
[32m+[m[32mmap:link[m
[32m+[m[32mLoading target map from build/egame.map, tag: link[m
[32m+[m[32mComparing code between reference (entrypoint 0000:1850/001850) and target (entrypoint 0000:328c/00328c) executables[m
[32m+[m[32mNew comparison location 0000:1850/001850, queue size = 0[m
[32m+[m[32m--- Now @0000:1850/001850, routine 0000:1841-0000:18d4[000094]: sub_11841 [near] [complete], block 001841-0018d4[000094], target @0000:328c/00328c[m
[32m+[m[32m0000:1850/001850: mov word [bp-0x02], 0x0          == 0000:328c/00328c: mov word [bp-0x02], 0x0[m
[32m+[m[32m0000:1855/001855: jmp short 0x185a (0x5 down)      == 0000:3291/003291: jmp short 0x3296 (0x5 down)[m
[32m+[m[32m0000:1857/001857: inc [bp-0x02]                    == 0000:3293/003293: inc [bp-0x02][m
[32m+[m[32m0000:185a/00185a: cmp word [bp-0x02], 0x8          == 0000:3296/003296: cmp word [bp-0x02], 0x8[m
[32m+[m[32m0000:185e/00185e: jge 0x187f (0x21 down)           == 0000:329a/00329a: jge 0x32bb (0x21 down)[m
[32m+[m[32m0000:1860/001860: mov si, [bp-0x02]                == 0000:329c/00329c: mov si, [bp-0x02][m
[32m+[m[32m0000:1863/001863: mov cl, 0x3                      == 0000:329f/00329f: mov cl, 0x3[m
[32m+[m[32m0000:1865/001865: shl si, cl                       == 0000:32a1/0032a1: shl si, cl[m
[32m+[m[32m0000:1867/001867: add word [si+0x0b56], 0xa        ~= 0000:32a3/0032a3: add word [si+0x0b98], 0xa ; var_90 / ?[m
[32m+[m[32m0000:186c/00186c: mov ax, [si+0x0b56]              =~ 0000:32a8/0032a8: mov ax, [si+0x0b98] ; var_90 / ?[m
[32m+[m[32m0000:1870/001870: mov cl, 0x9                      == 0000:32ac/0032ac: mov cl, 0x9[m
[32m+[m[32m0000:1872/001872: sar ax, cl                       == 0000:32ae/0032ae: sar ax, cl[m
[32m+[m[32m0000:1874/001874: add [si+0x0b54], ax              ~= 0000:32b0/0032b0: add [si+0x0b96], ax ; var_89 / ?[m
[32m+[m[32m0000:1878/001878: add byte [si+0x0b59], 0x6        ~= 0000:32b4/0032b4: add byte [si+0x0b9b], 0x6 ; var_92 / ?[m
[32m+[m[32m0000:187d/00187d: jmp short 0x1857 (0x26 up)       == 0000:32b9/0032b9: jmp short 0x3293 (0x26 up)[m
[32m+[m[32m0000:187f/00187f: test byte [0xe38], 0xf           ~= 0000:32bb/0032bb: test byte [0xe7a], 0xf ; var_109 / word_336E8[m
[32m+[m[32m0000:1884/001884: jnz 0x18cf (0x4b down)           ~= 0000:32c0/0032c0: jnz 0x3314 (0x54 down)[m
[32m+[m[32m0000:1886/001886: mov ax, [0xe38]                  =~ 0000:32c2/0032c2: mov ax, [0xe7a] ; var_109 / word_336E8[m
[32m+[m[32m0000:1889/001889: mov cl, 0x4                      == 0000:32c5/0032c5: mov cl, 0x4[m
[32m+[m[32m0000:188b/00188b: sar ax, cl                       == 0000:32c7/0032c7: sar ax, cl[m
[32m+[m[32m0000:188d/00188d: and ax, 0x7                      == 0000:32c9/0032c9: and ax, 0x7[m
[32m+[m[32m0000:1890/001890: mov [bp-0x04], ax                == 0000:32cc/0032cc: mov [bp-0x04], ax[m
[32m+[m[32m0000:1893/001893: mov si, ax                       == 0000:32cf/0032cf: mov si, ax[m
[32m+[m[32m0000:1895/001895: mov cl, 0x3                      == 0000:32d1/0032d1: mov cl, 0x3[m
[32m+[m[32m0000:1897/001897: shl si, cl                       == 0000:32d3/0032d3: shl si, cl[m
[32m+[m[32m0000:1899/001899: mov di, [0xe46]                  =~ 0000:32d5/0032d5: mov di, [0xe88] ; var_116 / word_336F6[m
[32m+[m[32m0000:189d/00189d: mov cl, 0x4                      == 0000:32d9/0032d9: mov cl, 0x4[m
[32m+[m[32m0000:189f/00189f: shl di, cl                       == 0000:32db/0032db: shl di, cl[m
[32m+[m[32m0000:18a1/0018a1: mov ax, [di-0x7e52]              =~ 0000:32dd/0032dd: mov ax, [di-0x7b26] ; var_761 / stru_3AA5E[m
[32m+[m[32m0000:18a5/0018a5: mov [si+0x0b52], ax              ~= 0000:32e1/0032e1: mov [si+0x0b94], ax ; var_88 / stru_33402[m
[32m+[m[32m0000:18a9/0018a9: mov ax, [di-0x7e50]              =~ 0000:32e5/0032e5: mov ax, [di-0x7b24] ; var_762 / ?[m
[32m+[m[32m0000:18ad/0018ad: mov [si+0x0b54], ax              ~= 0000:32e9/0032e9: mov [si+0x0b96], ax ; var_89 / ?[m
[32m+[m[32m0000:18b1/0018b1: mov word [si+0x0b56], 0x80       ~= 0000:32ed/0032ed: mov word [si+0x0b98], 0x80 ; var_90 / ?[m
[32m+[m[32m0000:18b7/0018b7: mov ax, 0x100                    == 0000:32f3/0032f3: mov ax, 0x100[m
[32m+[m[32m0000:18ba/0018ba: push ax                          == 0000:32f6/0032f6: push ax[m
[32m+[m[32m0000:18bb/0018bb: call 0xd200 (0xb945 down)        ~= 0000:32f7/0032f7: call 0x4000 (0xd09 down) ; randlmul / sub_1D200[m
[32m+[m[32m0000:18be/0018be: add sp, 0x2                      == 0000:32fa/0032fa: add sp, 0x2[m
[32m+[m[32m0000:18c1/0018c1: mov ch, al                       == 0000:32fd/0032fd: mov ch, al[m
[32m+[m[32m0000:18c3/0018c3: sub cl, cl                       == 0000:32ff/0032ff: sub cl, cl[m
[32m+[m[32m0000:18c5/0018c5: mov [si+0x0b58], cx              != 0000:3301/003301: mov bx, [bp-0x04] ; var_91 / ?[m
[32m+[m[32mERROR: Instruction mismatch in routine sub_11841 at 0000:18c5/0018c5: mov [si+0x0b58], cx != 0000:3301/003301: mov bx, [bp-0x04][m
[32m+[m[32m--- Context information for up to 10 additional instructions of routine sub_11841 after mismatch location:[m
[32m+[m[32m0000:18c9/0018c9: mov ax, [bp-0x04]                != 0000:3304/003304: mov ax, cx[m
[32m+[m[32m0000:18cc/0018cc: mov [0xb92], ax                  != 0000:3306/003306: mov cl, 0x3[m
[32m+[m[32m0000:18cf/0018cf: pop si                           != 0000:3308/003308: shl bx, cl[m
[32m+[m[32m0000:18d0/0018d0: pop di                           != 0000:330a/00330a: mov [bx+0x0b9a], ax[m
[32m+[m[32m0000:18d1/0018d1: mov sp, bp                       != 0000:330e/00330e: mov ax, [bp-0x04][m
[32m+[m[32m0000:18d3/0018d3: pop bp                           != 0000:3311/003311: mov [0xbd4], ax[m
[32m+[m[32m0000:18d4/0018d4: ret                              != 0000:3314/003314: pop si[m
[32m+[m
[32m+[m[32megame1.c(1920) : warning C4073: scoping too deep, deepest scoping merged when debugging[m
[32m+[m
[32m+[m[32mDeclarations appeared at a static nesting level greater than[m
[32m+[m[32m1 3 . As a result, all declarations will seem to appear at the[m
[32m+[m[32msame level. ( 1 )[m
[32m+[m
[32m+[m[32mmoved half of the routines (without changing the order) from egame1.c to egame0.c. The scoping warning disappeared and verification passed.[m
[32m+[m[32mfile too big to fit in mem?[m
[32m+[m
[32m+[m[32mnot sure why not hit in other files, start is mostly in order[m[41m [m
[32m+[m
[32m+[m[32m```[m
[41m+[m
[41m+[m
