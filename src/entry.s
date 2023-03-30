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
 
	/* Jump to kernel! */
	j kentry
 
	.cfi_endproc
 
.end