
function stackfold,t
s=size(t)
n=indgen(s(2)/2)*2
print,n
tt=(t(*,n,*,*)+t(*,n+1,*,*))/2

return,tt
end
