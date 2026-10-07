pro savegnuplot,f,sl
s=size(sl)

openw,1,f,width=16*s(1)
for i=0,s(2)-1 do printf,1,sl(*,i)
close,1

end
