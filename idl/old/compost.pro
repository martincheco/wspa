function composit,img1,img2,width
;overlays two RGB images
img1=img1(0:2,*,*)
img2=img2(0:2,*,*)

s1=size(img1)
s2=size(img2)
;if s1 ne s2 then return,0
img=img1(0)*intarr(s1(2)*2-width,s1(3))
mask=img*0
find=findgen(width)/width
minimask=mreplicate(find,s1(3))

part1=1L*img1(*,0:s1(2)-1-width,*)
part2=1L*img2(*,width:*,*)

help,part1
help,part2

part31=1.*img1(*,s1(2)-width:*,*)
part32=1.*img2(*,0:width-1,*)

for i=0,2 do begin
part31(i,*,*)=(part31(i,*,*)*(1-minimask))
part32(i,*,*)=(part32(i,*,*)*(minimask))
end

help,part31
help,part32
part3=round((part32+part31))

img=bytarr(3,s1(2)+s2(2)-width,s1(3))
img(*,0:s1(2)-1-width,*)=part1
help,img
s=size(img)
help,s(2)-s1(2)
img(*,s1(2):*,*)=part2
print,s1(2)-1-width-s1(2)+1

img(*,s1(2)-width:s1(2)-1,*)=part3

help,img
return,img
end


pro compost,w
a=dialog_pickfile()
b=dialog_pickfile()
aa=read_png(a)
bb=read_png(b)
help,aa
help,bb
s1=size(aa)
s2=size(bb)
if s1(3) ne s2(3) then begin
    mx=max([s1(3),s2(3)])
    f1=mx/s1(3)
    f2=mx/s2(3)
    aa=congrid(aa,3,f1*s1(2),mx,cubic=-0.3)
    bb=congrid(bb,3,f2*s2(2),mx,cubic=-0.3)
end
help,aa
help,bb
t=composit(aa,bb,w)
tv,t,true=1
f=file_dirname(a)+"/"+file_basename(a,".png")+"_vs_"+file_basename(b,".png")+".png"
print,f
write_png,f,t
end

