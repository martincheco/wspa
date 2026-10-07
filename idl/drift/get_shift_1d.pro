function get_shift_1d,a,b,mx=mx ;determines an arbitrary shift between two similar or
;identical size vectors a and b
;mx returns maximum value


	s=size(reform(a))
;print,s(1),s(2)
	g=abs(shift(ccor_1d(reform(a),reform(b)),s(1)/2))
;tvscl,g
	ii=where(g eq max(g))
	ii=ii(0)
	r=ii - s(1)/2	
	if keyword_set(mx) then mx=max(g)

	return,r
end
