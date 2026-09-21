// Test file for AArch64 GAS -- the MOVW GOT offset operators used by the
// large position-independent code model.

	.text
func:
	movz	x0, #:gotoff_g3:sym
	movk	x0, #:gotoff_g2_nc:sym
	movk	x0, #:gotoff_g1_nc:sym
	movk	x0, #:gotoff_g0_nc:sym
	movz	x1, #:gotoff_g2:sym
	movz	x2, #:gotoff_g1:sym
	movz	x3, #:gotoff_g0:sym
	movn	x4, #:gotoff_g0:sym

// The low-chunk-first order, ending in a MOVK of the top chunk.
	movz	x5, #:gotoff_g0_nc:sym
	movk	x5, #:gotoff_g1_nc:sym
	movk	x5, #:gotoff_g2_nc:sym
	movk	x5, #:gotoff_g3:sym
