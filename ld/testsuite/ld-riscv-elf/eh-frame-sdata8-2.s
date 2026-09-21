# An 8-byte PC-relative FDE initial location is emitted as an
# R_RISCV_ADD64/R_RISCV_SUB64 pair whose subtrahend is a local label in
# .eh_frame.  When the linker merges this CIE with an identical one from
# another input, the FDE moves; its initial location must still match the
# function.

	.option	norvc
	.text
	.global	func2
func2:
	call	func2_callee
	ret
func2_callee:
	ret

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
	.8byte	func2 - .			# initial location
	.8byte	func2_callee - func2		# address range
	.uleb128 0			# augmentation length
	.p2align 3, 0
.Lfde_end:
