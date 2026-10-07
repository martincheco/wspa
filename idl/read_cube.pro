function read_cube,f
;reads cubefile
;values for dimensions and offset experimental
if not(keyword_set(f)) then f=dialog_pickfile(/must_exist)

hdr=strarr(6)

openr,1,f
readf,1,hdr


print,hdr

h1=float(strsplit(hdr(2)," ",/ext))
h2=float(strsplit(hdr(3)," ",/ext))
h3=float(strsplit(hdr(4)," ",/ext))
h4=float(strsplit(hdr(5)," ",/ext))


m=long(h2(0))
l=long(h3(0))
k=long(h4(0))

print,k,l,m

natoms=h1(0)
help,natoms
atoms=fltarr(5,natoms)
xdim=h4(3)
ydim=h3(2)
zdim=h2(1)


xoffs=h1(3)
yoffs=h1(2)
zoffs=h1(1)

aaa=fltarr(k,l,m)


readf,1,atoms


readf,1,aaa

print,aaa(0:10)
close,1

help,aaa
print,k*l*m
data=reform(aaa,k,l,m)

return,{data:data,atoms:atoms,zheader:hdr,xdim:xdim,ydim:ydim,zdim:zdim,xoffs:xoffs,yoffs:yoffs,zoffs:zoffs}
end



