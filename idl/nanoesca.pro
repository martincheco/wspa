function read_stack_par,f

s=strarr(999)
openr,1,f
c=0
repeat begin
	a=""
	readf,1,a
	if a ne "" then begin
		s(c)=a
		c=c+1
	end
end until EOF(1)
close,1

s=s(0:c)

return,s
end

function read_stack,f
if not(keyword_set(f)) then f=dialog_pickfile(/multiple,/must_exist)
n=n_elements(f)
ek=indgen(n)
par=""

;if only one file is selected, check if it is a DAT file
if n eq 1 then $
	if (strlen(f(0))-strpos(f(0),".DAT")) eq 4 then begin
		dname=file_dirname(f(0),/mark)
		par=read_stack_par(f(0))
		npar=n_elements(par)
		;find data filenames
		istart=where(par eq "[DataSum]")
		if istart(0) ne -1 then begin
			;print,istart(0),npar,npar-istart(0)
			ff=strarr(npar-istart(0))
			ek=fltarr(npar-istart(0))
			
			for k=istart(0)+1,npar-1 do begin
				;print,k,k-istart(0)-1
				parcut=strsplit(par(k),/extract)
				if n_elements(parcut) ge 8 then begin
					ek(k-istart(0)-1)=float(parcut(0))
					ff(k-istart(0)-1)=dname+strmid(parcut(8),1,strlen(parcut(8))-2)
					lastc=k-istart(0)-1
				end
			end
			print,ff
			f=ff(0:lastc)
			ek=ek(0:lastc)
		end $
		else begin
			print,'No files found in .DAT file'
			return,-1
		end
	end

n=n_elements(f)
img=read_tiff(f(0))
s=size(img)
;print,'size 1st',s
stack=intarr(s(1),s(2),n)
for i=1,n-1 do stack(*,*,i)=read_tiff(f(i))

;print,'size stact',size(stack)

return, {data:stack,par:par,ek:ek}
end

pro show3d,stack,xi,yi,zi
print,xi,yi,zi

s=size(stack)
nx=s(1)
ny=s(2)
nz=s(3)
;print,xi,yi,zi


tva=bytscl((stack(*,*,zi)))
tvb=transpose((bytscl(stack(xi,*,*))))
tvc=(bytscl(stack(*,yi,*)))

;help,tva
;help,tvb
;help,tvc

tva(xi,*)=200
tva(*,yi)=200
tvc(*,0,zi)=200
tvc(xi,0,*)=200
tvb(*,yi)=200
tvb(zi,*)=200

tv,tva
tv,tvb,nx,0
tv,tvc,0,ny

end

pro nanoesca,xx=xx,yx=yx,zx=zx,norm=norm
;keywords are expansion factors


stack=read_stack(f)

s=size(stack.data)
nx=s(1)
ny=s(2)
nz=s(3)

if keyword_set(norm) then $
	for k=0,nz-1 do stack.data(*,*,k)=bytscl(stack.data(*,*,k))

mxs=float(max([nx,ny]))
print,mxs
if keyword_set(xx) then (xx=(xx)>0<10) else xx=(mxs<800.)/mxs
if keyword_set(yx) then (yx=(yx)>0<10) else yx=xx
if keyword_set(zx) then (zx=(zx)>0<10) else zx=round(mxs*xx/4/nz)
print,xx,yx,zx

eexc=getval(stack.par,"E_PH = ","float")
if eexc eq '' then eexc=nz

if xx ne 1 or yx ne 1 or nz ne 1 then begin
	newdata=congrid(stack.data,nx*xx,ny*yx,nz*zx,cubic=-0.5)
	ek=eexc-congrid(stack.ek,nz*zx)
end $
else $
begin
	ek=stack.ek
	ek=eexc-ek
	newdata=stack.data
end


s=size(newdata)
nx=s(1)
ny=s(2)
nz=s(3)

;help,nx
;help,ny
;help,nz

window,1,xs=nx+nz,ys=ny+nz,title='Stack view'

x=0
y=0
xi=nx/2
yi=ny/2
zi=nz/2

goldpalette,/pure
plots,[nx+1,nx+nz-1],[ny+1,ny+nz-1],psym=-3,/device,color=128
plots,[nx+1,nx+nz-1],[ny+nz-1,ny+1],psym=-3,/device,color=128

show3d,newdata,xi,yi,zi
xyouts,1,1,"EB = "+string(ek(zi))+" eV",/device,charsize=2.0

repeat begin
if (x lt nx) or (y lt ny) then cursor,x,y,/up,/device

    ;print,!mouse.button
    if (x lt nx) and (y lt ny) then begin
	repeat begin
	    cursor,x,y,/change,/device
	    xi=(x<(nx-1))>0
	    yi=(y<(ny-1))>0
	    show3d,newdata,xi,yi,zi
	    xyouts,1,1,"EB = "+string(ek(zi))+" eV",/device,charsize=2.0
	end until !mouse.button eq 1
    end

    if (x lt nx) and (y gt ny) then begin
	repeat begin
	    cursor,x,y,/change,/device
	    zi=((y-ny)<(ny-1))>0
	    xi=(x<(nx-1))>0
	    show3d,newdata,xi,yi,zi
	    xyouts,1,1,"EB = "+string(ek(zi))+" eV",/device,charsize=2.0
	end until !mouse.button eq 1
    end

    if (x gt nx) and (y lt ny) then begin
	repeat begin
	    cursor,x,y,/change,/device
	    zi=((x-nx)<(nx-1))>0
	    yi=(y<(ny-1))>0
	    show3d,newdata,xi,yi,zi
	    xyouts,1,1,"EB = "+string(ek(zi))+" eV",/device,charsize=2.0
	end until !mouse.button eq 1
    end

if (x lt nx) or (y lt ny) then cursor,x,y,/up,/device

end until (x gt nx) and (y gt ny)

end


