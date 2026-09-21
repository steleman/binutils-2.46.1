/* Place the code more than 2GiB away from .eh_frame_hdr.  */
SECTIONS
{
  . = 0x10000;
  .eh_frame_hdr : { *(.eh_frame_hdr) }
  .eh_frame : { KEEP (*(.eh_frame)) }
  . = 0x100000000;
  .text : { *(.text) }
}
