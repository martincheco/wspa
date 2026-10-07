; zkonvertuje integer image v souboru na long,
;predpokladajice, ze ma 400x400pixelu, ulozi jej s priponou .l
pro con2long,f

if not(keyword_set(f)) then $
f = dialog_pickfile(/read, /must_exist, filter = '*')


openr,1,f,/swap_if_little_endian
status=fstat(1)
print, status.size/2
a=intarr(status.size/2)
b=intarr (status.size/2+2)
readu,1,a
b(2:*)=a(0:*)
b(0)=400
b(1)=400
close,1

openw,1,f+'.l'
writeu,1,long(b)
close,1

end


pro con2lon,f,x,y

if not(keyword_set(f)) then $
f = dialog_pickfile(/read, /must_exist, filter = '*')


openr,1,f,/swap_if_little_endian
status=fstat(1)
print, status.size/2
a=intarr(status.size/2)
b=intarr (status.size/2+2)
readu,1,a
b(2:*)=a(0:*)
b(0)=x
b(1)=y
close,1

openw,1,f+'.l'
writeu,1,long(b)
close,1

end


;nacte ze souboru image (mXX_ori.tXX)
function rd_int_img,f,x,y

if not(keyword_set(f)) then $
f = dialog_pickfile(/read, /must_exist, filter = '*.t**')

if not(keyword_set(x)) or not(keyword_set(y)) then $
begin
x=400
y=400
end

openr,1,f,/swap_if_little_endian
status=fstat(1)
print,status.size
if (long(status.size/2) ge long(x*y)) then $
begin
a=intarr(x,y)
readu,1,a
end
print,f
close,1

return,a

end


pro gentif,img,f,i=i, view=view;i znaci inverzi, f jmeno souboru a img kyzeny obrazek

if keyword_set(i) then img=-img

img=bytscl(img)
ad=[[[img]],[[img]],[[img]]]
ad=transpose(ad,[2,0,1])

if keyword_set(view) then begin
s=size(img)
loadct,0
window,1, xsize=s(1), ysize=s(2)
wset,1
tv,ad,/true
end

if not(keyword_set(f)) then $
f = dialog_pickfile(/write, filter = '*.tif')
tiff_write,f,ad

end


pro long2tif, f ,g

if not(keyword_set(f)) then $
f = dialog_pickfile(/read, /must_exist, filter = '*')

openr,1,f
status=fstat(1)
print, status.size/4
a=lonarr(2)
readu,1,a
print,a
b=lonarr(a(0),a(1))
readu,1,b
close,1

gentif,b,g

end



pro show,f,rot,tilt
openr,1,f
status=fstat(1)
print, status.size/4
a=lonarr(2)
readu,1,a
print,a
b=lonarr(a(0),a(1))
readu,1,b
close,1
goldpalette,/pure
loadct,0
window,1,xsize=400, ysize=400
;shade_surf,congrid(b,400,400, cubic=-0.5),ax=tilt,az=rot
tv,(bytscl(congrid(b,400,400,cubic =-.5)))
end

function readlong,f
if not(keyword_set(f)) then $
f = dialog_pickfile(/read, /must_exist, filter = '*')

openr,1,f
status=fstat(1)
print, status.size/4
a=lonarr(2)
readu,1,a
print,a
b=lonarr(a(0),a(1))
readu,1,b
close,1

return,B
end


pro swaplong,f
if not(keyword_set(f)) then $
f = dialog_pickfile(/read, /must_exist, filter = '*')

openr,1,f,/swap_endian
status=fstat(1)
print, status.size/4
a=lonarr(status.size/4)
readu,1,a
close,1

openw,1,f+'.s'
writeu,1,a
close,1

end
pro saveu,b,f
if not(keyword_set(f)) then $
f = dialog_pickfile(/write, filter = '*')
openw,1,f
writeu,1,b
close,1
end

pro savelong,img,f
s=size(img)
imgg=lonarr(n_elements(img)+2)
print,long(s(1)),long(s(2))
imgg(0)=long(s(1))
imgg(1)=long(s(2))
imgg(2:*)=img

if not(keyword_set(f)) then $
f = dialog_pickfile(/write, filter = '*')
print,f
openw,1,f

writeu,1,imgg

close,1

end
