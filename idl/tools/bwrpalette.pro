pro bwrpalette,r=r,g=g,b=b,nomod=nomod,zero=zero

;if not(keyword_set(zero)) then zero=0.5 else zero=(zero>0.)<1.

;print,zero

bwpalette,r=rb,g=gb,b=bb,/nomod
rwpalette,r=rr,g=gr,b=br,/nomod


if zero lt 0.05 then begin
;	print,'zero too small'
	r=reverse(rb)
	b=reverse(bb)
	g=reverse(gb)
end else if zero gt 0.95 then begin
;	print,'zero too high'
	r=(rr)
	b=(br)
	g=(gr)
end else begin
;print,'normal'
r1=congrid(rb,256*(1.-zero))
g1=congrid(gb,256*(1.-zero))
b1=congrid(bb,256*(1.-zero))

r1=reverse(r1)
b1=reverse(b1)
g1=reverse(g1)


r2=congrid(rr,256*zero)
g2=congrid(gr,256*zero)
b2=congrid(br,256*zero)


r=[r1,r2]
g=[g1,g2]
b=[b1,b2]

end

if not(keyword_set(nomod)) then tvlct,r,g,b

end
