function xmld_read,f

if keyword_set(f) then $
	a=read_ascii(f,data_start=1) $
	else a=read_ascii(data_start=1)


aa=double(a.(0))

e=aa(0,*)
;total yield
t=(aa(3,*))
;partial yield
p=(aa(10,*))
m=(aa(2,*))

return,{e:e,t:t,p:p,m:m}
end

pro write_xy,f,x,y
openw,1,f
for i=0,n_elements(x)-1 do $
	printf,1,x(i),y(i)
close,1
end


function xmld_norm,st,lin=lin,nrm=nrm,lo=lo,hi=hi,disp=disp
;lin - position where a const. bkg is subtracted
;nrm - position where a normalization should be done
;lo,hi - applied limits

e=st.e
p=st.p
t=st.t


if keyword_set(lo) then begin
	d=abs(e-lo)
	w=where(d eq min(d))
	if w(0) ne -1 then begin
		e=e(w(0):*)
		p=p(w(0):*)
		t=t(w(0):*)
	end
end


if keyword_set(hi) then begin
	d=abs(e-hi)
	w=where(d eq min(d))
	if w(0) ne -1 then begin
		e=e(0:w(0))
		p=p(0:w(0))
		t=t(0:w(0))
	end
end




if keyword_set(lin) then begin
	d=abs(e-lin)
	w=where(d eq min(d))
	if w(0) ne -1 then begin
		p=p-p(w(0))
		t=t-t(w(0))
	end
end


if keyword_set(nrm) then begin
	d=abs(e-nrm)
	w=where(d eq min(d))
	if w(0) ne -1 then begin
		p=p/p(w(0))
		t=t/t(w(0))
	end
end

if keyword_set(disp) then begin
	plot,e,t,yrange=[min([t,p]),max([t,p])],yst=1,background=255,color=0
	oplot,e,p,color=200
end
return,{e:e,t:t,p:p}
end


pro xmld,nrm=nrm,lin=lin,lo=lo,hi=hi,f=f,png=png,sav=sav
;lin - subtracts const. bkg at specified energy (neares e)
;nrm - normalization at the specified energy (nearest e)
;png - saves png graph
;sav - saves data (total, partial, after all the filters)
if not(keyword_set(f)) then f=dialog_pickfile(/must_exist,/multi)

for i=0,n_elements(f)-1 do begin
	t=xmld_read(f(i))
	tt=xmld_norm(t,lin=lin,nrm=nrm,lo=lo,hi=hi,/disp)
	a=tvrd(0,true=1)
	if keyword_set(png) then write_png,f(i)+'.png',a
	if keyword_set(sav) then write_xy,f(i)+'_tey.dat',tt.e,tt.t
	if keyword_set(sav) then write_xy,f(i)+'_pey.dat',tt.e,tt.p
	



end
end
