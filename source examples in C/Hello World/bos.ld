OUTPUT_FORMAT(binary)
ENTRY(_start)
SECTIONS
{
    . = 0x70000000;
    .text :
    {
        *(.text);
    }
    .data :
    {
        *(.data);
        *(.bss);
        *(.rodata);
    }
    _end = ALIGN(4);
}
