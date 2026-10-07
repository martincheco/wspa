function acor,im                                                                
print, 'Creating autocorrelation..'                                             
temp=fft(im,-1)                                                                 
imf=fft(temp*CONJ(temp),-1)                                                     
return, imf                                                                     
end    

;conversion routines for xyz and xyI fireball outputs

function convert, a,rep=rep,sn=sn,zoom=zoom,atoms=atoms                 
                      
if not(keyword_set(rep)) then rep=1                                 
if not(keyword_set(zoom)) then zoom=1.                                             
if not(keyword_set(sn)) then sn=400                                                                                                                       
;vezme jelinkuv zatim blize nespecifikovany format,                             
;ktery je zadan jako tri sloupce x, y a z souradnic                             
;a vygeneruje z nej obrazek                                                     
                                                                        
                                            
a1=a.field1   
a2=a.field2   
a3=a.field3 


;;;

n=n_elements(a1)      
print, a1[0],a2[0];debug

a1=a1-a1[0] ;centering                                                                     
a2=a2-a2[0]

help,n


;guessing..
xl=1L
xdif=1.1*abs(a1(1)-a1(0)) ;smallest difference of x

while abs(a1(xl+1)-a1(xl)) le xdif do xl=xl+1
xl=xl+1

yl=n/xl

print,'Dimensions of array'
print,xl,yl


yy=reform(a3,xl,yl)                                                             
s=size(yy)                 

xll=xl-1; cesar fixed this already! (summer 2013)                                                                        
yll=yl-1;                                                                        

yy=yy(0:xll-1,0:yll-1) ;some lines are doubled                                
;print,'MIN., MAX. VALUE:',min(yy),',',max(yy)                                   

vx2=a1[xl-1]      
vx1=a1[yl*xl-xll-1] 
vy2=a2[xl-1]                                                              
vy1=a2[yl*xl-xll-1]


print,'vectors:'
print,vx1,vy1,vx2,vy2
r=(vx1^2+vy1^2)^0.5 

;;;

img=fltarr(xll*rep,yll*rep)                                                     
for i=0,rep-1 do for j=0,rep-1 do $                                             
begin                                                                           
img(i*xll,j*yll)=yy                                                             
end                                                                           


fact=sn/r*0.5
print,'fact:'
print,fact
vx1=vx1*fact
vy1=vy1*fact
vx2=vx2*fact
vy2=vy2*fact
r=r*fact

snx=sn*xll/yll
sny=sn

print,snx,sny

imgg=congrid(img,snx,sny,cubic=-0.5)                                                                                                
imgg=imgg(0:snx-1,0:sny-1)            
fromx=([0.,0.,snx,snx])                                                   
fromy=([0.,sny,0.,sny])                                                   
tox=([0.,vx1,vx2,vx1+vx2]-(vx1+vx2)/2)*1.5*zoom+r                             
toy=([0.,vy1,vy2,vy1+vy2]-(vy2+vy1)/2)*1.5*zoom+r                        
                                                                                
                                                                                
result=warp_tri(tox,toy,fromx,fromy,imgg,output_size=[sn,sn])

return,result
;return,imgg
end      


function convert_debug, f,c

a=read_ascii(f,data_start=3)                    
help,a,/struct  
                                            
a1=reform(a.field1(0,*))
a2=reform(a.field1(1,*))
a3=reform(a.field1(2,*))

n=n_elements(a1)      

;guessing..
xl=1L
xdif=1.1*abs(a1(1)-a1(0)) ;smallest difference of x
print,a1(0:10),xdif

while abs(a1(xl+1)-a1(xl)) le xdif do xl=xl+1
xl=xl+1

print,'size in x',xl

yl=1L
ydif=1.1*abs(a2(1)-a2(0)) ;smallest difference of x
while abs(a2(yl+1)-a2(yl)) le ydif do yl=yl+1
yl=yl+1
print,'size in y',yl

print,'Dimensions of array'
print,xl,yl
                                                                                
a1=a1-a1[0]                                                                     
a2=a2-a2[0]                                                                     
                                                                                

