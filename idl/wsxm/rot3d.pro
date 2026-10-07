function rot3d,stack,ang,fast=fast,accel=accel
;rotates by the first axis
s=size(stack)
rst=stack
trg=lonarr(s(1))
if keyword_set(fast) then interp=0 else interp=1
if keyword_set(accel) then begin
    for i=0,s(1)-1 do trg(i)=(where(finite(stack(i,*,*))))(0)
end

;print,trg

for i=0,s(1)-1 do $
    if trg(i) ne -1 then rst(i,*,*)=rot(reform(stack(i,*,*)),ang,interp=interp,missing=(-0./0.))


return,rst
end
