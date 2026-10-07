function matrixexp,f
f=dialog_pickfile()
openu,1,f
c=100
b=bytarr(c)
cc=0
a=0B
while ~ EOF(1) and cc lt (c-1) do begin
readu,1,a
b(cc)=a
cc=cc+1
end
close,1
return,b
end
