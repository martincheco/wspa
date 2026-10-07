function load_orbs_old


aa=read_png('orb1.png')
bb=read_png('orb2.png')
cc=read_png('orb3.png')
dd=read_png('orb4.png')

a=double(reform(aa(0,*,*)))
b=double(reform(bb(0,*,*)))
c=double(reform(cc(0,*,*)))
d=double(reform(dd(0,*,*)))

a=shift(a,-10,7-5)
b=shift(b,0,0-5)
c=shift(c,0,7-5)
d=shift(d,0,0-5)



a=a(1:278,*)
c=c(1:278,*)
b=b(1:278,*)
d=d(1:278,*)




return,{a:a,b:b,c:c,d:d}

end

function orbfile,f

a=read_file(f,/array)

n=n_elements(a)

aa=strsplit(a(0),';',/extract)
nn=n_elements(aa)	

img=dblarr(n,nn)

for i=0,n-1 do begin
	aa=strsplit(a(i),';',/extract)
	img(i,*)=double(aa)
end

return,img
end

function load_orbs


a=orbfile('DOS70.txt')
b=orbfile('DOS71.txt')
c=orbfile('DOS72.txt')
d=orbfile('DOS73.txt')
s=orbfile('Absorption.txt')

a=a/max(a)
b=b/max(b)
c=c/max(c)
d=d/max(d)
s=s/max(s)


;a=a-a(0,0)
;b=b-b(0,0)
;c=c-c(0,0)
;d=d-d(0,0)
;s=s>0.


return,{a:a,b:b,c:c,d:d,s:s}

end




function photocurr,t,p
;s=smooth(t.s^0.75,40,/edge_wrap)
;s=smooth(t.s/max(t.s),40)
;s=t.s*0.+1.
s=t.s^0.5
;fw=p(3)*(t.b*t.d) + p(4)*(t.b*t.c) + t.c + p(1)*t.d + p(2)*t.b

fw=p(0)*t.c + p(1)*t.d + p(2)*t.b
fw=s*fw


bw=(p(3)*t.a + p(4)*t.b) ;+ p(5)*t.c
bw=s*bw


return,{fw:fw,bw:bw,s:s}
end

pro photocurr_randomize,t,pp=pp,smth=smth

if not(keyword_set(smth)) then smth=1
y=0
while y lt 200 do begin
	r=randomn(seed,5)
	
	ph=photocurr(t,pp)
	;ppn=pp+((r)-0.5)/500.
	ppn=pp*((r/10.)+0.5)/.5
;print,'diff'
	phn=photocurr(t,ppn)
	phndif=phn.bw+phn.fw
	zero1=max(phndif)/(max(phndif)-min(phndif))
	bwrpalette,zero=zero1
	tvscl,smooth(phndif,smth,/edge_wrap),280,240
	phdif=ph.bw+ph.fw
	print,min(phdif),max(phdif),phdif(0,0)
	zero2=max(phdif)/(max(phdif)-min(phdif))
	bwrpalette,zero=zero2
	tvscl,smooth(phdif,smth,/edge_wrap),0,240
	
	
;print,'fw'
	phnfw=phn.fw
	zero1=max(phnfw)/(max(phnfw)-min(phnfw))
	bwrpalette,zero=zero1
	tvscl,smooth(phnfw,smth,/edge_wrap),280,2*240
	phfw=ph.fw
	zero1=max(phfw)/(max(phfw)-min(phfw))
	bwrpalette,zero=zero1
	tvscl,smooth(phfw,smth,/edge_wrap),0,2*240


	
;print,'bw'
	phnbw=phn.bw
	zero1=max(phnbw)/(max(phnbw)-min(phnbw))
	bwrpalette,zero=zero1
	tvscl,smooth(phnbw,smth,/edge_wrap),280,0
	phbw=ph.bw
	zero1=max(phbw)/(max(phbw)-min(phbw))
	bwrpalette,zero=zero1
	tvscl,smooth(phbw,smth,/edge_wrap),0,0


	
	cursor,x,y,/up,/device
	if x gt 290 then begin
		pp=ppn
		print,pp
	end
end


end

