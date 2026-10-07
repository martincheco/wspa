pro qconvert
f=dialog_pickfile()
a=read_ascii(f,data_start=3)
aa=a.field1(2,*)
aaa=reform(aa,61,61)
aaa=aaa(0:19,0:19)
tvscl,[[aaa,aaa,aaa],[aaa,aaa,aaa],[aaa,aaa,aaa]]
aaa=reform(aaa,400)

openw,1,f+'.p'
for i=0,399 do printf,1,aaa(i)
close,1
end


