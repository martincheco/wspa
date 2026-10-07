pro bwpalette, r = r, g = g, b = b,nomod=nomod
;redblue diverging center white
;r, g, b = vektorove promenne pro vystup nastavenych intenzit RGB (nemusi se vyuzit)
;nomod does not store the palette

if !D.NAME ne 'NULL' then device, decomposed = 0
;h=bytarr(128)
;q=bytarr(64)

;i=byte(indgen(128)*2B)
ii=indgen(256)
rii=reverse(ii)
ij=bytarr(256)+255.;round(indgen(128)/2.)

b=[ij]
g=[rii]
r=[rii]

;print,'Using: BWpalette.pro'
if not(keyword_set(nomod)) then tvlct,r,g,b
end
