function hextrans,buf

x=float(buf(*,0,*))
y=float(buf(*,1,*))

xx=x+0.5*y
yy=(3^0.5)/2*y
buff=float(buf)
buff(*,0,*)=xx
buff(*,1,*)=yy

return,buff
end


function gen_vects,dim
ix=lindgen(long(dim)^2)
ii=ix/dim
jj=ix mod dim

return,[[ii],[jj]]
end

function hexdist,vect

distvect=vect(*,0)^2+vect(*,1)^2+vect(*,1)*vect(*,0)

return,distvect
end

function csdist,vect
distvect=vect(*,0)^2+vect(*,1)^2
return, distvect
end

function selpts,a,cnt,lim,hex=hex,verbose=verbose
if keyword_set(hex) then c=hexdist(a) else c=csdist(a)
res=lonarr(n_elements(c),2,cnt>2)
a=a(sort(c),*)
c=c(sort(c))
i=0L
j=0L
repeat begin
	w=where(c eq c(i))
	if w(0) ne -1 then $
		if n_elements(w) eq cnt then begin
		if keyword_Set(verbose) then begin
			print,c(w(0))
			print,a(w,0)
			print,a(w,1)
		end
		res(j,0,*)=reform(a(w,0))
		res(j,1,*)=reform(a(w,1))
		j=j+1
		i=i+cnt-1
		end

	i=i+1
endrep until i gt n_elements(c)-2
if j ne 0 then return,transpose(res(0:j-1,*,*)) else return,-1

end

pro coincidence,dim,factor
;calculates rotational coincidences of two hexagonal systems
;records indices of the coincident points
;evaluates the multiplicity

v=gen_vects(dim)
vv=hexdist(v)
vv=vv(sort(vv))
vvv=vv(uniq(vv))
d1=double(vvv)^0.5
d2=d1*factor

;now crawl the d1 and d2 arrays and find the coincidences within some range
range=0.1
ixs=crawl(d1,d2,range)


;evaluate the angles
for i=0,n_elements(ixs)-1 do begin
	i1=where(vv eq vvv(ixs(i,0)))
	i2=where(vv eq vvv(ixs(i,1)))
	v1=v(i1)
	v2=v(i2)
;	baseangle=
;	rotangle=
;	angle=rotangle-baseangle
end




end


pro drawpts,x,y,col,dim,hex=hex
x=double(reform(x,n_elements(x)))
y=double(reform(y,n_elements(y)))
if keyword_set(hex) then r=x^2+y^2+x*y else r=x^2+y^2

w=where(r^0.5 lt dim)
if w(0) ne -1 then begin
;for i=0,n-1 do if r(i) lt dim then begin
	plots,x(w),y(w),psym=2,color=col
end

end

pro dcirc,xx,yy,col,dim,hex=hex
for p=0L,n_elements(xx)-1 do begin
	x=xx(p)
	y=yy(p)
	if keyword_set(hex) then r=x^2+y^2+x*y else r=x^2+y^2
	r=(r)^0.5
	rr=!d.x_size
	if keyword_set(hex)then step=!PI/3/float(rr) else step=!PI/2/float(rr)
	
	if r le dim then for a=0,rr do begin
		plots,r*cos(a*step),r*sin(a*step),psym=3,color=col
	end
end

end

pro vis_sym,dim,cntlim,hex=hex, verbose=verbose,circ=circ

if keyword_set(cntlim) then cntlim=(20<cntlim)>0 else cntlim=5 
print,cntlim
a=gen_vects(dim)
plot,indgen(dim),indgen(dim),/nodata,/iso,xrange=[0,1.5*(dim-1)],yrange=[0,dim-1],xst=-1,yst=-1

	if keyword_set(hex) then begin
		buf=hextrans(a)
		x=buf(0:dim-1,0)
		y=buf(0:dim-1,1)
	end else begin
		x=a(0:dim-1,0)
		y=a(0:dim-1,1)
	end



oplot,x,y,psym=2

a=a(dim:*,*)

for i=1,cntlim do begin
		
	print,i
	t=selpts(a,i,dim,hex=hex,verbose=verbose)
;	if n_elements(t) ne 1 then plots,t(*,0,*),t(*,1,*),psym=1 ,color=(i)*255./float(cntlim) else print,"No vectors found for multiplicity: "+string(i)
	
	if t(0) ne -1 then begin
		help,t
		if keyword_set(hex) then begin
			buf=hextrans(t)
			x=buf(*,0,*)
			y=buf(*,1,*)
		end else begin
			x=t(*,0,*)
			y=t(*,1,*)
		end


		if keyword_set(circ) then dcirc,t(0,0,*),t(0,1,*),(2*i+1)*255./16.,dim,hex=hex 
		;plots,x,y,psym=2,color=(2*i+1)*255./16 
		drawpts,x,y,(2*i+1)*255./16,dim
;	print,(i)*255./float(cntlim)
	end $
	else print,"No vectors found for multiplicity: "+string(i)


end


end