yy=reform(a3,xl,yl)                                                             
s=size(yy)                 
                                                     
yy=yy(0:s(1)-c,0:s(2)-c) ;some lines are doubled                                
print,'MIN., MAX. VALUE:',min(yy),',',max(yy)                                   
xll=xl-1                                                                        
yll=yl-1                                                                        

vx2=a1[xl-1]-a1[0]                                                              
vx1=a1[yl*xll-xll]-a1[0]                                                          
                                                                                
vy2=a2[xl-1]-a2[0]                                                              
vy1=a2[yl*xl-xl]-a2[0]  


print,'vectors:'
print,vx1,vy1,vx2,vy2

r=(vx1^2+vy1^2)^0.5 

print,'Output dimensions'
print,size(yy)                                                                  

return,yy


end      


pro xyz2img
goldpalette,/pure
a=xyz2img()
end

;pro rgb_goldpalette,r,g,b                                                            
                                                                                     
;ll=intarr(85)*0                                                                      
;hl=intarr(85)+255                                                                    
;sl=indgen(85)*3                                                                      
;ssl=indgen(170)*3/2+1                                                                
;r=[0,ssl,hl]                                                                         
;g=[0,ll,ssl]                                                                         
;b=[0,ll,ll,sl]                                                                       
                                                                                     
;end   


pro pal_handler,ev
widget_control, ev.top, get_uvalue = descr
XLOADCT,group=ev.top,/modal
xyz2img_RedrawTopography, ev.top
xyz2img_UpdateScale, ev.top
end

pro Goldpal,ev
widget_control, ev.top, get_uvalue = descr
goldpalette,/pure
xyz2img_RedrawTopography, ev.top
xyz2img_UpdateScale, ev.top
end

pro xyz2img_reload,ev
widget_control, ev.top, get_uvalue = descr
xyz2img_Refresh, ev
xyz2img_RedrawTopography, ev.top
xyz2img_UpdateScale, ev.top
end


function sgn,x                                                                  
return, abs(x)/x                                                                
end  


function xyz2img,sn=sn
device,retain=2,decomposed=0
cd,current=hdir
print,'homedir: ',hdir

if not(keyword_set(sn)) then sn=400
d=7

descr = {atoms:ptr_new(0),vdata:ptr_new(0),data: fltarr(sn,sn), fact:1.,n:sn,rep:1, $
sclimg:bytarr(sn/d,sn),d:d,Cwin:0,TWin:0,SWin:0, $
contr:bytarr(sn,sn),hdir:hdir,indir:hdir,outdir:hdir,at_filename:'',filename:'',zoom:1., atoms_vis:1}

app = widget_base(/column, app_mbar = menu, title = 'xyz2img', /tlb_kill_request_event,uname='main')
open = widget_button(menu, value = 'Open',/menu)
d = widget_button(open, value = 'For derivation', event_pro = 'xyz2img_OpenDFileDialog') 

ZI = widget_button(open, value = 'xyZ/xyI', event_pro = 'xyz2img_OpenFileDialog') 
Ats = widget_button(open, value = 'Atoms', event_pro = 'xyz2img_OpenAtomDialog')

expo = widget_button(menu, value = 'Export', /menu)
savePNG= widget_button(expo, value = 'ExportAsPNG', event_pro = 'xyz2img_ExportAsPNG')
saveTIF= widget_button(expo, value = 'ExportAsTIF', event_pro = 'xyz2img_ExportAsTIF')
saveDat= widget_button(expo, value = 'ExportAsRaw', event_pro = 'xyz2img_ExportAsRaw')

savePNGs= widget_button(expo, value = 'ExportAsPNGwithScale', event_pro = 'xyz2img_ExportAsPNGs')
;saveTIFs= widget_button(expo, value = 'ExportAsTIFwithScale', event_pro = 'xyz2img_ExportAsTIFs')
savePNGc= widget_button(expo, value = 'ExportContourAsPNG', event_pro = 'xyz2img_ExportCAsPNG')

savePS= widget_button(expo, value = 'ExportContourAsPS', event_pro = 'xyz2img_ExportCAsPS')


