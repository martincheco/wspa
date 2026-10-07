pro currmaps,f

n=n_elements(f)

for i=0,n-1 do begin
	a=loadnanonis(f(i))
	aa=a.img
	;current images
	curr=0.5*(shift(aa(*,*,8),0)+shift(aa(*,*,9),0))
	offs=-8.6E-14;mmean(dats(2:10,2:10))
	curr=curr-offs
	

	;laser lockin signal
	inp2x=0.5*(shift(aa(*,*,2),-3)+shift(aa(*,*,3),2))
	inp2y=0.5*(shift(aa(*,*,4),-3)+shift(aa(*,*,5),2))
	inp2=inp2x
	;dIdV lockin signal
	didv=0.5*(shift(aa(*,*,12),-2)+shift(aa(*,*,13),1))
	;APD signal
	;apd=shift(aa(*,*,16),-0)+shift(aa(*,*,17),0)
	
	unit='unit'
	bias=getval(a.par,'Bias:',unit=unit)
;	ii=string(i+1,format='(I03)')
	ii=file_basename(f(i),'.sxm')
	sbias=strtrim(string(bias,'(F-5.2)'),2)
	print,ii
	az=a.zunit
	slicewsxm,ii+'_'+sbias+'V.ch1.f',curr,xdim=a.xsize,ydim=a.ysize,zunit=az(8),bias=bias*1e3,chan='Current'
	writefilt,ii+'_'+sbias+'V.ch1.f.flt',curr,'current'

	slicewsxm,ii+'_'+sbias+'V.ch2.f',inp2,xdim=a.xsize,ydim=a.ysize,zunit=az(2),bias=bias*1e3,chan='lasermod'
	writefilt,ii+'_'+sbias+'V.ch2.f.flt',inp2,'lasermod'
	slicewsxm,ii+'_'+sbias+'V.ch3.f',didv,xdim=a.xsize,ydim=a.ysize,zunit=az(12),bias=bias*1e3,chan='dIdV'
	writefilt,ii+'_'+sbias+'V.ch3.f.flt',didv,'dIdV'
;	slicewsxm,ii+'_'+sbias+'V.ch4.f',apd,xdim=a.xsize,ydim=a.ysize,zunit=az(14),bias=bias*1e3,chan='APD'


end

end

pro writefilt,f,dats,chan
mx=max(abs(dats))
	openw,1,f


	if chan eq 'current' then begin
		;		mx=max(abs(ftgauss(dats,0.7,0.7,1)))
	;	mna=-8.5706E-11
	;	mxa=1.7236E-10
;		mna=-2.7226E-12
;		mxa=6.5020E-12
;		mid=-mna/(-mna+mxa)
		
		mx=max(ftgauss(dats,0.77,0.9,1))
		mn=min(ftgauss(dats,0.77,0.9,1))
		
;		if (mx) ge (-mn) then begin
;			mnr=mna*mx/mxa
;			mxr=mx
;		end else begin
;			mnr=mn
;			mxr=mxa*mn/mna
;		end
		mid=((-mn)/(mx-mn))
		mnr=mn
		mxr=mx


		printf,1,'ftgauss 0.77 0.9 1'
		printf,1,'rebin 4'
;		printf,1,'histxpand'+string(mnr)+string(mxr)+" 1"
		if mn gt 0 and mx gt 0 then begin
			printf,1,'color -1'
			printf,1,'histxpand'+string(0)+string(mxr)+" 1"
		end
		if mn lt 0 and mx gt 0 then printf,1,'color -34 '+string(mid)+' -1'

		if mn lt 0 and mx lt 0 then begin
			printf,1,'color -34'
			printf,1,'histxpand'+string(mnr)+string(0)+" 1"
		end
	end

	if chan eq 'lasermod' then begin
		mna=-1.0373E+00
		mxa=2.2347E+00
	;	mna=-9.4244E+02
	;	mxa=1.5168E+03
		mid=-mna/(-mna+mxa)
		
		mx=max((dats))
		mn=min((dats))
		
		mid=((-mn/(-mn+mx))>0.002)<0.998
		if (mx) ge (-mn) then begin
			mnr=mna*mx/mxa
			mxr=mx
		end else begin
			mnr=mn
			mxr=mxa*mn/mna
		end
		mnr=mn
		mxr=mx
		mid=-mn/(-mn+mx)	
		
		printf,1,'rebin 4'
		printf,1,'histxpand'+string(mnr)+string(mxr)+" 1"
		printf,1,'color -25 '+string(mid)+' 23'
	end


	if chan eq 'dIdV' then begin
		mx=max(abs(dats))
		printf,1,'rebin 4'
		printf,1,'histxpand'+string(-mx)+string(mx)+" 1"
		printf,1,'color -30 0.5 30'
	end

	close,1



end
