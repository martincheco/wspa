function despk,array,tol=tol,width=width
if not(keyword_set(tol)) then tol=0.1 ;standard 10 percent tolerance
if not(keyword_set(width)) then width=9 ;standard 9 point median filter

newarray=reform(array) ;need to clone the array not to overwrite it
dtm=median(newarray,width)
w=where( (newarray / dtm)-1. gt tol )


newarray(w)=dtm(w)

return,newarray
end
