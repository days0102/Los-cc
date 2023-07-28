/*
    LD 脚本  使用：gcc T XXX.ld
*/

/* OUTPUT_ARCH(arch) 命令指定输出文件所适用的计算机体系架构 */
OUTPUT_ARCH("riscv")

/* ENTRY(symbol) 命令用于设置入口点,参数为一个label */
ENTRY(_start)   /* _start define at init/entry.S */

/*
MEMORY
{
    name [(attr)]: ORIGIN=origin,LENGTH=len
    .....
}
指定内存区域位置、大小
*/
MEMORY
{
	ram   (wxa!ri) : ORIGIN = 0x80000000, LENGTH = 128M
}


/*
SECTIONS
{
     sections-command
     sections-command
     ......
}
*/
SECTIONS
{
    /*
    PROVIDE(symbol=expression)
    赋值
    */
    .text : {   /* 需要空格 */
        PROVIDE(text_start = . );
        *(.text .text.*)
        PROVIDE(text_end = . );
        
        /* usertrap  */
        . = ALIGN(4096);
        *(trap_text)  /* 把 usertrap.S 放到这里 */
    }>ram

    .data : {
        . = ALIGN(4096); 
		PROVIDE(data_start = .);
        *(.sdata .sdata.*)
		*(.data .data.*)
		PROVIDE(data_end = .);
    }>ram

    .rodata : {
        . = ALIGN(4096);        /*保证位1个页偏移*/
		PROVIDE(rodata_start = .);
		*(.rodata .rodata.*)
		PROVIDE(rodata_end = .);
	} >ram
    
    .bss : {
        . = ALIGN(4096);
        PROVIDE(bss_start = .);
		*(.sbss .sbss.*)
		*(.bss .bss.*)
		*(COMMON)
		PROVIDE(bss_end = .);
    }>ram

    /* .traptext : { */
        /* . = ALIGN(4096); */
        /* *(traptext)   把 usertrap.S 放到这里 */
    /* }>ram */

    . = ALIGN(4096);

    PROVIDE(mem_start = ORIGIN(ram));
    PROVIDE(mem_end = ORIGIN(ram)+LENGTH(ram));

    PROVIDE(heap_start = .);         /* 堆的起始位置 */
    PROVIDE(heap_end = mem_end);
}