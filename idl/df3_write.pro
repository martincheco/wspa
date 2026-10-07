pro df3_write,f,st
;writes the povray df3 file, using bytes
if not(keyword_set(f)) then f=dialog_pickfile()
stt=transpose(st,[1,0,2])
s=size(stt)
print,uint(s)
openw,1,f
writeu,1,swap_endian(uint(s(1)))
writeu,1,swap_endian(uint(s(2)))
writeu,1,swap_endian(uint(s(3)))
writeu,1,swap_endian(bytscl(stt))

close,1
end
