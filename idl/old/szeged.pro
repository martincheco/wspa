function rd_szgd_stm, f
img=bytarr(256,256)
info=bytarr(512+256)
openr,1,f
readu,1,info
readu,1,img
close,1
info(where(info lt 1))=32
print,f,string(info)
return,img
end


function auto_process, f
if not(keyword_set(f)) then f = dialog_pickfile(/read, /must_exist, /multiple_files)
b=intarr(n_elements(f),256,256)

for i=0,n_elements(f)-1 do $
begin
a=rd_szgd_stm(f(i))
b(i,*,*)=hist_equal(rowsequal(a))
end
return,b
end

pro conv2tiff,f
if not(keyword_set(f)) then f = dialog_pickfile(/read, /must_exist, /multiple_files)

tvlct,redx,greenx,bluex,/get
goldpalette,/pure
tvlct,red,green,blue,/get
for i=0,n_elements(f)-1 do $
begin
a=rd_szgd_stm(f(i))
b=hist_equal(rowsequal(a))
fd=f(i)
strput,fd,'.tif',strpos(fd,'.IMG')


write_tiff, fd, b, 1, red = red, green = green, blue = blue
end
tvlct,redx,greenx,bluex
end



