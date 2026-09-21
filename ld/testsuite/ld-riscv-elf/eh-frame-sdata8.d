#name: 8-byte PC-relative FDE locations with merged CIEs
#source: eh-frame-sdata8-1.s
#source: eh-frame-sdata8-2.s
#as: -march=rv64i -mabi=lp64
#ld: -melf64lriscv --relax -e func1 -Ttext=0x10000
#readelf: -wf

#...
0+0018 0+001c 0+001c FDE cie=0+0000 pc=0+10000..0+10008
#...
0+0038 0+0018 0+003c FDE cie=0+0000 pc=0+1000c..0+10014
#pass
