function set_copy,sets
n=n_elements(sets)
newpset=ptrarr(n)
for i=0,n-1 do $
    newpset(i)=ptr_new(*sets(i))

return,newpset
end


function read_rules,f
return,""
end

function set_process,set,rules

;if rules() contains set.xunit then ...



;endcase

return,set
end

pro qplus_vis,set,setp
;set,sets has the context of a set of curves
cp=[254,200,175,95,70,33,255,90,0] ;pallette

nmem=n_elements(set)

!P.MULTI=[0,2,nmem,0,1]


for i=0,nmem-1 do begin
	p=set(i).pars
	plot,set(i).x,set(i).y,psym=3,/nodata,background=255,color=0,yst=16,charsize=2,$
	xtit=p.xax+' '+p.xunit,ytit=p.yax+' '+p.yunit
	oplot,set(i).x,set(i).y,psym=3,color=cp(8)
	oplot,set(i).x,set(i).yb,psym=3,color=cp(4)
    end

nmemp=n_elements(setp)
if nmemp lt nmem then nmemp=nmem


for i=0,nmemp-1 do begin
	p=setp(i).pars
	plot,setp(i).x,setp(i).y,psym=3,/nodata,color=0,yst=16,charsize=2,$
	xtit=p.xax+' '+p.xunit,ytit=p.yax+' '+p.yunit
	oplot,setp(i).x,setp(i).y,psym=3,color=cp(8)
	oplot,setp(i).x,setp(i).yb,psym=3,color=cp(4)
    end

!P.MULTI=0
end


pro qbender,sm,conversion=conversion
;sm - number of members in a set
;conversion(0) - x size of the corresponding image (in nm)
;conversion(1) - xpixels/xsize of the corr. image (in px/nm)
; conversion(2),conversion(3) - analogous for y



if not(keyword_set(sm)) then sm=4

f=dialog_pickfile(/multi,/must_exist)
if not(File_test(f(0))) then return
sets=mread_qplus(f,sm)
;psets=mread_qplus(f,sm)
psets=set_copy(sets)

nmem=n_elements(*psets(0))
rules=read_rules()


for i=0,nmem-1 do begin
	unit=(*psets(0))(i).pars.xunit
	(*psets(0))(i)=set_process((*psets(0))(i),rules)
	(*psets(0))(i).x=axred((*psets(0))(i).x,unit)
	(*psets(0))(i).pars.xunit=unit
	unit_o=(*psets(0))(i).pars.yunit
	unit=unit_o
	(*psets(0))(i).yb=axred((*psets(0))(i).yb,unit) ;not a clean solution
	unit=unit_o
	(*psets(0))(i).y=axred((*psets(0))(i).y,unit)
	(*psets(0))(i).pars.yunit=unit

end

if (keyword_set(conversion)) then begin
    device, set_graphics_function = 6; XOR graphics
    xpos=((*psets(0))(0).pars.xpos+conversion(0)/2)*conversion(1)
    ypos=((*psets(0))(0).pars.ypos+conversion(2)/2)*conversion(3)
    print,xpos,ypos
    plots,xpos,ypos,psym=5,/device
    device, set_graphics_function = 3; copy graphics
    window,/FREE,xs=700,ys=700

end 

wgraph=!D.window

setvis

qplus_vis,*sets(0),*psets(0)

end