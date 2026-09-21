# Large position-independent code model support — GNU binutils 2.46.1

This series adds the assembler and linker support needed by the large
position-independent code model (`-mcmodel=large` with `-fpic`/`-fPIC`), as
implemented for AArch64 and RISCV64 by the companion GCC and LLVM series.

The model places code, data and the GOT arbitrarily far apart:

- On **AArch64**, it uses AAELF64 relocations that binutils did not implement
  or implemented incompletely (`MOVW_GOTOFF_G*`, `MOVW_PREL_G*` in gold,
  `TLSIE_MOVW_GOTTPREL_*`), and needs assembler operators to write them.
- On **RISCV64**, it needs no new relocations, but it uses 8-byte
  PC-relative exception-handling pointers, which ld.bfd corrupted.
- On **both**, code or `.eh_frame` can end up more than 2 GiB from
  `.eh_frame_hdr`, which `ld.bfd` could neither index nor point to.

Objects from GCC and Clang, assembled by GNU as or LLVM's integrated
assembler, link and run with `ld.bfd`, `ld.gold` and `lld` in every combination
tested.

## Contents

| Patch | Component | Summary |
|---|---|---|
| 01 | bfd, ld | `R_AARCH64_MOVW_GOTOFF_G0..G3` (five new reloc codes and HOWTOs); MOV[NZ] handling of `GOTOFF_G*` and `TLSIE_MOVW_GOTTPREL_G1`; a MOVK stays a MOVK |
| 02 | gas | `:gotoff_g0:` `:gotoff_g1_nc:` `:gotoff_g2:` `:gotoff_g2_nc:` `:gotoff_g3:` (`:gotoff_g3:` also on MOVK); gas and ld-aarch64 tests |
| 03 | gold | `R_AARCH64_MOVW_PREL_G*`, `MOVW_GOTOFF_G*`, `TLSIE_MOVW_GOTTPREL_G1/_G0_NC` |
| 04 | bfd, ld | 64-bit `.eh_frame_hdr` (8-byte `eh_frame_ptr`, `DW_EH_PE_datarel\|sdata8` search table) when code or `.eh_frame` is out of 32-bit reach; AArch64 and RISCV tests |
| 05 | bfd, ld | RISCV: fix 8-byte PC-relative `.eh_frame` fields (`ADD64`/`SUB64` pairs) in entries moved by `.eh_frame` merging; test |

Base: `binutils-with-gold-2.46.1` with the Fedora 44 patches from
`binutils-2.46.1-1.fc44.src.rpm`, applied by `../apply-fedora-patches.sh`.
Apply in order from the top of that tree:

```sh
for p in binutils-mcmodel-large-pic-0*.patch; do patch -p1 < $p; done
```

