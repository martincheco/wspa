function FePc_NG
a=read_png('/home/martin/sync/data/FePC/distortions/comparison2_G.png')
b=read_png('/home/martin/sync/data/FePC/distortions/comparison2_NG.png')
aa=reform(a(1,*,*))
bb=reform(b(1,*,*))
help,aa
help,bb

d=distort(stuff(bb,1.2),stuff(aa,1.2),3,15,17,/draw)


return,d
end
