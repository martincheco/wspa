

function read_vsage_set,f
;f are the filenames for a set of curves taken the same time
n=n_elements(f)

t=read_vsage(f(0))
if n_tags(t) ne 0 then begin
set=replicate(t,n)
end

if n gt 1 then $
for i=1,n-1 do begin
    tt=read_vsage(f(i))
    if n_tags(tt) ne 0 then $
	if n_elements(tt.(0)) eq n_elements(t.(0)) then set(i)=tt
end
return,set
end
