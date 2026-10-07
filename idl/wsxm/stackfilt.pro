function stackfilt,t,n
if not(keyword_set(n)) then n=4
;filters using dezofilter along the first coord
nt=t(0:-2,*,*)
s=size(t)
x=dindgen(s(1))
for i=0,s(2)-1 do for j=0,s(3)-1 do begin
	res=dezofilter(x,reform(t(*,i,j)),width=n)
	nt(*,i,j)=res
end 

return,nt
end
