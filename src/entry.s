.section .text
.option norvc
 
.type start, @function
.global _start
_start:
	.cfi_startproc

    la tp, __tdata
 
	/* Jump to kernel! */
	tail kentry

	j hlt_loop
 
	.cfi_endproc

hlt_loop:
	wfi
	j hlt_loop
 
.end