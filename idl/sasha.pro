pro sasha,f,df=df,exc=exc,sh=sh

;sh is shift

a=loadnanonis(f)
aa=a.img

if not(keyword_set(sh)) then sh=4 ;implicit fwd-bwd offset

;extract force

ff=reform(aa(*,*,12))
fb=shift(reform(aa(*,*,13)),sh)

;extract dissipation

ef=reform(aa(*,*,14))
eb=shift(reform(aa(*,*,15)),sh)

sh=abs(sh)
ff=ff(sh:-sh,*)
fb=fb(sh:-sh,*)
ef=ef(sh:-sh,*)
eb=eb(sh:-sh,*)

help,ef
s=size(ef)

ec=bytarr(3,s(1),s(2))
fc=bytarr(3,s(1),s(2))

print,s

help,reform(ef,s(1),s(2))


ec(0,*,*)=bytscl(reform(ef,1,s(1),s(2)))
ec(1,*,*)=bytscl(reform(eb,1,s(1),s(2)))
fc(0,*,*)=bytscl(reform(ff,1,s(1),s(2)))
fc(1,*,*)=bytscl(reform(fb,1,s(1),s(2)))


device,decomposed=1
tvscl,fc,/true
tvscl,ec,256,0,/true
df=(ff+fb)/2.
exc=(ef+eb)/2.

dfmin=fltarr(s(2))
dfmax=fltarr(s(2))
dfavg=fltarr(s(2))

emax=fltarr(s(2))
emin=fltarr(s(2))
edfmin=fltarr(s(2))
ii=intarr(s(2))

smexc=ftgauss(exc,.1)

for row=0,s(2)-1 do begin
	w=where(smexc(*,row) eq max(smexc(*,row)))
print,w(0)
	dfmin(row)=min(df(*,row))
	dfmax(row)=max(df(*,row))
	dfavg(row)=mmean(df(*,row))
	emin(row)=min(exc(*,row))

	emax(row)=max(exc(*,row))
	edfmin(row)=df(w(0),row)
	ii(row)=w(0)
	df(w(0),row)=0
end

openw,1,f+'.dat',width=1024
printf,1,'edfmin	','dfmin	','dfmax	','dfavg	','emin	','emax	','column'
for row=0,s(2)-1 do begin
	printf,1,edfmin(row),dfmin(row),dfmax(row),dfavg(row),emin(row),emax(row),ii(row)
end
close,1

window,1
q=64000D
plot,-4*!PI*q*(edfmin-dfavg)/((emax-emin)/emin)
wset,0
end


pro sasha2,f,df
s=size(df)

window,1,xs=800,ys=400

for i=0,s(2)-1,10 do begin
	
	plot,df(*,i),yrange=[-0.7,-0.3],ys=1
	a=tvrd(0)
	write_png,f+string(i,format='(I03)')+'.png',a
end

end