labels = widget_base(app,/row,uname = 'Labels')

l1=widget_label(labels,value='Data File: none',/DYNAMIC_RESIZE,uname='l1')

graphs = widget_base(app,/row,uname = 'Graphs')


TWindow = widget_draw(graphs, xsize = descr.n, ysize = descr.n, $
  uname = 'TDraw')


SWindow = widget_draw(graphs,xsize = descr.n/descr.d, ysize = descr.n,  $
  uname = 'SDraw')

CWindow = widget_draw(graphs, xsize = descr.n, ysize = descr.n, $
  uname = 'CDraw')


tools = widget_base(app,/row,uname = 'Tools')

;butt2 = widget_base(tools,/row, frame = 0)
showall = widget_button(tools, value = 'Reload', event_pro = 'xyz2img_reload', sensitive = 1, $
  uname = 'ShowAllTopoButton')

palette = widget_button(tools, value = 'Palette', event_pro = 'pal_handler', sensitive=1)

goldpal = widget_button(tools, value = 'GoldPal.', event_pro = 'GoldPal', sensitive=1)


mtools=widget_base(tools,/row, frame = 0)

rep1 = CW_field(mtools,/row,/return_events,xsize=2,frame = 0,value=descr.rep,title='Repeat:',/integer,uname='rep1')
zom1 = CW_field(mtools,/row,/return_events,xsize=7,frame = 0,value=descr.zoom,title='Zoom:',uname='zom1')
fact = CW_field(mtools,/row,/return_events,xsize=11,frame = 0,value=descr.fact,title='Factor:',uname='fact')




;butt3 = widget_base(tools,frame = 0)



chk = widget_button(tools, value = 'Contours', event_pro = 'xyz2img_redraw_contour', sensitive=1)
chk2 = widget_button(tools, value = 'Exact', event_pro = 'xyz2img_redraw_contour2', sensitive=1)
c3d = widget_button(tools, value = '3D view', event_pro = 'xyz2img_3D', sensitive=1)
acor = widget_button(tools, value = 'AutoCorr.', event_pro = 'xyz2img_acor', sensitive=1)



;vykresleni widgetove struktury a zapis datove struktury
widget_control, app, /realize
widget_control, twindow, get_value = win
descr.TWin = win

widget_control, cwindow, get_value = win
descr.CWin = win


widget_control, swindow, get_value = win
descr.SWin = win

widget_control, app, set_uvalue = descr
;GoldPalette

;spusteni aplikace
xmanager, 'xyz2img', app, event_handler = 'xyz2img_AtTLBEvent'
end

pro xyz2img_Quit, ev
;Ukonceni programu
;answer = dialog_message('Do you really want to quit the application?', /question, $
;  dialog_parent = ev.top)
;if answer EQ 'Yes' then $
widget_control, ev.top, get_uvalue = descr

cd,descr.hdir
widget_control, ev.top, /destroy
ptr_free,ptr_valid()
end

pro xyz2img_AtTLBEvent, ev
;Osetreni udalosti tykajicich se hlavniho okna programu



case tag_names(ev, /structure_name) of
'WIDGET_KILL_REQUEST': xyz2img_Quit, ev

; application close button pressed
;'WIDGET_BASE': widgetcontrol, ev.top, scr_xsize = ev.x, scr_ysize = ev.y
else: print, !ERROR_STATE.MSG_PREFIX + 'Unprocessed event'
endcase

widget_control,ev.top, get_uvalue=descr

 
repbox = widget_info(ev.top, find_by_uname = 'rep1')
widget_control,repbox, get_value=rep

zombox = widget_info(ev.top, find_by_uname = 'zom1')
widget_control,zombox, get_value=zoom

factbox = widget_info(ev.top, find_by_uname = 'fact')
widget_control,factbox, get_value=fact


if (rep NE descr.rep) or (zoom NE descr.zoom) or (fact NE descr.fact) then begin
print,'Changed the numbers'
descr.zoom=zoom
descr.rep=rep
descr.fact=fact

