pro rmdriftwsxm,st=st
fixangle=0 ;fix the angle =1
;here will be an option to load a vectorset, for now it is hexagonal
r3=3.^0.5/2.
matrix=[[r3,0.5],[r3,-0.5]]
data=loadwsxm()
if n_tags(data) eq 0 then return
olds=size(data.img)
;if n_elements(data.img) le 1 then return
imf=unidrift(data.img,matrix,/recut)

s=size(imf)
;help,data.xsize

data.xsize=data.xsize*s(1)/olds(1)
data.ysize=data.ysize*s(2)/olds(2)
;help,olds(1)
;help,data.xsize
savewsxm,refitwsxm(data,imf)

st=refitwsxm(data,imf)

end