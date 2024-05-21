---
layout: post
title: The compiler has dirty tricks
date: 2024-05-05
category: f15-se2
---

<small>(_This post is part of a [series]({% link category/f15-se2.html %}) on the subject of my hobby project, which is recreating the C source code for the 1989 game [F-15 Strike Eagle II]({% post_url 2022-06-05-origins %}) by reverse engineering the original binaries._)</small>

A long time ago, I used to work for a large company. As a way of making us better developers, management decided we would get training on solving algorithmic problems - those made up ones like on Leetcode. But it wasn't enough to train us. In true corporate fashion, it turned into a big thing where we would get a test every quarter and if you wanted a promotion, you would need to solve at least some of those tests successfully, and the difficulty increased as you (hopefully) rose through the ranks. During the test, you were dropped into a limited environment with only an IDE, no Internet, extra monitors would switch off, Windows task switching didn't work, and it was all on a time limit of course. Oh, and on higher levels you were also rated on how well your program performed in comparison to other people.

Not having a computer science background, I was never good at this stuff, so this caused me a great amount of stress. I guess this is one of grown up life's disappointments - you figure you leave school and there will be no more tests - nope, there will be tests from here to eternity. Looking back on the whole experience, I can appreciate it - I learned a lot of new things, even if they hardly ever came useful on the actual job (I think I needed to write a sort routine only once in my professional life). But it comes up often on job interviews, so I guess I should thank my old company for helping me find a better job? Also, I still kinda suck at it, and I won't be inverting red-black trees anytime soon, but at least I can write a DFS, which came useful a bunch of times while making tooling for this project.

In any case, that test had a bunch of rules that I considered incredibly stupid back then. You could pick a language; C++, Java or Python if memory serves. But for C++ you could not use STL, some standard library routines were likewise prohibited (only they didn't tell you which). You were expected to allocate your memory statically and solve everything with arrays. Which probably made sense if you were to be graded on performance (dynamic allocations will always have more overhead). Also, if a part of the task was e.g. to implement a queue, it would hardly make sense to let people use `queue<T>` and call it a day, would it?

But the thing was, the whole thing, like so much at that company, was held together with ducttape and bubble gum. Your source code was parsed before being passed to the compiler, but the parser was very primitive. If it detected a verboten keyword, routine or anything really, it would silently fail the compilation, without telling you why, and on which line the problem was. If you had written a big chunk of code, the only way to figure it out was to keep deleting lines and trying if it would compile. I cannot tell you how much time I wasted trying to spot a variable called `connectedNodes`, because the parser thought I was trying to `connect()` out of my sandbox. Yes, it didn't even bother to check word boundaries, it just scanned the whole thing against a list of patterns, apparently.

Ever the defiant one, I decided to play dirty:

{% highlight cpp %}
#define foo <vec
#define bar tor>
#include foo ## bar
{% endhighlight %}

Unsurprisingly, this worked and now I could use the forbidden fruit of STL containers in the test. Yay. If I were more black-hat inclined, I could probably find interesting ways to abuse the system and bring down the Matrix, but I could never be bothered. I just showed it to a bunch of colleagues and we shared a laugh. One commented giddily: "sneaky, sneaky!".

Well, this painfully protracted intro finally brings us to the matter at hand, which is reversing F-15. When I stumbled onto the soultion of this puzzle, that exact line came through my head. But let's start at the beginning. I'm currently tweaking a long routine, already translated from disassembly to C, into identical opcodes when compared with the original. After a string of successes, `mzdiff` stops again on this bit of code:

{% highlight nasm %}
		test	word_1C830, 200h
		jz	short loc_146B9
		sub	ax, ax
		jmp	short loc_146BC
loc_146B9:
		mov	ax, 708h
loc_146BC:
		cwd    ; A) DX:AX = (long)((word_1C830 & 0x200) ? 0 : 0x708)
		mov	cx, word_1C82C
		sub	bx, bx
		sub	cx, 8000h
		sbb	bx, bx
		neg	cx
		adc	bx, 0
		neg	bx ; B) BX:CX = 0x8000 - (long)(word_1C82C)
		mov	word ptr [bp+var_30], cx
		mov	word ptr [bp+var_30+2],	bx ; C) var_30 = BX:CX
		mov	cl, 5
		mov	word ptr [bp+var_34], ax
		mov	word ptr [bp+var_34+2],	dx ; D) var_34 = DX:AX
		mov	ax, word ptr [bp+var_30]
		mov	dx, bx                     ; E) DX:AX = var_30
loc_146E3:
		shl	ax, 1
		rcl	dx, 1
		dec	cl
		jz	short loc_146ED
		jmp	short loc_146E3            ; F) DX:AX <<= 5
loc_146ED:
		sub	ax, word ptr [bp+var_34]
		sbb	dx, word ptr [bp+var_34+2] ; G) DX:AX -= var_34
		mov	word ptr dword_1D650, ax
		mov	word ptr dword_1D650+2,	dx ; H) dword_1D650 = AX:DX
{% endhighlight %}

Is it a coincidence that it's always 32bit (long) numbers that are giving me trouble? This time however, the actual arithmetic is not (much of) the problem. What this does essentially, is calculate two long values in `DX:AX` (A) and `BX:CX` (B), respectively, before shifting one left by 5 bits (F), calculating the final result as a subtraction of the two (G), and placing the result in another variable (H). Also, the values making up the calculation are stored and retrieved from stack variables while this is going on (C, D, E). It essentially comes to this:

