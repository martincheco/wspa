pro dowpalette, r = r, g = g, b = b,nomod=nomod
;redblue diverging center white
;r, g, b = vektorove promenne pro vystup nastavenych intenzit RGB (nemusi se vyuzit)
;nomod does not store the palette
if !D.NAME ne 'NULL' then device, decomposed = 0

ramp=indgen(128)
flat=bytarr(128)
;ii=[ramp/2B,3B*ramp/2B+64B]
ii=[flat,ramp*2B]
bii=reverse(ii)


rii=[191B+ramp/2B,flat+255B]
rii=reverse(rii)
;gii=[3B*ramp/2B,ramp/2B+192B]
gii=[32B+ramp/2B,159B*ramp/128B+95B]
gii=reverse(gii)


;ij=[ramp/4B+160B,reverse(ramp)*3B/2B]

b=[bii]
r=[rii]
g=[gii]

print,'Using: dowpalette.pro'
if not(keyword_set(nomod)) then tvlct,r,g,b
end
