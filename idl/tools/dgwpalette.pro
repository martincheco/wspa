pro dgwpalette, r = r, g = g, b = b,nomod=nomod
;redblue diverging center white
;r, g, b = vektorove promenne pro vystup nastavenych intenzit RGB (nemusi se vyuzit)
;nomod does not store the palette
if !D.NAME ne 'NULL' then device, decomposed = 0

ramp=indgen(128)
flat=bytarr(128)
ii=[ramp/2B,3B*ramp/2B+63B]
bii=reverse(ii)


gii=[95B+3B*ramp/4B,ramp/2B+191B]
gii=reverse(gii)

;ij=[ramp/4B+160B,reverse(ramp)*3B/2B]

b=[bii]
r=[bii]
g=[gii]

print,'Using: dgwpalette.pro'
if not(keyword_set(nomod)) then tvlct,r,g,b
end