{% highlight cpp %}
void someRoutine()
    // ...
    long var_30, var_34;
    // ...
    var_34 = (long)((word_1C830 & 0x200) ? 0 : 0x708);
    var_30 = 0x8000 - (long)word_1C82C;
    dword_1D650 = (var_30 << 5) - var_34;
    // ...
}
{% endhighlight %}

I have already figured out the arithmetic [in a previous post]({% post_url 2024-05-05-ghidra %}), and the calculations are correct and resolving to identical instructions. However, this will not produce exactly matching instructions for the entire block. As soon as the compiler sees an assignment to `var_34`, it will emit a write of the value to the stack. In the original code, the stores are interwoven with the calculations in a weird way; 

1. The value of var_34 is calculated but not stored 
2. The value of var_30 is calculated and stored in the variable
3. The counter for the long bit shift loop is initialized (?)
4. The value of var_34 is stored in its variable
5. The value of var_30 is read back for shifting, subtraction and storage in the destination

Particularly, there does not appear to be a way (in the C programming language) to force a delay of the store in 4) until after the calculation result of 2) is stored in 3). You write a statement to calculate something and where to place the result, and it's done immediately (modern compilers may very well do crazy reoderding, but we are living in 1989 here). You cannot say `x = y + 5... but write to x a little later please`. So this looks like some quirky compiler behaviour due to needing to juggle the limited register storage to perform the requested calculation.

Also, that the values are stored in the middle of the calculation smells of the "assignment as subexpression" idiom (`a = (b = c + d)`) that I've seen used heavily throughout the reconstructed code. So how about this?

{% highlight cpp %}
dword_1D650 = ((var_30 = 0x8000 - (long)word_1C82C) << 5) - (var_34 = (long)((word_1C830 & 0x200) ? 0 : 0x708));
{% endhighlight %}

I used to get nausea from code like this before, but these days it's just another day at the reversing office. However, there are two problems (one of them made up). Notice that the `var_34` subexpression with the conditional inside comes second in the overall expression. Meanwhile, in the disassembly, it actually comes first. Until now in my experience, the order of the machine instructions was matching the natural order of operations in the expression. Here however, probably because of the conditional, the compiler actually does the `var_34` calculation first, no matter where it's placed in the expression. So it's not actually a problem - see, told you. 😉

The real problem is that it will still produce the store as soon as possible:

<pre>
1000:46ad/0146ad: test word [si+0x5ce0], 0x200     ~= 1000:1951/011951: test word [si+0x5d26], 0x200
1000:46b3/0146b3: jz 0x46b9 (0x4 down)             == 1000:1957/011957: jz 0x195d (0x4 down)
1000:46b5/0146b5: sub ax, ax                       == 1000:1959/011959: sub ax, ax
1000:46b7/0146b7: jmp short 0x46bc (0x3 down)      == 1000:195b/01195b: jmp short 0x1960 (0x3 down)
1000:46b9/0146b9: mov ax, 0x708                    == 1000:195d/01195d: mov ax, 0x708
1000:46bc/0146bc: cwd                              == 1000:1960/011960: cwd
<r>1000:46bd/0146bd: mov cx, [si+0x5cdc]              != 1000:1961/011961: mov [bp-0x32], ax</r>
ERROR: Instruction mismatch in routine sub_14093 at 1000:46bd/0146bd: mov cx, [si+0x5cdc] != 1000:1961/011961: mov [bp-0x32], ax
--- Context information for up to 30 additional instructions after mismatch location:
1000:46c1/0146c1: sub bx, bx                       != 1000:1964/011964: mov [bp-0x30], dx
1000:46c3/0146c3: sub cx, 0x8000                   != 1000:1967/011967: mov cx, [si+0x5d22]
1000:46c7/0146c7: sbb bx, bx                       != 1000:196b/01196b: sub bx, bx
1000:46c9/0146c9: neg cx                           != 1000:196d/01196d: sub cx, 0x8000
1000:46cb/0146cb: adc bx, 0x0                      != 1000:1971/011971: sbb bx, bx
1000:46ce/0146ce: neg bx                           != 1000:1973/011973: neg cx
1000:46d0/0146d0: mov [bp-0x30], cx                != 1000:1975/011975: adc bx, 0x0
</pre>

It writes `dx:ax` to var_34 as soon as it's done calculating the value. There does not appear to be a way to have the cake and eat it too. 

I spent two days trying to rewrite the expression in as many ways as possible. For a while, abusing the seldom used behaviour of the comma operator in C could be the golden ticket:

{% highlight cpp %}
var_34 = (var_30 = 0x8000 - (long)word_1C82C), (long)((word_1C830 & 0x200) ? 0 : 0x708);
{% endhighlight %}

This evaluates the expressions from left to right, and yields the value of the last expression as the result. However, in this case actually the left-to-right order is observed, and var_30 really is evaluated first (which is the way I wrote it, but hoped the compiler would reorder it). So again, no dice.

This had me puzzled and out of ideas. Looking at the sequence of the instructions, it seemed like the compiler decided to dump `dx:ax` onto the stack because it needed them to do arithmetic in the shifting loop (It seems to prefer those for 32bit arithmetic, idk). So maybe this is not a store that the programmer wanted at all? Maybe the compiler just figured it needed a place to put the intermediate results, and decided on the stack behind my back? I remove the two impossibile stores:

{% highlight cpp %}
dword_1D650 = ((0x8000 - (long)word_1C82C) << 5) - ((long)((word_1C830 & 0x200) ? 0 : 0x708));
{% endhighlight %}

Success! Even though I did not request it, the compiler stores the values by itself. My routine completely matches the original at the problematic location, and a couple hundred instructions afterwards. Scratch that off, move to the next one. Whew, that was sneaky!
