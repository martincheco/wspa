pro BluePalette, r = r, g = g, b = b,nomod=nomod
;Nastavi "modrou" paletu
;r, g, b = vektorove promenne pro vystup nastavenych intenzit RGB (nemusi se vyuzit)
;nomod does not store the palette

device, decomposed = 0
;h=bytarr(128)
;q=bytarr(64)

;i=byte(indgen(128)*2B)

b=[indgen(256)]
r=[bytarr(256)]
g=[bytarr(256)]

print,'Using: Bluepalette.pro'
if not(keyword_set(nomod)) then tvlct,r,g,b
end
