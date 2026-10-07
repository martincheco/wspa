pro profiler,arr

s=size(arr)
for i=0,s(1)-1 do begin
	p=mprofile(reform(arr(i,*,*)),0,200,200,0,latscl=200./256.*1.5)
	nm=string(i,format='(I03)')
	openw,1,nm+'.txt'
	for k=0,n_elements(p.r)-1 do printf,1,p.r(k),p.z(k)
	close,1	
end



end
