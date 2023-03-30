.section .text
.option norvc
 
.type start, @function
.global _start
_start:
	.cfi_startproc

    la tp, __tdata
 
	/* Jump to kernel! */
	tail kentry
 
	.cfi_endproc
 
.end