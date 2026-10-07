function SubtrPlane, img, const = const, slopex = slopex, slopey = slopey
;Prolozi obrazkem rovinu a vraci obrazek vznikly po odecteni teto roviny
;img = puvodni data (obrazek)
;const = konstantni slozka (prumerna hodnota pres cely obrazek)
;slopex = sklon ve smeru osy x
;slopey = sklon ve smeru osy y
;Jsou-li zadany parametry odecitane roviny pomoci pojmenovanych parametru const, slopex, slopey
;rovina se odecte okamzite, jinak se parametry pocitaji
;a pripadne ulozi do promennych prirazenych pojmenovanym parametrum

if min(img) eq max(img) then begin ;if the image is completely flat
	if not(keyword_set(slopex)) then slopex=0
	if not(keyword_set(slopey)) then slopey=0
	if not(keyword_set(const)) then const=min(img)
	print,"Image is flat!"
	print,"X, Y slope: ",slopex,slopey
	return,img
end

m=(size(img))[1]
n=(size(img))[2]
stairsx=(findgen(m)-float(m-1)/2) # replicate(1,n)
stairsy=(findgen(n)-float(n-1)/2) ## replicate(1,m)
if not keyword_set(const) then const = total(img)/(m*n)


;if not keyword_set(slopex) then slopex = median((img-const)*stairsx) / ((1./12.0)*(m-1)*(m+1))
;if not keyword_set(slopey) then slopey = median((img-const)*stairsy) / ((1./12.0)*(n-1)*(n+1))

if not keyword_set(slopex) then slopex = total((img-const)*stairsx) / ((1./12.0)*n*m*(m-1)*(m+1))
if not keyword_set(slopey) then slopey = total((img-const)*stairsy) / ((1./12.0)*m*n*(n-1)*(n+1))
res=img - const - stairsx*slopex - stairsy*slopey
print,"X, Y slope: ",slopex,slopey
;print,'Using: Subtrplane'
;help,res
;print,min(res), max(res), median(res)
return, res
end
