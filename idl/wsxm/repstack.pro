function repstack,st,rep,dim
;replicates a 3D array along the specified dimension
s=size(st)
if dim eq 1 then begin
nw=dblarr(rep*s(1),s(2),s(3))
for i=0,rep-1 do nw(i*s(1):(i+1)*s(1)-1,*,*)=st
end
if dim eq 2 then begin
nw=dblarr(s(1),rep*s(2),s(3))
for i=0,rep-1 do nw(*,i*s(2):(i+1)*s(2)-1,*)=st
end
if dim eq 3 then begin
nw=dblarr(s(1),s(2),rep*s(3))
for i=0,rep-1 do nw(*,*,i*s(3):(i+1)*s(3)-1)=st
end

return,nw
end