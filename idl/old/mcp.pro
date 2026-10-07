pro panacci
p=[1,2,5,10]
n=n_elements(p)-1
q=p*0
c=0
l=0
print,'***',p,q

while (total(p) gt 0) or (l lt 30) do $

begin
;cesta tam
i=fix(randomu(4))
j=fix(randomu(4))

if (p[i] ne 0) or (p[j] ne 0) then $ ;jeden clen je nenulovy
	begin
		q[i]=p[i] ;prehazovani do druhyho pole
		q[j]=p[j]
		p[i]=0
		p[j]=0
		l=l+max([q[i],q[j]]) ;kolik to da
		print,'-->',p,q,'Duration:',l
	end
	
if q[i] ne 0 then $ ;jeden nenulovy
	begin
		p[i]=q[i] ;prehazovani do druhyho pole
		p[j]=q[j]
		q[i]=0
		q[j]=0
		l=l+max([q[i],q[j]]) ;kolik to da 
		print,'<--',p,q,'Duration:',l
	end

end

if total(p) eq 0 then print,"!!!",p,q,'Duration',l else print,"XXX",p,q,l

end
