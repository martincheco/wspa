pro map_process
f=dialog_pickfile(/multi,filter='MLS*.sxm')
for i=0,n_elements(f)-1 do begin
	print,f(i)
	t=lumimap(f=f(i))
	tt=lumi_despk2d(lumi_baseline(t),150)
;	ta=lumi_corr(t,13,15,thr=0.8,/iter,export='bright')
	ta=lumi_corr(t,10,15,thr=0.8,/iter,export='bright')
;	tb=lumi_corr(t,32,15,thr=0.8,/iter,export='dark')
	tb=lumi_corr(t,20,15,thr=0.8,/iter,export='dark')
	plot,1240./t.x,tb.avg,xst=1,yst=1
	oplot,1240./t.x,ta.avg,color=200
	a=tvrd(0,true=1)
	write_png,f(i)+'.png',a

end

end

