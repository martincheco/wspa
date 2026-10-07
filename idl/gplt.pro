function gplt

d=getfiles(/dirs)
n=n_elements(d)
q=dblarr(n)
k=q
p=q
im=ptrarr(n)

for i=0,n-1 do begin
	kq=strsplit(file_basename(d(i)),'Q|K',/regex,/extract)
	k(i)=kq(0)
	q(i)=kq(1)
	
	img=0;read_png(d(i)+'/a_overview.png')
	im(i)=ptr_new(img)
	pars=read_file(d(i)+'/params.txt',/array)
	help,pars
	p(i)=getval(pars,'Pearson:','flt')

end
help,p

;q=reform(q,3,9)
;q(*,0:3)=reverse(q(*,0:3),2)
;k=reform(k,3,9)
;k(*,0:3)=reverse(k(*,0:3),2)
;p=reform(p,3,9)
;p(*,0:3)=reverse(p(*,0:3),2)
mi=multisort(k,q)

im=im(mi)
k=k(mi)
q=q(mi)
p=p(mi)
help,mi
help,p
ii=n_elements(uniq(q(sort(q))))
jj=n/ii

p=reform(p,ii,jj)
k=reform(k,ii,jj)
q=reform(q,ii,jj)
im=reform(im,ii,jj)

openw,1,'gplt.dat'
for i=0,ii-1 do begin
	for j=0,jj-1 do printf,1,k(i,j),q(i,j),p(i,j)
	printf,1,''
end
close,1

return,{k:q,q:k,p:p,im:img}
end
