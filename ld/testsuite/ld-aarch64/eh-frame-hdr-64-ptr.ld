/* Place the code and .eh_frame more than 2GiB away from .eh_frame_hdr, so
   that eh_frame_ptr needs 8 bytes as well as the search table.  */
SECTIONS
{
  . = 0x10000;
  .eh_frame_hdr : { *(.eh_frame_hdr) }
  . = 0x100000000;
  .text : { *(.text) }
  .eh_frame : { KEEP (*(.eh_frame)) }
}