widget_control,ev.top, set_uvalue=descr
if (descr.filename ne '' or descr.at_filename ne '') then xyz2img_refresh,ev
end


end

pro xyz2img_Redraw_contour2, ev
widget_control, ev.top, get_uvalue = descr
vdata = *descr.vdata
atoms = *descr.atoms
tvlct,r,g,b,/get
loadct,0,/silent
;help,atoms
wset, descr.Cwin
if n_tags(vdata) gt 0 then begin

lvls=min(descr.data)+findgen(10)*(max(descr.data)-min(descr.data))/9.

lbls=lvls
lbls= strtrim(string(lbls,format='(F5.2)'),2)

contour,vdata.field3*descr.fact,vdata.field1,vdata.field2,nlevels=60,/iso,/irregular,xstyle=1,ystyle=1,/cell_fill,/data
;contour,vdata.field3*descr.fact,vdata.field1,vdata.field2,levels=lvls,/overplot,/irregular,/data,c_annotation=lbls
end

if n_tags(atoms) gt 0 and descr.atoms_vis then begin
xyouts,atoms.field2,atoms.field3,atoms.field1,color=0,charthick=4.,charsize=1.5,/data
xyouts,atoms.field2,atoms.field3,atoms.field1,color=255,charthick=2.0,charsize=1.5,/data
end

descr.contr=tvrd()
tvlct,r,g,b
tv,descr.contr
widget_control, ev.top, set_uvalue = descr

wset,descr.Twin
end



pro xyz2img_Redraw_contour, ev
widget_control, ev.top, get_uvalue = descr
vdata = *descr.vdata
atoms = *descr.atoms
tvlct,r,g,b,/get
loadct,0,/silent
;help,atoms
wset, descr.Cwin
if n_tags(vdata) gt 0 then begin
lvls=min(descr.data)+findgen(10)*(max(descr.data)-min(descr.data))/9.
lbls=lvls
lbls= strtrim(string(lbls,format='(F5.2)'),2)
tvscl,descr.data
contour,descr.data,pos=[0,0,399,399],/device,levels=lvls,c_annotation=lbls,/noerase,yst=4,xst=4
end
;if n_tags(atoms) gt 0 then begin
;xyouts,atoms.field2,atoms.field3,atoms.field1,color=0,charthick=4.,charsize=1.5,/device
;xyouts,atoms.field2,atoms.field3,atoms.field1,color=255,charthick=2.0,charsize=1.5,/device
;end

descr.contr=tvrd()
tvlct,r,g,b
tv,descr.contr
widget_control, ev.top, set_uvalue = descr

wset,descr.Twin
end


pro xyz2img_3D, ev
widget_control, ev.top, get_uvalue = descr
vdata = *descr.vdata
atoms = *descr.atoms
help,atoms
wset, descr.Cwin
tvlct,r,g,b,/get
tvlct,rrr,ggg,bbb,/get

if n_tags(vdata) gt 0 then begin
set_plot,'Z'
device,set_resolution=[800,800],decomposed=0

loadct,0,/silent
;t3d,/reset,trans=[-0.5,-0.5,0]
;t3d,rot=[0,0,30]
;t3d,rot=[-5,0,0]

;t3d,scale=[2.,2.,2.]

;t3d,trans=[0.5,0.5,0]

imge=intarr(800,800)
shade_surf,descr.data,az=30,ax=88,xstyle=5,ystyle=5,zstyle=5,shades=bytscl(descr.data),/save,$
zrange=[min(descr.data),max(descr.data)]

shft=(max(descr.data)-min(descr.data))/8.
;contour,descr.data+shft,xstyle=4,ystyle=4,/t3d,zstyle=4,$
;zrange=[min(descr.data),max(descr.data)],$
;levels=shft+min(descr.data)+findgen(10)*(max(descr.data)-min(descr.data))/9.,$
;thick=1.5,/noerase,/device
;tvlct,r,g,b
b=tvrd()

set_plot,'X'
end
device,decomposed=0

