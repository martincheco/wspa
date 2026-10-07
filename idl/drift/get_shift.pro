function get_shift,a,b,reg=reg ;determines an arbitrary shift between two similar or
;identical images a and b
;reg forces the use of register2 module (iterative search for the shift)

s=size(a)
;print,s(1),s(2)
if keyword_set(reg) then begin
	aa=reform(a,1,s(1),s(2))
	bb=reform(b,1,s(1),s(2))
	rg=register_iter(aa,bb,1,0,0,0,0,0,0,mask=[0,0,0,1,1,0,0],/silent)
	r=[rg.vect(3),rg.vect(4)]
	print,r
end else begin
	g=abs(shift(ccor(a,b),s(1)/2,s(2)/2))
;tvscl,g
	ii=where(g eq max(g))
	ii=ii(0)
	r=[ii mod s(1)-s(1)/2,ii/s(1)-s(2)/2]
end
return,r
end
