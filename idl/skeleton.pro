function mkhex,x,y,d,f,a
pts=dblarr(6,2)
pts(0,0)=x+d
pts(0,1)=y+d



return,pts
end

function skeleton,img
tvscl,img
d=10
f=1
x=100
y=100
while 1 eq 1 do begin
    pts=mkhex(x,y,d,f)
    plots,/device

end
return,sk
end