tvlct,rrr,ggg,bbb
;loadct,4
bb=b(220:619,220:619)
tv,bb
descr.contr=bb
widget_control, ev.top, set_uvalue = descr
wset,descr.Twin
end

pro xyz2img_acor, ev
widget_control, ev.top, get_uvalue = descr
vdata = *descr.vdata
atoms = *descr.atoms
tvlct,r,g,b,/get
loadct,0,/silent
help,atoms
wset, descr.Cwin
if n_tags(vdata) gt 0 then begin

tv,bytscl(shift(acor(descr.data),descr.n/2,descr.n/2))

end

descr.contr=tvrd()
tvlct,r,g,b
tv,(descr.contr)
widget_control, ev.top, set_uvalue = descr

wset,descr.Twin
end





pro xyz2img_UpdateScale,top
widget_control, top, get_uvalue = descr
vata=*descr.vdata
vdata=vata.field3*descr.fact
scl=transpose(indgen(descr.n)*(max(vdata)-min(vdata))/256+min(vdata))

wset, descr.Swin

yyscl=intarr(descr.n/descr.d,descr.n)
yscl=intarr(descr.n/descr.d)
tvlct,r,g,b,/get
loadct,0,/silent
for h=0,descr.n-1 do yyscl(*,h)=yscl
escl=fltarr(descr.n/descr.d,descr.n)
;help,scl
;help,escl
scll=findgen(descr.n)/descr.n
for h=0,descr.n/descr.d-1 do escl(h,*)=scl
for h=0,descr.n-1 do begin
plots, [0,1.0],[scll(h),scll(h)],/normal,color=scll(h)*255

end
for h=1,9 do begin
xyouts,0,scll(h*descr.n/10),STRTRIM(string(scl(h*descr.n/10-1),format='(E8.1)'),1),/normal,color=255,charthick=1.0
;xyouts,0,scll(h*descr.n/10),STRTRIM(string(scl(h*descr.n/10-1),format='(E8.1)'),1),/normal,color=0,charthick=1.0

end
wshow,descr.swin,iconic=0
sclimg=tvrd()
help,sclimg
descr.sclimg=sclimg
tvlct,r,g,b
tv,sclimg
wset,descr.twin
widget_control, top, set_uvalue = descr

end

pro xyz2img_RedrawTopography, top
widget_control, top, get_uvalue = descr
img = descr.data
wset, descr.Twin
tv,tvscaled(img,min=1)
end

pro xyz2img_refresh, ev
widget_control, ev.top, get_uvalue = descr
a=*descr.vdata
;help,a,/struct
if (n_elements(a)) then if (n_tags(a)) then begin
print,'data file: ',descr.filename
fact=descr.fact
img=convert(a, atoms=*descr.atoms,rep=descr.rep,sn=descr.n,zoom=descr.zoom)
img=img*fact

descr.data = img

print,'Image_Recalculated'
end
widget_control, ev.top,set_uvalue=descr

xyz2img_RedrawTopography, ev.top
xyz2img_UpdateScale,ev.top
widget_control, ev.top, /update
end


pro xyz2img_OpenDFileDialog, ev
widget_control, ev.top, get_uvalue = descr
indir=descr.indir
print, indir
if n_elements(indir) NE 0 then cd,indir
f1 = dialog_pickfile(/read, /must_exist,title='Choose 1st, reference file',get_path=indir)
if indir NE '' then cd,indir
f2 = dialog_pickfile(/read, /must_exist,get_path=indir,title='Choose 2nd, file to subtract from 1st')

if f1 EQ '' or f2 EQ '' then return
if f1 NE '' and f2 NE '' then descr.filename=f1
if indir NE '' then descr.indir=indir
restore,descr.hdir+'/tmpl/data.tmpl'

*descr.vdata=read_ascii(f1,template=tm) ;prasarna jak nacpat differenci dvou obrazku primo do vdata, faktor pozdeji
vata=*descr.vdata
vdata1=vata.field3

*descr.vdata=read_ascii(f2,template=tm)
vata=*descr.vdata
vdata2=vata.field3
(*descr.vdata).field3=vdata1-vdata2
widget_control, ev.top,set_uvalue=descr

