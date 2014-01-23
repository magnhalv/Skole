ENTRY(_reset)

MEMORY
{
  rom (rx) : ORIGIN = 0x00000000, LENGTH = 1048576
  ram (rwx) : ORIGIN = 0x20000000, LENGTH = 131072
}

SECTIONS
{
  .text :
  {
    *(.vectors)
    *(.text)
  } >rom

  .data : ALIGN (8)
  {
    *(.data)
  } >ram

  .bss : ALIGN (8)
  {
    *(.bss)
  } >ram

  stack_top = ORIGIN(ram) + LENGTH(ram);
}
