pub const GeneralRegisters = packed struct {
    ra: usize, // trapframe offset 8
    gp: usize, // trapframe offset 16
    sp: usize, // trapframe offset 24
    tp: usize, // trapframe offset 32
    t0: usize, // trapframe offset 40
    t1: usize, // trapframe offset 48
    t2: usize, // trapframe offset 56
    s0: usize, // trapframe offset 64
    s1: usize, // trapframe offset 72
    a0: usize, // trapframe offset 80
    a1: usize, // trapframe offset 88
    a2: usize, // trapframe offset 96
    a3: usize, // trapframe offset 104
    a4: usize, // trapframe offset 112
    a5: usize, // trapframe offset 120
    a6: usize, // trapframe offset 128
    a7: usize, // trapframe offset 136
    s2: usize, // trapframe offset 144
    s3: usize, // trapframe offset 152
    s4: usize, // trapframe offset 160
    s5: usize, // trapframe offset 168
    s6: usize, // trapframe offset 176
    s7: usize, // trapframe offset 184
    s8: usize, // trapframe offset 192
    s9: usize, // trapframe offset 200
    s10: usize, // trapframe offset 208
    s11: usize, // trapframe offset 216
    t3: usize, // trapframe offset 224
    t4: usize, // trapframe offset 232
    t5: usize, // trapframe offset 240
    t6: usize, // trapframe offset 248
};