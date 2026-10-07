function RowsEqual, img,backplane=backplane,col=col,smth=smth
;Vyrovnavani radku
;Od kazdeho radku se odecita streni stredni hodnota dat v nem
;img = puvodni data (obrazek)
;Funkce vraci pole s vyrovnanymi radky
;col - column to use for the row equalization, smoothed by height/10

ss=size(img)
a=ss[1]
b=ss[2]
;print,'Using: RowsEqual'
if keyword_set(col) then begin
	help,img
    col1=(reform(img((col>0)<a,*)))
	help,col1
	if keyword_set(smth) then col1=smooth(col1,smth,/edge_wrap)
    	res=transpose(mreplicate((col1),a))
	return,img-res
end


if not(keyword_set(backplane)) then return, img - (total(img, 1) ## replicate(1, a)) / float(a) $
else $
begin
	mg=img*0

	for i=0,b-1 do begin
		;h=histogram((img(*,i)),binsize=10)
		val=median(img(*,i))
		if val ne -1 then mg(*,i)=img(*,i)-val
	end
	return,mg
end

end
