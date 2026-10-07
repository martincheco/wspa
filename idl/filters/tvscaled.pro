function TvScaled, img, mincolor = mincolor, maxcolor = maxcolor
;preskaluje barvy v zadanem obrazku stejne jako procedura TvScale
;na rozdil od TvScale obrazek nekresli, ale vraci jako funkcni hodnotu
;mincolor = nejmensi dovolene cislo barvy
;maxcolor = nejvetsi dovolene cislo barvy

if not keyword_set(mincolor) then mincolor = 1
if not keyword_set(maxcolor) then maxcolor = !D.table_size-2
minvalue = float(min(img, max = maxvalue))
maxvalue = float(maxvalue)
if minvalue EQ maxvalue then return, int2B(img * 0)
ret =  int2B((mincolor*(maxvalue-img) + maxcolor*(img-minvalue)) / (maxvalue-minvalue))
;print,'Using: TvScaled.pro'
return, ret
end
