function fall2min,y,xseed
con=0
x=xseed
n=n_elements(y)
x=(x<(n-1))>0

while 1 do begin
xd=x
xp1=(x+1)<(n-1)
xm1=(x-1)>0
if y(x) lt y(xm1) and y(x) lt y(xp1) then return,x ;minimum found

if y(x) gt y(xm1) and y(x) le y(xp1) then x=xm1 ;on the left is lower
if y(x) gt y(xp1) and y(x) le y(xm1) then x=xp1 ;on the right is lower

if xd eq x then $  ;dead cycle
    if x eq 0 or x eq n-1 then return,x else return,-1 ;if on the flat, returns nothing, if on the edge, gives value


end

return,-1 ;this should never happen
end

function localmin,xn,yn,w,ran=ran
;returns local minima for a sane curve
;x values; if not ascending the function does sort it
;y values
;w characteristic width between minima expected (in indices), default 1
;performs random search, otherwise will perform a regular search
;works in indices

s=sort(xn)
x=xn(s)
y=yn(s)

mx=max(x)
mn=min(y)

n=n_elements(x)

if not(keyword_set(w)) then w=1 else w=round((w>1)<(n/5))

if keyword_set(ran) then xseed=round(n*(randomu(seed,n/w+1))) $
else xseed=indgen(n/w+1)*w

xmin=fltarr(n/w+1)*x(0) ; just to have the same type
for i=0,n/w do begin
;    print,"In: ",xseed(i)
    xmin(i)=fall2min(y,xseed(i))
;    print,"Out: ",xmin(i)

end

xmin=xmin(where(xmin ne -1)) ;purify
xmin=xmin(sort(xmin)) ;sort
xmin=xmin(uniq(xmin)) ;purify

return,xmin
end


