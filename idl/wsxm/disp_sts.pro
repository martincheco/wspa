pro disp_sts,t,chan1,chan2,oplot=oplot
;displays structure ina reasonable way
n=n_elements(t.chans)
if not(keyword_set(chan2)) then chan2=1<(n-1)
if not(keyword_set(chan1)) then chan1=0<(n-1)

if not(keyword_set(oplot)) then $
plot,t.data(chan1,*),t.data(chan2,*),xst=1,$
xtit=(t.chans(chan1)),ytit=(t.chans(chan2))$;,title=t.p.exptype+' '+t.p.date $
else $
oplot,t.data(chan1,*),t.data(chan2,*),color=oplot

end