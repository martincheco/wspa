pro GoldPalette2, r = r, g = g, b = b,nomod=nomod
;Nastavi "zlatocervenou" paletu
;r, g, b = vektorove promenne pro vystup nastavenych intenzit RGB (nemusi se vyuzit)
;nomod does not store the palette
if !D.NAME ne 'NULL' then device, decomposed = 0
h=bytarr(128)
q=bytarr(64)

i=byte(indgen(128)*2B)

r=[i,h+255B]
g=[q,i,q+255B]
b=[h,i]

print,'Using: Goldpalette2.pro'
if not(keyword_set(nomod)) then tvlct,r,g,b
end
