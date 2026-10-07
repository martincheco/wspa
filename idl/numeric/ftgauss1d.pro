function ftgauss1d,f,mm,edge_wrap=edge_wrap
;filter that applies arbitrary gaussian kernel
;min value 1
;edge_wrap tries to extend edges correctly
s=size(f)
n=s(1)
if not(keyword_set(mm)) then m=1 else m=(mm>1)<n

;print,m,n

kernel = gauss1d(s(1),floor(s(1)/2),n/m)

kernel=shift(kernel,floor(s(1)/2))


mf=fft(f,1)
mf=(mf)*kernel        
mf=real_part(fft(mf,-1))

return,mf

end
