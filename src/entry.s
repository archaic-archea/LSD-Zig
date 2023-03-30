.section .init
 
.option norvc
 
.type start, @function
.global _start
_start:
	.cfi_startproc
 
    .option push
    .option norelax
	la gp, __global_pointer
    .option pop

    la tp, __tdata_start

	j kernel
 
	/* Clear the BSS section */
	la t5, __bss_start
	la t6, __bss_end
    bss_clear:
        bgeu t5, t6, kernel
        sd zero, (t5)
        addi t5, t5, 8
		j bss_clear
 
	kernel:
		/* Jump to kernel! */
		tail kentry
 
	.cfi_endproc
 
.end