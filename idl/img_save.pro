function img_save, f, img, grey=grey,no_save=no_save,typ=typ
if not(keyword_set(typ)) then typ='png'
tvlct,r,g,b,/get
print,'Saving:', f
s=size(img)
ri=img
gi=img
bi=img

for i=0, 255 do begin
ind=where(img eq i)

if ind(0) ne -1 then begin
ri(ind)=r(i)
gi(ind)=g(i)
bi(ind)=b(i)
end
end


a=intarr(3,s(1),s(2))
a(0,0:s(1)-1,0:s(2)-1)=ri(0:s(1)-1,0:s(2)-1)
a(1,0:s(1)-1,0:s(2)-1)=gi(0:s(1)-1,0:s(2)-1)
a(2,0:s(1)-1,0:s(2)-1)=bi(0:s(1)-1,0:s(2)-1)

if typ eq 'tiff' then begin
img=reverse(img,2)
if not(keyword_set(no_save)) then $
if keyword_set(grey) then write_tiff, f ,img else $
write_tiff, f , 1, red=ri,green=gi,blue=bi, planarconfig=2
end else begin
if not(keyword_set(no_save)) then $
if keyword_set(grey) then write_png, f ,img else $
write_png, f, img, r,g,b
end
return,a
end