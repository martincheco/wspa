function stitch,t
sig=[reform(t.data(1,*)),reverse(reform(t.data(2,*)))]
return,sig
end

pro vis,npt,a,smpl=smpl

tmp=(*npt(a))
if not(keyword_set(smpl)) then smpl=1000
plot,tmp.sig(0:smpl),psym=1
oplot,1e-12*(tmp.tsig(0:smpl)*(tmp.p2-tmp.p1)+tmp.p1),color=255

print,tmp.thist.his(0:10<(n_elements(w)-1))

end

function digitize,sig,thr
print,thr
tsig=byte(sig*0)
w=where(sig gt thr)
if w(0) ne -1 then tsig(w)=1

return,tsig
end


function thist,tsig
itsig=fix(tsig)
dif=tsig(1:*)-tsig(0:-2) ;corrected 2018-08-02
w=where(abs(dif) gt 0.1)
help,w
wdif=w(1:*)-w(0:-2)
n=n_elements(wdif)
ii=lindgen(n/2)
hi=wdif(ii*2)
lo=wdif(ii*2+1)
hhi=histogram(hi,binsize=1)
hlo=histogram(lo,binsize=1)

if tsig(0) eq 0 then return,{hi:hhi,lo:hlo,his:hi,los:lo} else return,{hi:hlo,lo:hhi,his:lo,los:hi} 

end


function stp,sig
;determines step in the current (for the binsize)
sgs=sig(sort(sig))
sgs=sgs-shift(sgs,1)
sgs=sgs(1:*)
dsg=sgs(sort(sgs))
dsgd=dsg(where(dsg gt 0))
return,dsgd;d(0)
end


function fithist,h
ff=fitfunct(h.hist,'gausovky',/vis,pars=pars)
return,{hist:h.hist,loc:h.loc,fit:ff,par:pars}
end


function hhist,sig
h=histogram(sig,min=min(sig),max=max(sig),binsize=1.522D-14*8,locations=loc)
return,{hist:h,loc:loc}
end


pro savehist,f,h
x=h.loc
y=h.hist
n=n_elements(y)
openw,1,f
for i=0,n-1 do begin
	printf,1,x(i)*1e12,y(i)
end
close,1
end

pro savex,f,x
n=n_elements(x)
openw,1,f
for i=0,n-1 do begin
	printf,1,x(i)
end
close,1
end


pro savexy,f,x,y
n=n_elements(x)
openw,1,f
for i=0,n-1 do begin
	printf,1,x(i),y(i)
end
close,1
end

function makehist,f,nowr=nowr,stitch=stitch
if not(keyword_set(f)) then f=dialog_pickfile()
fn=n_elements(f)
pt=ptrarr(fn)
for j=0,fn-1 do begin
	t=loadnanonis_sts(f(j))
	if keyword_set(stitch) then sig=stitch(t) else sig=reform(t.data(1,*))
	h=hhist(sig)
	pt(j)=ptr_new({sig:sig,hist:h,file:f(j)})
	if not(keyword_set(nowr)) then savehist,f(j)+'.hist',h
end
return,pt
end


function read_fitted,f
wh=read_ascii(f)
bl=wh.(0)
s=size(bl)
n=round((s(2))/9)
ii=indgen(n)*9
pos1=reform(bl(1,ii+2))
pos2=reform(bl(1,ii+6))
amp1=reform(bl(1,ii+3))
amp2=reform(bl(1,ii+7))
wid=reform(bl(1,ii+4))
return,{a1:amp1,a2:amp2,w:wid,p1:pos1,p2:pos2}
end

function finalize,t

ft=read_fitted('fits.txt')
help,ft,/st
help,t,/st
n=n_elements(t)
npt=ptrarr(n)
openw,1,'fitpars.txt'
printf,1,"p1",ft.p1
printf,1,"p2",ft.p2
printf,1,"a1",ft.a1
printf,1,"a2",ft.a2
printf,1,"w",ft.w
close,1
	
for i=0,n-1 do begin
	print,i
	help,ft.p1(i)
	help,ft.p2(i)
	thr=1e-12*(ft.p1(i)+ft.p2(i))/2.
	sig=(*t(i)).sig
	hist=(*t(i)).hist
	file=(*t(i)).file
	tsig=digitize(sig,thr)
	th=thist(tsig)	
	savex,file+'.tlo',th.lo
	savex,file+'.thi',th.hi
	
npt(i)=ptr_new({file:file,sig:sig,tsig:tsig,hist:hist,thist:th,a1:ft.a1(i),a2:ft.a2(i),w:ft.w(i),p1:ft.p1(i),p2:ft.p2(i)})
end


return,npt
end

pro events,f

ns=lonarr(n_elements(f))

for i=0,n_elements(f)-1 do begin
	print,f(i)
	a=read_ascii(f(i))
	aa=a.(0)
	ns(i)=total(aa)
	print,ns(i)
end

openw,1,'N_events.dat'
for i=0,n_elements(f)-1 do printf,1,ns(i)

close,1

end


function extract_events,t
n=n_elements(t)

npt=ptrarr(n)
for i=0,n-1 do begin
	print,i
	sig=(*t(i)).sig
	hist=(*t(i)).hist
	thr=mmean(sig)
	file=(*t(i)).file
	tsig=digitize(sig,thr)
	th=thist(tsig)	
	savex,file+'.tlo',th.lo
	savex,file+'.thi',th.hi
	
npt(i)=ptr_new({file:file,sig:sig,tsig:tsig,hist:hist,thist:th})
end

return,npt

end
