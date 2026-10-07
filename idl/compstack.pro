function cs_th,at=at,dirnm=dirnm
resolve_routine,'genslice'
drs=getfiles('.',/dirs)
n=n_elements(drs)

dirnm=drs
thp=ptrarr(n)
;print,drs
for i=0,n-1 do begin
	th=xsf_read(drs(i)+'OutFz.xsf')
	s=size(th)
	th=giessibl(reverse(1.60217*1e-9*th.data,1),n=14,dz=5e-12,k=1e6,f0=1e6,/ext)
	thp(i)=ptr_new(th)
end

return,thp
end

pro cs_totplt,th,ii
n=n_elements(ii)
s=size(*th(0))
oplot,total(total((*th(0)),3,/double),2,/double)/double(s(2))/double(s(3)),color=255


for i=1,n-1 do oplot,total(total((*th(i)),3,/double),2,/double)/double(s(2))/double(s(3)),color=255



end
