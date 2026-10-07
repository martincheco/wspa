function photoncycle,f,freq=freq,shft=shft
;loads a cycle of photon intensity vs. modulation at a given frequency
;from a time-correlated histogram
;assumes that the no. of histogram bins 
;correlates with a sine wave of the same freq and returns a structure containig all
;shft imposes a rigid shift of the modulation phase

if not(keyword_set(f)) then f=dialog_pickfile(/must_exist)
print,f
a=loadascii(f)

;a=aa.(0)

t=reform(a(0,*)) ;time values
v=reform(a(1,*)) ;counts

binw=t(1)-t(0) ;binwidth (ps)
help,binw

n=n_elements(t)

print,'last bin (ps):',t(-1)


if not(keyword_set(freq)) then begin
	freq=1E12/t(-1)
	per=t(-1)
	nn=n
	print,'Assuming frequency ',freq
end else begin
	per=1E12/freq
	;nn=n*per/t(-1)
	nn=n
end

print,'Calculated period (ps): ',per
print,'Number of bins in the dataset: ',n 
print,'Calculated nbins for the sine: ',nn


;s=sin(2*!PI*(findgen(nn)/nn))
s=sin(2*!PI*(double(t)/per))

gg=get_shift_1d(v,s)
if not(keyword_set(shft)) then g=gg else g=shft
print,'Detected shift: ',gg
print,'Used shift: ',g

;ss=sin(2*!PI*(findgen(nn)+g(0))/nn)
gs=double(g(0))/nn
;ss=sin(2*!PI*(double(t)/per+gs))
ss=shift(sin(2*!PI*(double(t)/per)),-g(0))

return,{freq:freq,v:v,t:t,ss:ss,s:s,shft:g}
end






pro photoncycle_range,g,freq=freq,shft=shft,osc=osc


help,g


r=photoncycle(g(-1),freq=freq,shft=shft)
coeff=255/n_elements(g)
if keyword_set(osc) then plot,r.t,r.v,psym=2,background=255,color=0,yrange=[0,max(r.v)] else plot,r.ss,r.v,psym=2,background=255,color=0,yrange=[0,max(r.v)]



for i=0,n_elements(g)-2 do begin
	r=photoncycle(g(i),freq=freq,shft=shft)
	if keyword_set(osc) then oplot,r.t,r.v,psym=2,color=(n_elements(g)-1-i)*coeff else  oplot,r.ss,r.v,psym=2,color=(n_elements(g)-1-i)*coeff

	print,r.shft
end

end
