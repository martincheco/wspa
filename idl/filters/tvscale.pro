pro TvScale, img, mincolor = mincolor, maxcolor = maxcolor, win = win
;nakresli obrazek tak, aby byla plne vyuzita zadana skala barev
;mincolor = nejmensi dovolene cislo barvy
;maxcolor = nejvetsi dovolene cislo barvy
;win = cislo okna, do ktereho se bude kreslit
print,'Using: tvscale.pro'
if not keyword_set(mincolor) then mincolor = 0
if not keyword_set(maxcolor) then maxcolor = !D.table_size-1
if keyword_set(win) then wset, win
minvalue = float(min(img, max = maxvalue))
maxvalue = float(maxvalue)
if minvalue EQ maxvalue then tv, int2B(img * 0) else $
tv, int2B((mincolor*(maxvalue-img) + maxcolor*(img-minvalue)) / (maxvalue-minvalue))

end
