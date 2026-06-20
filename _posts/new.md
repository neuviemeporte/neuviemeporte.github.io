
```

drawProjectionSphere: seg000 NEAR 0334-0685 R0334-03ff R0400-0685

0000:048c/00048c: mov word [bp-0x04], 0x0          == 0000:7d04/007d04: mov word [bp-0x04], 0x0
0000:0491/000491: mov si, [bp-0x04]                != 0000:7d09/007d09: mov ax, [bp-0x04]
ERROR: Instruction mismatch in routine drawProjectionSphere at 0000:0491/000491: mov si, [bp-0x04] != 0000:7d09/007d09: mov ax, [bp-0x04]
--- Context information for up to 20 additional instructions of routine drawProjectionSphere after mismatch location:
0000:0494/000494: shl si, 1                        != 0000:7d0c/007d0c: shl ax, 1
0000:0496/000496: add si, bp                       != 0000:7d0e/007d0e: add ax, bp
0000:0498/000498: mov ax, [si-0x26]                != 0000:7d10/007d10: mov [bp-0x00a6], ax
0000:049b/00049b: mov [bp-0x009c], ax              != 0000:7d14/007d14: mov bx, ax
0000:049f/00049f: mov ax, [si-0x48]                != 0000:7d16/007d16: mov ax, [bx-0x26]

// ==== seg000:0x0334 ====
void drawProjectionSphere(int arg_0)
{
    int p;
    int a;
    int b[17];
    int c[17];
    int d[17];
    int e[17];
    int f[8];
    int g;
    register int i;
    register int j;

    if (*(char *)&word_38FDC < 3) {
        sub_1FEEC(arg_0);
        return;
    }
    a = 0;
    do {
        i = a + a;
        *((int *)((char *)&word_3BE9C + i)) = *((int *)((char *)&word_32990 + i));
        a++;
    } while (a < 16);
    word_38FC6 = -var_226;
    p = (int)(((long)var_224 << 8) / (long)(var_225 < 0x200 ? 0x200 : var_225));
    if (var_594 != 0) {
        p <<= var_594;
    }
    if (var_456 != 0) {
        p >>= 1;
    }
    for (a = 0; a < 17; a++) {
        if (a < 16) {
            g = (&word_3BE9C)[a] + p;
        } else {
            g = 0x5848;
        }
        i = fixedMulQ14(-0x5848, var_227);
        j = fixedMulQ14(g, word_38FC6);
        b[a] = (word_3298C + i) - j;
        d[a] = -i + word_3298C - j;
        i = fixedMulQ14(g, var_227);
        j = fixedMulQ14(-0x5848, word_38FC6);
        c[a] = -(-((i + j >> 2) - i) + j) + word_3298E;
        e[a] = ((i - j >> 2) + word_3298E) - i + j;
    }
    a = 0;
    do {
        f[0] = b[a]; 🔴
        f[1] = c[a];
        f[2] = d[a];
        f[3] = e[a];
        f[4] = d[a + 1];
        f[5] = e[a + 1];
        f[6] = b[a + 1];
        f[7] = c[a + 1];
        drawPolygonOutline(word_3298A, 4, f, a + 0x60);
        a++;
    } while (a < 16);

// ==== seg000:0x0334 ====
void drawProjectionSphere(int arg_0)
{
    int p;
    int a;
    int b[17];
    int c[17];
    int d[17];
    int e[17];
    int f[8];
    int g;

    if (*(char *)&word_38FDC < 3) {
        sub_1FEEC(arg_0);
        return;
    }
    {
        register int i;
        a = 0;
        do {
            i = a + a;
            *((int *)((char *)&word_3BE9C + i)) = *((int *)((char *)&word_32990 + i));
            a++;
        } while (a < 16);
    }
    word_38FC6 = -var_226;
    p = (int)(((long)var_224 << 8) / (long)(var_225 < 0x200 ? 0x200 : var_225));
    if (var_594 != 0) {
        p <<= var_594;
    }
    if (var_456 != 0) {
        p >>= 1;
    }
    {
        register int i;
        register int j;
        for (a = 0; a < 17; a++) {
            if (a < 16) {
                g = (&word_3BE9C)[a] + p;
            } else {
                g = 0x5848;
            }
            i = fixedMulQ14(-0x5848, var_227);
            j = fixedMulQ14(g, word_38FC6);
            b[a] = (word_3298C + i) - j;
            d[a] = -i + word_3298C - j;
            i = fixedMulQ14(g, var_227);
            j = fixedMulQ14(-0x5848, word_38FC6);
            c[a] = -(-((i + j >> 2) - i) + j) + word_3298E;
            e[a] = ((i - j >> 2) + word_3298E) - i + j;
        }
    }

```

building fully optimized breaks the game - probably the reason parts were built with /zi, because it worked and they needed to ship