xyz2img_refresh,ev

xyz2img_RedrawTopography, ev.top
l1=widget_info(ev.top,find_by_uname='l1')
widget_control,l1,set_value='Data files: '+f1+' minus '+f2
widget_control, ev.top, /update
end




pro xyz2img_OpenFileDialog, ev
widget_control, ev.top, get_uvalue = descr
indir=descr.indir
print, indir
if n_elements(indir) NE 0 then cd,indir
f = dialog_pickfile(/read, /must_exist,get_path=indir)
if f EQ '' then return
if f NE '' then descr.filename=f
if indir NE '' then descr.indir=indir
restore,descr.hdir+'/tmpl/data.tmpl'
tt=read_ascii(f,template=tm)
*descr.vdata=tt
print,(fix(alog10((mean(tt.field3)))))

descr.fact=10.^(-fix(alog10((mean(tt.field3)))))
factbox = widget_info(ev.top, find_by_uname = 'fact')
widget_control,factbox, set_value=descr.fact,/update

widget_control, ev.top,set_uvalue=descr


xyz2img_refresh,ev

xyz2img_RedrawTopography, ev.top
l1=widget_info(ev.top,find_by_uname='l1')
widget_control,l1,set_value='Data file:'+f
widget_control, ev.top, /update
end



pro xyz2img_OpenAtomDialog, ev
widget_control, ev.top, get_uvalue = descr
indir=descr.indir
print, indir
if n_elements(indir) NE 0 then cd,indir
f = dialog_pickfile(/read, /must_exist,get_path=indir)
if f EQ '' then return
if f NE '' then descr.at_filename=f
print,f
if indir NE '' then descr.indir=indir
restore,descr.hdir+'/tmpl/atoms.tmpl'
a=read_ascii(f,template=tm)
*descr.atoms=a
print,'atoms loaded'
print,a.field1,a.field2,a.field3

widget_control, ev.top,set_uvalue=descr

xyz2img_refresh,ev


xyz2img_RedrawTopography, ev.top


widget_control, ev.top, /update
end

pro xyz2img_ExportCAsPS, ev                        
widget_control, ev.top, get_uvalue = descr
if descr.filename EQ '' then return                                          

if descr.outdir NE '' then cd,descr.outdir else if descr.indir NE '' then cd,descr.indir
fil=descr.filename+'_c.ps'
fout=dialog_pickfile(/write,filter='*.ps',file=fil, get_path=outdir)                   
if fout EQ '' then return

tvlct,r,g,b,/get

vdata = *descr.vdata
vdata= vdata
atoms = *descr.atoms
tvlct,r,g,b,/get
;loadct,0,/silent
help,atoms
wset, descr.Cwin

if n_tags(vdata) gt 0 then begin
set_plot,'PS'
device,filename=fout,/color,bits=8,/encapsulated

lvls=min(descr.data)+findgen(10)*(max(descr.data)-min(descr.data))/9.
lbls=lvls*1E7

lbls=strtrim(string(lbls,format='(F5.2)'),2)

contour,vdata.field3*descr.fact,vdata.field1,vdata.field2,nlevels=60,/iso,/irregular,xstyle=1,ystyle=1,/cell_fill,/data

;contour,descr.data,/device,levels=lvls,c_annotation=string(lbls),xstyle=4,ystyle=4,charthick=2.,charsize=1.4,/iso
;contour,descr.data,/device,nlevels=60,c_annotation=string(lbls),/fill,xst=4,yst=4
;contour,descr.data,/device,levels=lvls,c_annotation=string(lbls),/noerase,yst=4,xst=4


;contour,vdata.field3*descr.fact,vdata.field1,vdata.field2,nlevels=60,/iso,/irregular,xstyle=1,ystyle=1,charthick=2.,charsize=1.4,/cell_fill,/device,font=0
;contour,vdata.field3*descr.fact,vdata.field1,vdata.field2,nlevels=10,/overplot,/irregular,/device


