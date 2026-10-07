function sparse_uniq,x,tol=tol
;x array of values that need to be uniqued
;tol is tolerance within which to consider values as identical

if n_elements(x) eq 1 then return,[0]
if n_elements(x) eq 2 then begin
;    print,"only two"
    if keyword_Set(tol) then if abs(x(0)-x(1)) gt tol then return,sort(x)
    return,0
end

srt=sort(x)
xs=x(srt)

dif=abs(xs-shift(xs,1))

;this is probably ill
;if not(keyword_set(tol)) then begin
;    dif=abs(xs-shift(xs,1))
;    tol=xs(where(dif eq min(dif)))
;    tol=tol(0)
;end


;not very clean, but works by median values
wn=where(dif gt tol)

if wn(0) eq -1 then return,srt(n_elements(xs)/2.) ;all elements similar, return median

ix=0L
n=n_elements(wn)-1
for i=0,n do ix=[ix,(wn(i)+wn((i+1)<n))/2.] ;this is working in principle


return,srt(ix(1:*))
end