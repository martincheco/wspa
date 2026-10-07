function bindown,img,a
;reduces the size of an array, factor must be an integer factor of its size
s=size(img)
help,s
nx=round(s(1)/a)
ny=round(s(2)/a)

imf=intarr(nx,ny)*img(0)

;xi=indgen(nx)*a
;yi=indgen(ny)*a


imf = REFORM(img, a, nx, a, ny)

imf = TOTAL(TOTAL(imf, 1), 2) / (a * a)


return,imf
end
