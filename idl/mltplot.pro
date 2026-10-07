pro mltplot,basei=basei,trans=trans


whch=[1,8,6,7,5]

g=getfiles(mask='Bias*.dat')
a=loadnanonis_sts(g(0))
tt=sts_toarea(g)
if keyword_set(trans) then t=transpose(tt,[0,2,1]) else t=tt
;window,1,xsize=600,ysize=1024
n=n_elements(whch)

!P.Multi = [0, 1, n]
s=size(t)
if not(keyword_set(basei)) then basei=0
print,s
set_plot,'ps'
Device, DECOMPOSED=0, COLOR=1, BITS_PER_PIXEL=8
device, filename='test_plot.ps'
device,XSIZE=4, YSIZE=10, /INCHES
device,/encapsulated
device,xoffset=0

xx=t(basei,0,*)
;xx=findgen(s(1))

un=getunit(a.chans(basei))
help,un
xx=axred(xx,un)
xttl=replunit(a.chans(basei),un)

for i=0,n-1 do begin
	yun=getunit(a.chans(whch(i)))
	yy=reform(axred(t(whch(i),*,*),yun))
	yttl=replunit(a.chans(whch(i)),yun)
	xmx=max(xx)
	xmn=min(xx)
	ymn=min(yy)
	ymx=max(yy)
	loadct,0
	plot,xx,yy(0,*),xtit=xttl,ytit=yttl,$
		xst=1,yst=1,xrange=[xmn,xmx],yrange=[ymn,ymx],charsize=1.5,xmargin=[15,2],color=0
	loadct,13
	for j=1,s(2)-1 do begin
		oplot,xx,yy(j,*),color=255*j/s(2)
	end
end

device,/close
end