The series is applied to `../binutils-with-gold-2.46.1`. Patch 01 includes the
regenerated `bfd/bfd-in2.h` and `bfd/libbfd.h` (from `make headers` in the
build's `bfd/` directory).

### What needs which patch

| Use | AArch64 | RISCV64 |
|---|---|---|
| Assemble GCC large-PIC output with gas | 02 | — (no new operators) |
| Assemble `clang -S` / `llc` large-PIC output with gas | 02 (`:gotoff_g3:` on MOVK) | — |
| Link large-PIC objects with ld.bfd | 01 | — |
| Link large-PIC objects with ld.gold | 03 | No RISCV port |
| Link LLVM objects with ld.bfd or ld.gold | 01 / 03 (MOVN placeholder, `GOTOFF_G3` on MOVK) | — |
| Large-model C++ exceptions with ld.bfd | — | 05 |
| Code or `.eh_frame` more than 2 GiB from `.eh_frame_hdr` with ld.bfd | 04 | 04 |

---

## Patch 01 — bfd/ld: `R_AARCH64_MOVW_GOTOFF_G*`

AAELF64 allocates `R_AARCH64_MOVW_GOTOFF_G0` through `_G3` (300–306), which
compute `G(GDAT(S)) - GOT`: the offset of a symbol's GOT entry from the GOT
base, in 16-bit chunks. BFD knew only `_G0_NC` and `_G1`. The large PIC model
loads GOT entries with the full four-chunk offset:

```asm
  movz x0, #:gotoff_g3:sym          // R_AARCH64_MOVW_GOTOFF_G3
  movk x0, #:gotoff_g2_nc:sym       // R_AARCH64_MOVW_GOTOFF_G2_NC
  movk x0, #:gotoff_g1_nc:sym       // R_AARCH64_MOVW_GOTOFF_G1_NC
  movk x0, #:gotoff_g0_nc:sym       // R_AARCH64_MOVW_GOTOFF_G0_NC
  ldr  x0, [gotbase, x0]
```

### Relocation codes

`reloc.c` adds `BFD_RELOC_AARCH64_MOVW_GOTOFF_G0`, `_G1_NC`, `_G2`, `_G2_NC`
and `_G3`. `elfNN_aarch64_howto_table` is indexed by
`code - BFD_RELOC_AARCH64_RELOC_START`, so each new HOWTO sits at the same
position as its enum. The new relocations are handled wherever the existing
two are:

- `aarch64_reloc_got_type` and `elfNN_aarch64_check_relocs` create a GOT entry.
- `aarch64_relocation_aginst_gp_p` marks them GOT-base-relative.
- `elfNN_aarch64_final_link_relocate` and `_bfd_aarch64_elf_resolve_relocation`
  compute `G(GDAT(S)) - GOT`, where GOT is `_GLOBAL_OFFSET_TABLE_`, the start
  of `.got`, as in lld.

### MOV[NZ] and MOVK

AAELF64 classifies `MOVW_GOTOFF_G0..G3` and `TLSIE_MOVW_GOTTPREL_G1` as
MOV[NZ]: the linker writes MOVZ or MOVN depending on the sign of the value.
Before this patch, ld only patched the immediate of `GOTOFF_G1` and
`GOTTPREL_G1`. LLVM emits a MOVN placeholder for `:gottprel_g1:`, so ld turned
it into a wrong offset and the program crashed at run time.

`_bfd_aarch64_elf_put_addend` now treats them as MOV[NZ], with one rule taken
from lld: **an instruction that is already a MOVK stays a MOVK**, and only its
immediate is patched (checked through opcode bits 29–30). LLVM builds a GOT
offset low chunk first, with `movz #:gotoff_g0_nc:` followed by MOVKs, and
puts `GOTOFF_G3` on the final MOVK. Rewriting that instruction to MOVZ would
wipe the 48 bits the earlier MOVKs built. The rule also covers the existing
MOV[NZ] relocations, which GNU as never places on a MOVK, so existing output
is unchanged.

---

## Patch 02 — gas: `:gotoff_gN:` operators

`reloc_table` in `gas/config/tc-aarch64.c` gains the missing operators. The
full set is now:

```
:gotoff_g0:  :gotoff_g0_nc:  :gotoff_g1:  :gotoff_g1_nc:
:gotoff_g2:  :gotoff_g2_nc:  :gotoff_g3:
```

The spellings follow the relocation names and the existing `:prel_gN:` and
`:gottprel_gN:` operators, and they are exactly what LLVM's integrated
assembler accepts. GOT offsets depend on the final GOT layout, so
`md_apply_fix` and `aarch64_force_reloc` always emit them as relocations.

`process_movw_reloc_info` decides which instruction each operator may appear
on:

| Operator | MOVZ/MOVN (64-bit) | MOVK | 32-bit register |
|---|---|---|---|
| `:gotoff_g0_nc:`, `:gotoff_g1_nc:`, `:gotoff_g2_nc:` | Yes | Yes | — |
| `:gotoff_g0:`, `:gotoff_g1:`, `:gotoff_g2:` (MOV[NZ] class) | Yes | **Rejected** | `g2` rejected |
| `:gotoff_g3:` (MOV[NZ] class) | Yes | **Accepted** | Rejected |
| `:gottprel_g1:` (MOV[NZ] class) | Yes | **Rejected** | — |

`:gotoff_g3:` on MOVK is the one deliberate exception. `clang -S` and `llc`
write LLVM's low-chunk-first sequence, which ends in
`movk xN, #:gotoff_g3:sym`, and gas must be able to assemble it. Linkers
leave a MOVK a MOVK (patch 01, patch 03 and lld), so the top chunk is patched
without disturbing the lower ones. Don't change which instructions accept
MOV[NZ]-class operators without checking both GCC's and LLVM's output against
it.

Tests:
- `gas/aarch64/reloc-gotoff-large.{s,d}`: every operator emits the right
  relocation.
- `gas/aarch64/reloc-gotoff-large-bad.{s,d,l}`: the rejected placements
  produce errors.
- `ld-aarch64/large-pic-gotoff.{s,d}`: a linked GOT base plus GOT load, with
  the resolved chunks.
- `ld-aarch64/large-pic-movk.{s,d}`: LLVM's low-chunk-first sequence keeps
  its final MOVK under `GOTOFF_G3`, and MOVN placeholders under `GOTOFF_G1`
  and `TLSIE_MOVW_GOTTPREL_G1` are rewritten by the sign of the value.

---

## Patch 03 — gold: AArch64 large PIC relocations

gold rejected every relocation of the model:

- `MOVW_PREL_G*` failed with "unsupported reloc 293", and `MOVW_PREL` against
  `_GLOBAL_OFFSET_TABLE_` hit an internal error.
- `MOVW_GOTOFF_G*` had relocate cases but no properties and no scan support.
- `TLSIE_MOVW_GOTTPREL_G1/_G0_NC` were marked unimplemented.

`aarch64-reloc.def` adds or enables the rows (implemented flag, overflow
bounds, selected bits) that drive `AArch64_reloc_property`, and `aarch64.cc`
implements them:

| Relocations | Value | Scan | Notes |
|---|---|---|---|
| `MOVW_PREL_G0..G3` (+`_NC`) | `S + A - P` | Possible function-pointer reference | Checked variants select MOVZ/MOVN by sign |
| `MOVW_GOTOFF_G0..G3` (+`_NC`) | `G(GDAT(S)) - GOT` | Creates a GOT entry (`Scan::local`/`global`); possible function-pointer reference | gold biases `_GLOBAL_OFFSET_TABLE_` by 0x8000 for GOTs of 0x8000 bytes or more, and `GOT_OFFSET` is already relative to that biased symbol, so the offset matches a GOT base computed from the symbol |
| `TLSIE_MOVW_GOTTPREL_G1/_G0_NC` | GOT offset of the TLS entry | Creates a TLS GOT entry | Applied in `Relocate::relocate_tls`; `optimize_tls_reloc` never relaxes them to LE |

`AArch64_relocate_functions::movnz` follows the same MOVK rule as patches 01
and lld.

---

## Patch 04 — ld: 64-bit `.eh_frame_hdr`

The binary search table in `.eh_frame_hdr` always used
`DW_EH_PE_datarel|sdata4`, so any link that placed code more than 2 GiB from
`.eh_frame_hdr` failed with ".eh_frame_hdr entry overflow". The large code
model on AArch64, RISCV and x86-64 allows exactly that layout. The header's
`eh_frame_ptr` was always `DW_EH_PE_pcrel|sdata4` too, and when `.eh_frame`
itself was more than 2 GiB away it was silently truncated, with no diagnostic
(`0xffffffffc0013970` for `.eh_frame` at `0xc0013970`).

- `eh_frame_hdr_needs_64bit` (`elf-eh-frame.c`) checks every allocated
  code section and `.eh_frame` against the header's address. It runs from
  `_bfd_elf_discard_section_eh_frame_hdr` (reached through
  `bfd_elf_discard_info` in each ELF emulation's `after_allocation`), after
  addresses are assigned but before final layout. If either end of any section
  is 2 GiB − 128 MiB or more away, it sets `dwarf_eh_frame_hdr_info.hdr_64`.
  The 128 MiB margin covers sections that may still move through stubs or
  relaxation.
- The output ELF header is not initialized at that point, so the 64-bit check
  uses `get_elf_backend_data (abfd)->s->elfclass` rather than `elf_elfheader`.
- With `hdr_64`, as in lld, both encodings widen together:
  `write_dwarf_eh_frame_hdr` writes `eh_frame_ptr` as 8 bytes (encoding 0x1c,
  `DW_EH_PE_pcrel|sdata8`), which lengthens the header from 8 to 12 bytes, and
  the search table as 16-byte entries (encoding 0x3c,
  `DW_EH_PE_datarel|sdata8`). The widening applies only to the default
  pcrel|sdata4 encoding from `elf_backend_encode_eh_address`; only 32-bit
  backends override that hook, and a `BFD_ASSERT` guards the header layout.
- Every link whose header fits in 32 bits produces byte-identical output.

Unwinders: LLVM libunwind reads 0x3c tables. libgcc before GCC series patch 09
finds FDEs correctly but falls back to a linear scan of `.eh_frame`, starting
from `eh_frame_ptr`; with patch 09 it binary searches the 64-bit table.

Tests (for `ld-aarch64` and `ld-riscv-elf`):
- `eh-frame-hdr-64.{s,d,ld}` place `.text` at 4 GiB, above a header at
  64 KiB, and check the 12-byte header with the 0x3c table.
- `eh-frame-hdr-64-ptr.{d,ld}` also move `.eh_frame` up to 4 GiB and check
  that the 8-byte `eh_frame_ptr` reaches it.

All four fail with the version of this patch that widened only the table.

The `eh_frame_ptr` widening was added on 2026-09-17. The first version of the
patch widened only the table. Its truncated `eh_frame_ptr` made libgcc
without GCC patch 09 segfault in the AArch64 libgcc test below, where
`.eh_frame` sits with the code 3 GiB from the header.

---

## Patch 05 — ld RISCV: 8-byte PC-relative `.eh_frame` fields

RISCV has no 64-bit PC-relative data relocation. An 8-byte `sym - .` in
`.eh_frame` is emitted by GNU as and LLVM as an `R_RISCV_ADD64`/`R_RISCV_SUB64`
pair, whose subtrahend is a local label at the field itself. Examples are a
`DW_EH_PE_pcrel|sdata8` FDE initial location, LSDA pointer or personality
pointer, which GCC and LLVM now use in the large code model.

When ld edits `.eh_frame`, later entries move, for example after merging a
CIE identical to one from an earlier input. Two separate mechanisms then
compensated for the same move:

1. `adjust_eh_frame_local_symbols` moves the local labels inside `.eh_frame`
   to their new offsets.
2. `_bfd_elf_write_section_eh_frame` adds `OFFSET - NEW_OFFSET` to every
   PC-relative field of a moved entry. It assumes those fields were resolved
   at their original location, as `R_RISCV_32_PCREL` is.

The `ADD64`/`SUB64` form was therefore adjusted twice. Every FDE after a
merged CIE pointed at the wrong code, with no diagnostic, and C++ exceptions
through that code called `std::terminate`. Before this patch, every
large-model C++ program linked by ld.bfd from more than one object failed
this way.

`riscv_elf_relocate_section` now handles a SUB relocation in an edited
`.eh_frame` (`SEC_INFO_TYPE_EH_FRAME`) whose non-section subtrahend is the
relocated field's new offset. It resolves that subtrahend at the field's
original location, the same convention `R_RISCV_32_PCREL` follows. lld was
always correct.

Test: `ld-riscv-elf/eh-frame-sdata8.d` links two objects with identical CIEs
and 8-byte FDE locations, with relaxation enabled, and checks that the second
FDE still covers its function.

---

## Compatibility with LLVM and lld

### AArch64

| Aspect | GNU binutils (this series) | LLVM / lld | Status |
|---|---|---|---|
| Operator spellings | `:gotoff_g0:` … `:gotoff_g3:` | Same (LLVM series 0001) | Identical; gas and llvm-mc emit the same relocations for the same source, verified on lld's own tests |
| `:gotoff_g3:` on MOVK | Accepted | Emitted by `clang -S`/`llc` | gas assembles LLVM's textual output |
| MOV[NZ] relocation on a MOVK | Immediate only (ld.bfd, ld.gold) | Immediate only (lld) | Same rule in all three linkers |
| MOVN placeholder under `:gottprel_g1:` | Rewritten by sign | LLVM emits MOVN, gas MOVZ | Linkers rewrite by sign, so the objects are equivalent |
| `_GLOBAL_OFFSET_TABLE_` | Start of `.got` (ld.bfd); +0x8000 bias for large GOTs (gold), with GOT offsets relative to the biased symbol | Start of `.got` (lld) | A GOT base computed from the symbol is consistent in all three |
| IE→LE relaxation of `TLSIE_MOVW_GOTTPREL_G1/_G0_NC` | Never (ld.bfd, ld.gold) | Never (lld, LLVM series 0002) | Required: the `LDR` that consumes the offset has no relocation |
| `.eh_frame_hdr` beyond 2 GiB | 0x1c `eh_frame_ptr` + 0x3c table (patch 04) | Same | Same encodings |

Both rejected alternatives to the MOVK rule crash at run time with LLVM
objects:
- Patching only the immediate, as pristine ld.bfd did, turns LLVM's MOVN
  placeholder into a wrong offset.
- Always rewriting to MOVZ, as an interim version did during development,
  wipes the low 48 bits built by the preceding MOVKs.

GCC emits `movz #:gotoff_g3:` first and is unaffected by either.

### RISCV64

| Aspect | GNU binutils (this series) | LLVM / lld | Status |
|---|---|---|---|
| Large PIC relocations | Existing `ADD64`/`SUB64`, `R_RISCV_64` | Same | No new relocation types on either side |
| 8-byte `.eh_frame` fields after CIE merging | Correct (patch 05) | Correct (lld) | Previously silent corruption in ld.bfd only |
| `.eh_frame_hdr` beyond 2 GiB | 0x1c `eh_frame_ptr` + 0x3c table (patch 04) | Same | Same encodings |
| gas FDE initial location from `.cfi_*` directives | Always pcrel\|sdata4 | `llvm-mc` uses sdata8 only with `-large-code-model` | This is why GCC's RISCV large model emits `.eh_frame` itself (GCC patch 08) |

### Limits shared with lld

- PLT stubs, and lld's AArch64 PIE range-extension thunks, are ADRP-based, so
  in dynamically linked programs, calls through the PLT still need the PLT
  within 4 GiB of the caller.
- AArch64 initial-exec TLS limits the GOT to 4 GiB, since AAELF64 defines only
  two `GOTTPREL` MOVW chunks.
- No signed-GOT (`R_AARCH64_AUTH_MOVW_GOTOFF_G*`) support anywhere.

---

## Verification

### Original testing (with GCC 16.0.1 and clang/lld 23.1.1)

Cross toolchains for `aarch64-linux-gnu` and `riscv64-linux-gnu`, glibc
sysroots, qemu-user:

| Check | Result |
|---|---|
| AArch64 runtime ABI matrix: large-PIC DSO + PIE, {GCC, Clang} × {GCC, Clang} objects, `-O2`/`-O0`, GCC output assembled by gas | 24/24 with ld.bfd, ld.gold and lld |
| Same matrix with Clang objects from `clang -fno-addrsig -S` assembled by gas (output contains `movk xN, #:gotoff_g3:sym`) | 24/24 with ld.bfd, ld.gold and lld |
| AArch64 far layout: data and GOT 5 GiB from the code, GCC and Clang objects | Pass with ld.bfd, ld.gold and lld; the small model fails to link |
| RISCV runtime matrix | 16/16 with ld.bfd and lld |
| RISCV C++ exceptions through destructors and callbacks, DSO + PIE, GCC/Clang/mixed, normal and with code 3 GiB from `.eh_frame(_hdr)` | 24/24 |
| `.eh_frame_hdr`: `_Unwind_Find_FDE` for 200 functions 3 GiB away | Succeeds with ld.bfd and lld tables; a deliberately corrupted table proves libgcc uses the 64-bit binary search |
| No regressions: every `run_dump_test` in `gas/testsuite/gas/{aarch64,riscv}`, `ld/testsuite/{ld-aarch64,ld-riscv-elf,ld-elf}` | 2171 tests over both targets, identical output with pristine and patched binutils |
| New tests (7 `.d` files; 9 since the patch 04 fix added `eh-frame-hdr-64-ptr` for ld-aarch64 and ld-riscv-elf) | All pass with the series and fail with pristine binutils |

`-fno-addrsig` is needed only because gas has no `.addrsig` directive. gas and
llvm-mc objects assembled from the same `llc` output have identical
relocations. The only instruction difference is the MOVZ vs MOVN placeholder
under `:gottprel_g1:`, which the linkers rewrite by sign.

DejaGnu is not installed on the test machine, so the testsuite checks used a
harness that runs each `.d` file's as/ld/dump pipeline, plus a
`run_dump_test`/`regexp_diff` emulator.

### With GCC 16.2.0 (2026-09-17)

These binutils, built for both targets, were the assembler and linkers for
the GCC 16.2.0 series verification:

| Check | Result |
|---|---|
| AArch64 runtime ABI matrix, GCC 16.2.0 + Clang 23.1.1, `-O2`/`-O0` | 24/24 with ld.bfd, ld.gold and lld |
| RISCV runtime ABI matrix | 16/16 with ld.bfd and lld |
| AArch64 far data layout: freestanding static programs, data and GOT 5 GiB from `.text`, {GCC, Clang} × {GCC, Clang}, `-O2`/`-O0` | 24/24 with ld.bfd, ld.gold and lld; the small model fails to link with all three |
| `.eh_frame_hdr` 0x3c table with GCC 16.2.0 libgcc: DSO with 200 functions 3 GiB above the header, looked up with `_Unwind_Find_FDE`, table intact and deliberately corrupted | RISCV (ld.bfd, lld) and AArch64 (lld): correct with patched and baseline libgcc_s; corruption breaks only patched libgcc_s, proving it uses the table. AArch64 ld.bfd with `.eh_frame` also 3 GiB from the header: correct too since the `eh_frame_ptr` fix; before it, the pointer wrapped and baseline libgcc_s segfaulted |
| Patch 04 `eh_frame_ptr` fix | New and updated `eh-frame-hdr-64*` tests pass with the fixed ld.bfd and fail with the previous one. Differential run of every `ld-aarch64`, `ld-riscv-elf` and `ld-elf` dump test (675 compared) with the previous and fixed ld.bfd: identical output apart from those 4 tests. 16 relinked GCC programs and libraries (C and C++, crt files, libstdc++) byte-identical; only the far layouts change. Runtime matrices (AArch64 24/24, RISCV 16/16), C++ exceptions and the RISCV 3 GiB EH test still pass |
| AArch64 Clang textual output (`clang -fno-addrsig -S`, `movk #:gotoff_g3:`) assembled by gas, in the runtime matrix and the 5 GiB layout | 24/24 and 24/24 with ld.bfd, ld.gold and lld. Code differs from integrated-assembler objects only in the `:gottprel_g1:` MOVZ/MOVN placeholder; gas FDEs built from `.cfi_*` use `PREL32` initial locations where LLVM's assembler uses `PREL64` |
| RISCV far data layout: data 3 GiB from `.text`, {GCC, Clang} × {GCC, Clang} objects, `-O2`/`-O0` | 16/16 with ld.bfd and lld once LLVM's jump-table fix (`98677af3cb50`) is in; before it, links with a Clang object containing a jump table failed on an out-of-range `R_RISCV_PCREL_HI20` in both linkers, correctly diagnosing the compiler bug. medany fails to link as a sanity check |
| RISCV far data layout, switch that keeps a jump table (static and PIC large, `-O2`/`-O0`) | ld.bfd and lld: GCC 16.2.0 objects 8/8; Clang objects 8/8 with the LLVM fix, 0/8 link without it |
| Far-layout linker scripts (test harness) | Need explicit `PHDRS`, or lld stretches the `.eh_frame` segment across the gap; the writable segment must be page-aligned away from the read-only one, or qemu rejects `.bss` overlapping a non-writable page; and the read-only segment must not be empty, because ld.bfd then emits an empty `PT_LOAD` at address 0 (lld drops it), which qemu cannot map |
| C++ exceptions across a large-PIC DSO and PIE | AArch64 6/6 (ld.bfd, ld.gold, lld); RISCV 4/4 (ld.bfd, lld) |
| RISCV library `.text` 3 GiB above `.eh_frame` (GCC's 8-byte FDEs) | Exceptions caught with ld.bfd and lld |
| Same link and run tests with objects built at `-O1` and `-O3` (2026-09-18) | Runtime ABI matrix: AArch64 24/24 with ld.bfd, ld.gold and lld (also with Clang textual output through gas), RISCV 16/16 with ld.bfd and lld; C++ exceptions (GCC objects only) AArch64 6/6, RISCV 4/4, while the RISCV exception tests with Clang and mixed objects, and with code 3 GiB from `.eh_frame(_hdr)`, were not repeated. Far data: AArch64 5 GiB 24/24 (both assemblers), RISCV 3 GiB 16/16; jump-table switch GCC 8/8, Clang 8/8 with the LLVM fix, 0/8 link without it. `.eh_frame_hdr` test (64-bit table and 8-byte `eh_frame_ptr` from both linkers): unchanged on all four target/linker combinations. Small/medany controls fail to link |

Not covered: gold's own testsuite (no new gold tests; the runtime matrices
exercised gold), and 32-bit or big-endian targets beyond building.

## Building and testing notes

```sh
$SRC/configure --target=aarch64-linux-gnu --prefix=$PREFIX \
  --with-sysroot=$SYSROOT --enable-gold --enable-ld=default \
  --disable-gdb --disable-gdbserver --disable-sim --disable-gprofng \
  --disable-doc --disable-nls --disable-werror --with-system-zlib
make MAKEINFO=true
```

- `--with-sysroot` is required for ld to honour `--sysroot` when linking
  through the GCC driver. gold has no RISCV port.
- After editing `bfd/reloc.c`, run `make headers` in the build's `bfd/`
  directory. It rewrites `bfd-in2.h` and `libbfd.h` in the source tree, and
  that output is part of the patch.
- Don't run `ld-elf` tests with a source tree as the working directory:
  several pass `-Map=file.map` with a relative path and overwrite the
  checked-in `.map` expectation files.
- Test registration: `gas/testsuite/gas/aarch64/aarch64.exp` globs `*.d`;
  `ld-aarch64/aarch64-elf.exp` and `ld-riscv-elf/ld-riscv-elf.exp` list tests
  explicitly (`run_dump_test_lp64` for LP64 AArch64 tests).
- Building GCC against these binutils: GCC's configure probes the target
  `as`, `ld` and `objdump`, so put them on `PATH` or pass `--with-as` and
  `--with-ld`. Then check the GCC build's `gcc/config.log`:
  `gcc_cv_ld_ro_rw_mix` should be `read-write` (a probe linking `"a"` and
  `"aw"` sections with ld.bfd and reading the result with objdump) and
  `gcc_cv_as_cfi_directive` should be `yes`. Both GCC 16.2.0 cross builds
  used for the verification above recorded those values. A GCC whose probes
  failed emits `.eh_frame` as `"aw"` and probably no `.cfi_*` directives;
  that is a GCC configuration problem, not a binutils one. The original GCC
  16.0.1 test compilers had it, which produced a wrong "GCC emits `aw` under
  PIC" note, since corrected in the GCC and LLVM docs.

## Related work

| Series | Location |
|---|---|
| GCC 16.2.0 | `/src/steleman/programming/gcc-mcmodel-large/16.2.0/gcc16-mcmodel-large-pic` |
| GCC 16.0.1 | `/src/steleman/programming/gcc-mcmodel-large/16.0.1/gcc16-mcmodel-large-pic` |
| LLVM AArch64 | `/src/steleman/programming/llvm-mcmodel-large/20260909/mcmodel-large-pic-aarch64` (MC operators, lld relocations, codegen, driver; RFC draft) |
| LLVM RISCV | `/src/steleman/programming/llvm-mcmodel-large/20260909/mcmodel-large-pic-riscv` (prototype behind `-riscv-large-pic`), `mcmodel-large-eh-riscv` (8-byte EH encodings) and `mcmodel-large-jt-riscv` (jump tables in the function's section under the large model) |

See [BINUTILS-README-MCMODEL-LARGE](BINUTILS-README-MCMODEL-LARGE.txt) in this directory for the original plain-text notes.