;if n_tags(atoms) gt 0 then begin
;xyouts,atoms.field2,atoms.field3,atoms.field1,color=0,charsize=1.8,charthick=8.,/device
;xyouts,atoms.field2,atoms.field3,atoms.field1,color=255,charsize=1.8,charthick=4.,/device

;end

Device,/close
set_plot,'X'
end
descr.outdir=outdir                                                                                              
widget_control, ev.top, set_uvalue = descr
widget_control, ev.top, /update
end

pro xyz2img_ExportCAsPNG, ev                        
widget_control, ev.top, get_uvalue = descr
if descr.filename EQ '' then return                                          
if descr.outdir NE '' then cd,descr.outdir else if descr.indir NE '' then cd,descr.indir
fil=descr.filename+'_c.png'
fout=dialog_pickfile(/write,filter='*.png',file=fil, get_path=outdir)                   
if fout EQ '' then return

tvlct,r,g,b,/get
write_png,fout,descr.contr,r,g,b  
descr.outdir=outdir                                                                                              
widget_control, ev.top, set_uvalue = descr
widget_control, ev.top, /update

end



pro xyz2img_ExportAsPNGs, ev                        
widget_control, ev.top, get_uvalue = descr
if descr.filename EQ '' then return                                          

if descr.outdir NE '' then cd,descr.outdir else if descr.indir NE '' then cd,descr.indir
fil=descr.filename+'_s.png'
fout=dialog_pickfile(/write,filter='*.png',file=fil, get_path=outdir)                   
if fout EQ '' then return

tvlct,r,g,b,/get
write_png,fout,[bytscl(descr.data),descr.sclimg],r,g,b  
descr.outdir=outdir                                                                                              
widget_control, ev.top, set_uvalue = descr
widget_control, ev.top, /update
end

pro xyz2img_ExportAsPNG, ev                        
widget_control, ev.top, get_uvalue = descr
if descr.filename EQ '' then return                                          

if descr.outdir NE '' then cd,descr.outdir else if descr.indir NE '' then cd,descr.indir
fil=descr.filename+'.png'
fout=dialog_pickfile(/write,filter='*.png',file=fil, get_path=outdir)                   
if fout EQ '' then return

tvlct,r,g,b,/get
write_png,fout,[bytscl(descr.data)],r,g,b  
descr.outdir=outdir                                                                                              
widget_control, ev.top, set_uvalue = descr
widget_control, ev.top, /update
end

pro xyz2img_ExportAsRaw, ev                        
widget_control, ev.top, get_uvalue = descr
if descr.filename EQ '' then return                                          

if descr.outdir NE '' then cd,descr.outdir else if descr.indir NE '' then cd,descr.indir
fil=descr.filename+'.raw'
fout=dialog_pickfile(/write,filter='*.raw',file=fil, get_path=outdir)                   
if fout EQ '' then return

openw,1,fout
s=size(descr.data)
printf,1,s(1)
printf,1,s(2) 
mn=min(descr.data)
mx=max(descr.data)
printf,1,mn
printf,1,mx

print,s(1),s(2),mn,mx

help,descr.data
outpr=(descr.data-mn)/(mx-mn)
help,outpr
print,min(outpr), max(outpr)
outp=uint(outpr*65535)
help,outp
print,min(outp),max(outp)
writeu,1,outp
close,1
descr.outdir=outdir                                                                                              
widget_control, ev.top, set_uvalue = descr
widget_control, ev.top, /update
end


pro xyz2img_ExportAsTIF, ev                        
widget_control, ev.top, get_uvalue = descr
if descr.filename EQ '' then return                                          

if descr.outdir NE '' then cd,descr.outdir else if descr.indir NE '' then cd,descr.indir
fil=descr.filename+'.tiff'
fout=dialog_pickfile(/write,filter='*.tiff',file=fil, get_path=outdir)                   
if fout EQ '' then return

tvlct,r,g,b,/get
write_tiff,fout,bytscl([descr.data]),red=r,green=g,blue=b  
descr.outdir=outdir                                                                                              
widget_control, ev.top, set_uvalue = descr
widget_control, ev.top, /update
end
                                                                                             