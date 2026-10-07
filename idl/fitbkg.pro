function fitbkg,y,boundsize
;should subtract a line bkg(or more?) from the data
;boundsize specifies width on the sides (percentage) where to catch the line, default 10 percent on each side
;does not need regular data
n=n_elements(y)
if not(keyword_set(boundsize)) then boundsize=0.1
if boundsize lt 0.4 then begin
x=indgen(n)
yw=[y(0:boundsize*n),y(n*(1-boundsize)-1:n-1)]
xw=[x(0:boundsize*n),x(n*(1-boundsize)-1:n-1)]
end else return,1
R = LADFIT(xw,yw) 
yn=y-(R(0)+R(1)*x)
return,yn
end
