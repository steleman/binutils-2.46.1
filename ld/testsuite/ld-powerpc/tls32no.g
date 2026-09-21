#source: tls32.s
#source: tlslib32.s
#as: -a32
#ld: --no-tls-optimize
#objdump: -sj.got
#target: powerpc*-*-*

.*

Contents of section \.got:
#pass
