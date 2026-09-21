# An FDE for code more than 2GiB from .eh_frame_hdr.  The binary search
# table in .eh_frame_hdr then needs DW_EH_PE_datarel | DW_EH_PE_sdata8
# entries, and, as with lld, eh_frame_ptr uses DW_EH_PE_pcrel |
# DW_EH_PE_sdata8 too.

	.text
	.global	_start
_start:
	.4byte	0x00000013
	.4byte	0x00000013

	.section .eh_frame,"a",%progbits
.Lcie:
	.4byte	.Lcie_end - .Lcie_start
.Lcie_start:
	.4byte	0			# CIE id
	.byte	1			# version
	.string	"zR"
	.uleb128 1			# code alignment
	.sleb128 -8			# data alignment
	.uleb128 1			# return address column
	.uleb128 1			# augmentation length
	.byte	0x1c			# DW_EH_PE_pcrel | DW_EH_PE_sdata8
	.byte	0x0c			# DW_CFA_def_cfa
	.uleb128 2
	.uleb128 0
	.p2align 3, 0
.Lcie_end:
.Lfde:
	.4byte	.Lfde_end - .Lfde_start
.Lfde_start:
	.4byte	.Lfde_start - .Lcie	# CIE pointer
	.8byte	_start - .		# initial location
	.8byte	8			# address range
	.uleb128 0			# augmentation length
	.p2align 3, 0
.Lfde_end:
