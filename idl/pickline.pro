function pickline,x,y,mn=mn,rng=rng
;interactively lets you select extremities in a graph (max as default)

if not(keyword_set(rng)) then rng=round(n_elements(x)/100.)>1 else rng=abs(rng)
n=n_elements(x)
res=0D
;ys=smooth(y,rng)
ys=y
plot,x,y,xst=1,yst=1
;cursor,xx,yy,/nowait,/data
yy=min(y)+1.
repeat begin
;	while !mouse.button eq 0 do begin
;	cursor,xx,yy,/data,/nowait
;	while !mouse.button eq 0 do begin
		cursor,xx,yy,/data
		wait,0.2
		ii=where(abs(x-xx) eq min(abs(x-xx)))
		print,xx,ii(0)
		if ii(0) ne -1 then begin
			i=ii(0) 
			ly=ys((i-rng/2)>0:(i+rng/2)<(n-1))
			if not(keyword_set(mn)) then w=where(ly eq max(ly)) else w=where(ly eq min(ly))
			print,w(0)
			if w(0) ne -1 then ww=w(0)+((i-rng/2)>0) else w=(0+rng/2)<(-1)
			plots,x(ww),y(ww)*1.1,psym=4
		end

;	end
	print,i,x(ww)
	res=[res,x(ww)]
endrep until yy le min(y) 

return,res
end


