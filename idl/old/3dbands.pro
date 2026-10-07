function read_bands,f

band={ek:fltarr(101,300,226),wk:fltarr(101,300,226),kx:fltarr(101,300),ky:fltarr(101,300)}

for i=0,100 do begin
	f=string(i,format='(I04)')
	k=read_ascii(f+'.kpts',data_start=1)
	dkx=k.(0)(0,*)
	dky=k.(0)(0,*)
	band.kx(i,*)=dkx
	band.ky(i,*)=dky

	ek=read_ascii(f+'.ek')
	dek=ek.(0)
	help,dek
	s=size(dek)
	
	band.ek(i,*,0:s(2)-1)=dek

	wk=read_ascii(f+'.wk')
	dwk=wk.(0)
	band.wk(i,*,0:s(2)-1)=dwk
	print,f
end

return,band
end