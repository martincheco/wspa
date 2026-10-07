function rd_int_img,f,x,y ;function reads a binary datafile

if not(keyword_set(f)) then $
f = dialog_pickfile(/read, /must_exist, filter = '*.t**')

if not(keyword_set(x)) or not(keyword_set(y)) then $
begin
x=400
y=400
end
print,'Reading file:',f
openu,1,f;,/big_endian
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
