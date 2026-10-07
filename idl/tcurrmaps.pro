pro tcurrmaps,f

n=n_elements(f)

for i=0,n-1 do begin
	a=loadtxt(f(i))
	curr=a.img

	az=a.zunit
	writefilt,f(i)+'.flt',curr

end

end

pro writefilt,f,dats
	openw,1,f
		lim=1E-12

		;mx=max(ftgauss(dats,0.25,0.25,1))
		;mn=min(ftgauss(dats,0.25,0.25,1))
		mx=double(max(dats))
		mn=min(dats)
		md=mmean(double(dats(*,0:10)))
		print,md
		mid=((-mn)/(mx-mn))
		mnr=mn
		mxr=mx


		;printf,1,'ftgauss 0.25 0.25 1'
		printf,1,'rotate 1 0 0'
		;printf,1,'rebin 4'
		if mn gt -lim and mx gt lim then begin
			printf,1,'color -1.0 0 0'
		end
		if mn lt -lim and mx gt lim then printf,1,'color -34.0 '+string(mid)+' -1.0'

		if mn lt -lim and mx lt lim then begin
			printf,1,'color -34.0 0 0'
		end

	close,1



end
