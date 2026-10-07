function pendry2,en,x,y

;x,y are input vectors to calculate pendry R-factor, 
;vectors have to be positive, above one(?)
;ref: G. Ertl, J. Kueppers - Low Energy Electrons and Surface Chemistry 
;ISBN 3-527-26056-0, equation 9.68


nx=n_elements(x)
ny=n_elements(y)
nen=n_elements(en)

x=reform(x,nx)
y=reform(y,ny)
en=reform(en,nx)

fx=double(x)
fy=double(y)

;derivating

dlnIx=double(Simplederiv(en,alog(fx>1)))
dlnIy=double(Simplederiv(en,alog(fy>1)))

;help,dlnIx
;help,dlnIy
;help,total(dlnIx)
;help,total(dlnIy)


;upper integral
ru=total((dlnIx-dlnIy)^2,/double)
;lower integral
rl=total(dlnIx^2+dlnIy^2,/double)

help,ru/rl
;help,rl

return, ru/rl
end
