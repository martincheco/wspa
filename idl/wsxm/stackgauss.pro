function stackgauss,t,n
;filters using dezofilter along the first coord
s=size(t)
nt=t


kernel = gauss1d(s(1),floor(s(1)/2),s(1)/n)

kernel=shift(kernel,floor(s(1)/2))


for i=0,s(2)-1 do for j=0,s(3)-1 do begin
	mf=fft(reform(t(*,i,j)),1)
	mf=(mf)*kernel        
	mf=real_part(fft(mf,-1))
	
	nt(*,i,j)=mf
end 



return,nt
end
