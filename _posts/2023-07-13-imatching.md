---
layout: post
title: Trying to think like a compiler
date: 2023-07-13
category: f15-se2
---
<small>(_This post is part of a [series]({% link category/f15-se2.html %}) on the subject of my hobby project, which is recreating the C source code for the 1989 game [F-15 Strike Eagle II]({% post_url 2022-06-05-origins %}) by reverse engineering the original binaries._)</small>

What I'm doing right now is going through the dissassembly of the game executables, rewriting the code into C, and trying to obtain identical instructions when compiling back into executable form, using mzdiff to do the comparison. Despite some problems with being unable to get some parts to match [no matter what I do]({% post_url 2023-05-17-compiler %}) (probably because I still haven't nailed the right compiler + options combination), I have been making some progress with transcribing the code while using some more advanced options I implemented in mzdiff to ignore these differences. I would like to get rid of them completely, but I've been burned out on that front, so instead I decided to move forward and make some actual progress on the recreation.

While working on the START executable's `main()` function, I came across this sequence of instructions in the disassembly:

{% highlight nasm %}
000002F0  C41EF277          les bx,[0x77f2] ; load far pointer to a structure into ES:BX
000002F4  26837F7201        cmp word [es:bx+0x72],byte +0x1 ; compare the value at offset 0x72 in the structure to 1
000002F9  7513              jnz 0x30e ; if not equal jump to the ELSE part of the expression
000002FB  8BC3              mov ax,bx ; conditional code, move the far pointer from ES:BX into DX:AX
000002FD  8CC2              mov dx,es
000002FF  054800            add ax,0x48 ; add an offset to the offset part
00000302  52                push dx ; push the segment and offset  onto the stack to be used as function arguments
00000303  50                push ax
00000304  9ADF00A506        call 0x6a5:0xdf ; call a function with the arguments
00000309  83C404            add sp,byte +0x4 ; pop the arguments off the stack
0000030C  EB08              jmp short 0x316 ; jump over the ELSE part
{% endhighlight %}

Rewritten into C, it might look something like this:

{% highlight cpp %}
union FarAddress {
    struct { uint16 off, seg; } data;
    uint8 far *ptr;
};

#define FARPTR_CAST_OFFSET(type, addr, offset) (type far*)(addr.ptr + offset)
#define COMM_SETUP_USEJOY_OFFSET 0x72

// far function declaration, accepts two word-sized arguments
int far cdecl copyJoystickData(uint16 offset, uint16 segment); 

static union FarAddress commAddr;

int main() {

    /* ... */

    if (*FARPTR_CAST_OFFSET(uint16, commAddr, COMM_SETUP_USEJOY_OFFSET) == 1) {
        // mind that the arguments are pushed in the reverse order that they are specified in the code
        copyJoystickData(commAddr.data.off + COMM_SETUP_JOYDATA_OFFSET, commAddr.data.seg);
    }
    else { /* ... */ }
}
{% endhighlight %}

This however generates the following code which does not exactly match:

{% highlight nasm %}
000002E3  C41ECA05          les bx,[0x5ca]
000002E7  26837F7201        cmp word [es:bx+0x72],byte +0x1
000002EC  7511              jnz 0x2ff
000002EE  06                push es ; push the segment part directly from ES
000002EF  8BC3              mov ax,bx
000002F1  054800            add ax,0x48 ; add the offset through AX and push thence
000002F4  50                push ax
000002F5  9ABA02C101        call 0x1c1:0x2ba
000002FA  83C404            add sp,byte +0x4
000002FD  EB08              jmp short 0x307
{% endhighlight %}

It makes sense to reuse the segment value that is already in ES to push it as an argument, so why did the compiler use DX as a temporary location for it in the original game executable? It took me a couple days to figure out. The function does not accept two arguments, as in the segment and offset, separately. It accepts a single far pointer argument, and two arithmetic-capable registers, namely DX:AX are used as a placeholder for the entire 32bit value to be manipulated arithmetically as a whole. This is just a matter of correcting the declaration and the place it's called to match:

{% highlight cpp %}
int far cdecl copyJoystickData(uint8 far *ptr);

/* ... */
    {
        copyJoystickData(commAddr.ptr + COMM_SETUP_JOYDATA_OFFSET);
    } 
{% endhighlight %}

Now the code matches up. However, some time later I come across this surprise:

{% highlight nasm %}
00000365  C41E0446          les bx,[0x4604] ; load far pointer to a buffer into ES:BX
00000369  8B46F4            mov ax,[bp-0xc] ; load stack variable value into AX
0000036C  2639473E          cmp [es:bx+0x3e],ax ; compare the value at offset 0x3e in the buffer with the stack variable
00000370  7519              jnz 0x38b ; if not equal, jump to conditional code
00000372  268B4738          mov ax,[es:bx+0x38] ; otherwise (OR), check value at offset 0x38 in the buffer
00000376  3946FA            cmp [bp-0x6],ax ; compare directly with a different stack variable
00000379  7510              jnz 0x38b ; if not equal, jump to conditional code
...
{% endhighlight %}

This is part of a longer conditional expression, but again, rewritten into C, it comes to:

{% highlight cpp %}
static union FarAddress commBufferPtr;

#define COMM_BUFFER_START_FFFF1_OFFSET 0x3e
#define COMM_BUFFER_START_FFFF2_OFFSET 0x38

int main(int argc, char* argv[]) 
{
    uint16 var_C;
    uint16 var_6;

    /* ... */

    if (*FARPTR_CAST_OFFSET(uint16, commBufferPtr, COMM_BUFFER_START_FFFF1_OFFSET) != var_C ||
        *FARPTR_CAST_OFFSET(uint16, commBufferPtr, COMM_BUFFER_START_FFFF2_OFFSET) != var_6)
    {
        // conditional code
    }
{% endhighlight %}

The problem I encountered was that the compiler generates code like this:

{% highlight nasm %}
00000358  C41ED405          les bx,[0x5d4]
0000035C  8B46F4            mov ax,[bp-0xc]
0000035F  2639473E          cmp [es:bx+0x3e],ax
00000363  7517              jnz 0x37c ; so far so good
00000365  8B46F2            mov ax,[bp-0xe] ; no good, stack value goes to ax instead of the far value
00000368  26394738          cmp [es:bx+0x38],ax ; and gets compared with the far value directly
0000036C  750E              jnz 0x37c
{% endhighlight %}

Why would the compiler put the value of `var_C` in AX the first time and compare with a far location, then reverse the order and put the far value in AX and compare with the stack location of `var_6`? The first thing that came to mind was to reverse the order of comparison in the condition for the second part of the `||`:

{% highlight cpp %}
    if (*FARPTR_CAST_OFFSET(uint16, commBufferPtr, COMM_BUFFER_START_FFFF1_OFFSET) != var_C ||
        var_6 != *FARPTR_CAST_OFFSET(uint16, commBufferPtr, COMM_BUFFER_START_FFFF2_OFFSET))
{% endhighlight %}

This does not make a difference. I am not entirely sure how I came up with it, but I was thinking that `CMP` is essentially a `SUB`, i.e. a subtraction, so it might matter for the flags what signedness the values are and in what order they appear in the subtraction. Surprisingly, all it took for the code to match was to flip the declaration of `var_6` to signed:

{% highlight cpp %}
    uint16 var_C;
    int16 var_6;
{% endhighlight %}

Again, this makes the code match up nicely.

I'm happy to have figured these minor pitfalls out, and I'm sure it will become useful elsewhere as I'm gathering a body of knowledge and building up the capability to recognize the compiler's patterns within my wetware. 😉

