ENTRY(_start);
 
SECTIONS {
    . = 0xfffffffa80000000;

    .text : ALIGN(4k) {
        PROVIDE(__text_start = .);
        PROVIDE(KERNEL_START = .);
        *(.init)
        *(.text .text.*)
        PROVIDE(__rodata_start = .);
        *(.rodata .rodata.*)
        PROVIDE(__text_end = .);
    }

    .data : ALIGN(4k) {
        PROVIDE(__data_start = .);  
        PROVIDE(__global_pointer = .);
        *(.sdata .sdata.*)     
        *(.data .data.*)
        PROVIDE(__data_end = .); 
    } 

    PROVIDE(__bss_start = .);
    .bss : ALIGN(4k) {
        *(.sbss .sbss.*);
        *(.bss .bss.*)
        PROVIDE(__bss_end = .);
    }

    .tdata : ALIGN(4k) {
        PROVIDE(__tdata_start = .);
        
        *(.tdata .tdata.* .tbss .tbss.*);

        PROVIDE(__tdata_end = .);
    }

    . = ALIGN(2M);
    PROVIDE(KERNEL_END = .);

    /DISCARD/ : { *(.eh_frame_hdr .eh_frame) }
}