function rd_int_raw,f ;function reads a raw datafile with header

if not(keyword_set(f)) then $
f = dialog_pickfile(/read, /must_exist, filter = '*.raw')

openr,1,f;,/swap_if_little_endian
x=0
y=0
;mn=1E-1
;mx=1
readf,1,x
readf,1,y 
readf,1,mn
readf,1,mx
print, x,y,mn,mx
im=uintarr(x,y)
readu,1,im
img=float(im)/65535.*(mx-mn)+mn
close,1
return,img
end
