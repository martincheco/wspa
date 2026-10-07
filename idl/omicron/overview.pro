pro Overview_lmaxSelect, ev
;vybrano nebo zruseno 
widget_control, ev.top, get_uvalue = descr
descr.lmax = ev.select
widget_control, ev.top, set_uvalue = descr
Overview_Spectrum_Redraw, ev.top
end

pro Overview_profileselect, ev
;vybrano nebo zruseno 
widget_control, ev.top, get_uvalue = descr
descr.profile = ev.select
widget_control, ev.top, set_uvalue = descr
if descr.profile then Overview_profile, ev.top else Overview_RedrawTopography,ev.top
end

pro overview
goldpalette
list=overview()
end

function didv,x,y ;global derivation filter
print, "derivating.."
wdth=fix(n_elements(x)/abs(max(x)-min(x))/10)
splns=fix(abs(min(x)-max(x))/10)
yy=Simplederiv(x,dezofilter(x,y, width=wdth, splines=splns))
return,yy
end

function dlnidlnv,x,y ;global derivation filter
print, "derivating.."
wdth=fix(n_elements(x)/abs(max(x)-min(x))/10)
splns=fix(abs(min(x)-max(x))/10)
yy=logderiv(x,dezofilter(x,y, width=wdth, splines=splns))
return,yy
end

pro pal_handler,ev
widget_control, ev.top, get_uvalue = descr
print,ev.top
print,'xloadct'
XLOADCT,group=ev.top,/modal
Overview_UpdateTopography, ev.top, description = descr
end

pro Goldpal,ev

widget_control, ev.top, get_uvalue = descr

Goldpalette

Overview_UpdateTopography, ev.top, description = descr
end

function sgn,x                                                                  
return, abs(x)/x                                                                
end  


function Overview, dirlist=dirlist, directory=directory, xsze = xsze, ysze = ysze
;xsize = vodorovny rozme okna aplikace
;ysize = svisly rozmer okna aplikace
if not(keyword_set(xsze)) then xsze=500
if not(keyword_set(ysze)) then ysze=500



;list = seznam vybranych souboru (vystupni parametr)
device,decomposed=0,retain=2

;Pocatecni cteni dat
print,'Overview started'
if keyword_set(directory) then $
begin
print,'Overview got a dir'
data = LoadSTM(directory = dirry, OK = OK)
end $
else $
begin
print,'Overview got no dir'
directory="/"
OK = "true"
end

;Zjisteni barevne palety
tvlct, r, g, b, /get
 
OUTPUT_INTERFACE_GATE = ptr_new('')

;Struktura popisujici stav aplikace OVERVIEW:
descr = {n: 0, dirlist: ptr_new(0), Data: ptr_new(0), Index: 0, TWindow: 0,SWindow: 0, TChannel: 1, SChannel: 1,$
  TopoZoom:0, tx1:0, tx2:0, ty1:0, ty2:0, px1:0,px2:0,py1:0,py2:0,OldPalette:{r:r, g:g, b:b}, Sindex:-1, spectrumx:ptr_new(0),spectrumy:ptr_new(0),$
  SubtrPlane: 1, ShowGrid: 1, profile:0, LocalPlane:1, EqualRows: 1, smooth: 0, TruncExtremes: 0, lmax:0, cdraw:0, InvertColors: 0, Interpolate: 1, ld: 0,$
  lnd: 0, xze:xsze, yze:ysze, cellsize:1D,$
  Selected: ptr_new(0), OUTPUT_INTERFACE_GATE: OUTPUT_INTERFACE_GATE}
;n = Pocet datovych polozek (1 polozka = 1 mereni)
;Data = ukazatel na pole datovych polozek
;Index = index aktualni (zobrazovane a zpracovavane) datove polozky
;Sindex = index aktualniho spektroskopicekho kanalu (zatim nefunguje)
;TWindow = cislo zobrazovaciho okna pro topografii
;TChannel = cislo zobrazeneho topografickeho kanalu
;OldPalette = definice palety nastavene pred spustenim programu (polozky R, G, B)
;TopoZoom = Zobrazovan pouze vyrez z celeho topografickeho obrazku
;tx1, ty1 = souradnice jednoho (leveho horniho) rohu vyrezu z topografie
;ty1, ty2 = souradnice protilehleho (praveho dolniho) rohu vyrezu z topografie
;SubtrPlane = od toporafickeho obrazku se odecita prolozena rovina - kompenzace sklonu
;ShowGrid = v topografickem obrazku se zobrazi spektroskopicka mrizka
;EqualRows = provadi se vyrovnavani radku
;localplane = rovina se odecita lokalne
;smooth = provadi se elementarni vyhlazeni filtrem
;InvertColors = prevraceni barevne skaly: vysoke hodnoty tmave, nizke svetle
;Selected = ukazatel na booleovske pole, ktere urcuje seznam uzivatelsky vybranych mereni
;OUTPUT_INTERFACE_GATE = dynamicka promenna, pomoci ktere lze ziskat vystup z widgetove casti aplikace
;dirlist = promenna obsahujici directory list v danem directory, pokud je
;ld,lnd = switches the derivation of spectroscopic curves

;definice widgetu
app = widget_base(/column, app_mbar = menu, title = 'STM Result Overview', /tlb_kill_request_events, $
  kill_notify = 'Overview_DestructApp', scr_xsize = xsize, scr_ysize = ysize)
file = widget_button(menu, value = 'File', /menu)
open = widget_button(file, value = 'Open', event_pro = 'Overview_OpenFileDialog')

opendd = widget_button(file, value = 'OpenDirectory', event_pro = 'Overview_OpenDirectory')

opendl = widget_button(file, value = 'OpenDirList', event_pro = 'Overview_OpenDirList')
add = widget_button(file, value = 'Add', event_pro = 'Overview_AddFiles')
closef = widget_button(file, value = 'Close', event_pro = 'Overview_CloseFileDialog', uname = 'CloseFiles', $
  sensitive = 0)
save = widget_button(file, value = 'SaveSelection', uname = 'SaveList', event_pro = $
  'Overview_SaveList', /separator)
quit = widget_button(file, value = 'Quit', event_pro = 'Overview_Quit', /separator)

expo = widget_button(menu, value = 'Image', /menu)
;savetiff= widget_button(expo, value = 'ExportAsTiff', event_pro = 'Overview_ExportAsTiff')
savePNG= widget_button(expo, value = 'Export PNG', event_pro = 'Overview_ExportAsPNG')
rmdrift= widget_button(expo, value = 'Rmdrift->PNG', event_pro = 'Overview_rmdrift')
rmdriftg= widget_button(expo, value = 'Global Rmdrift->PNG', event_pro = 'Overview_rmdriftg')

useful= widget_button(expo, value = 'ExportAll', event_pro = 'Overview_ExportUseful',sensitive=0,/separator)

esxpo = widget_button(menu, value = 'Spectrum', /menu)
;savetiff= widget_button(esxpo, value = 'ExportSAsTiff', event_pro = 'Overview_ExportSAsTiff')
ssavePNG= widget_button(esxpo, value = 'Export to PNG', event_pro = 'Overview_ExportSAsPNG')


epxpo = widget_button(menu, value = 'Profile', /menu)
psavePNG= widget_button(epxpo, value = 'Export to PNG', event_pro = 'Overview_ExportSAsPNG')

cr0= widget_base(app, /column, /base_align_left)

header = widget_label(cr0, uname = 'Header', /align_left, /dynamic_resize, $
  value = '')
;timeh = widget_label(cr0, uname = 'Timeh', /align_left, /dynamic_resize, $
;  value = '')
comment = widget_label(cr0, uname = 'Comment', /align_left, /dynamic_resize, $
  value = '')
;top = widget_base(app, /row, uname = 'Top')
;r1 = widget_base(app, /row, /base_align_left,uname='Top')
r2 = widget_base(app, /row, /base_align_left)



r0 = widget_base(app, /row,uname='Top')
prev = widget_button(r0, value = '<<Previous', uname = 'PreviousFile', event_pro = 'Overview_PrevFile', $
  sensitive = 0)
next = widget_button(r0, value = 'Next>>', uname = 'NextFile', event_pro = 'Overview_NextFile', $
  sensitive = 0)

dprev = widget_button(r0, value = '<<Prev_Dir', uname = 'PreviousDir', event_pro = 'Overview_PrevDir')
dnext = widget_button(r0, value = 'Next_Dir>>', uname = 'NextDir', event_pro = 'Overview_NextDir')
channel = widget_button(r0, /menu, uname = 'TChannelList', value =      'CHANNEL:     ')

schannel = widget_button(r0, /menu, uname = 'SChannelList', value =     'SPECTRUM:     ')



label1 = widget_label(r2, uname = 'TFileName', /dynamic_resize, value = 'FILE:                    ')
label2 = widget_label(r2, uname = 'TProperties', /dynamic_resize, value = 'FEEDBACK:                    ')
label3 = widget_label(r2, uname = 'TArea', /dynamic_resize, value =       'AREA:                        ')


r3=widget_base(app, /row, /base_align_left)

TWindow = widget_draw(r3,/button_events, xsize = xsze, ysize = ysze, event_pro = 'Overview_AtDrawEv', $
  uname = 'TDraw')



tools = widget_base(r3,/column,uname = 'Tools')
butts=widget_base(tools,/column,uname = 'Butts')
radios=widget_base(tools,/column,uname = 'Radios',/nonexclusive)
;butt2 = widget_base(tools, /column,frame = 0)
;butt4 = widget_base(tools, frame = 0)




;butt3 = widget_base(tools, frame = 0,/nonexclusive,/column)
;butt4 = widget_base(tools, frame = 0,/nonexclusive,/column)


showall = widget_button(butts, value = 'Reload', event_pro = 'Overview_ShowAllTopo', sensitive = 1, $
  uname = 'ShowAllTopoButton')

palette = widget_button(butts, value = 'Palette', event_pro = 'pal_handler', sensitive=1)

goldpal = widget_button(butts, value = 'GoldPal.', event_pro = 'GoldPal', sensitive=1)



select = widget_button(radios, value = 'Selected', event_pro = 'Overview_SelectToList', uname = 'SelectToList')
;TruncExtremes = widget_button(butt5, value = 'TruncExtremes', event_pro = 'Overview_TruncExtremes')
SubtrPlaneButton = widget_button(radios , value = 'Slope', event_pro = 'Overview_SubtrPlaneSelect')
LocalPlaneButton = widget_button(radios, value = 'Local', event_pro = 'Overview_LocalPlaneSelect')

InterpButton = widget_button(radios , value = 'Interpolate', event_pro = 'Overview_InterpSel')

smoothit = widget_button(radios , value = 'Smooth(3x3)', event_pro = 'Overview_SmoothSelect')


ShowGridButton = widget_button(radios, value = 'Show grid', event_pro = 'Overview_ShowGridSelect')

InvertColorButton = widget_button(radios, value = 'InvertColors', event_pro = 'Overview_InvertColorSelect')
profileButton = widget_button(radios, value = 'Profile', event_pro = 'Overview_ProfileSelect')

r4=widget_base(app, /row, /base_align_left)

SWindow = widget_draw(r4, xsize = xsze, ysize = (2*ysze)/5, uname = 'SDraw')
stools = widget_base(r4,/column,uname = 'Tools')

sradios=widget_base(stools,/column,uname = 'Radios',/nonexclusive)
Cdrawbutton = widget_button(sradios , value = 'Intensity', event_pro = 'Overview_CDrawSelect')
lmaxbutton=widget_button(sradios , value = 'Maxima', event_pro = 'Overview_lmaxSelect')
ldbutt=widget_button(sradios , value = 'dY/dX', event_pro = 'Overview_ldselect')
lndbutt=widget_button(sradios , value = 'dlnY/dlnX', event_pro = 'Overview_lndselect')

sbutts=widget_base(stools,/column,uname = 'Sbutts')
xppts=widget_button(sbutts , value = 'Export pts', event_pro = 'Overview_xppts')


;widget_control, TruncExtremes, set_button = descr.TruncExtremes
widget_control, SubtrPlaneButton, set_button = descr.SubtrPlane
widget_control, LocalPlaneButton, set_button = descr.LocalPlane
;widget_control, ShowGridButton, set_button= descr.ShowGrid
widget_control, InvertColorButton, set_button = descr.InvertColors
widget_control, InterpButton, set_button = descr.Interpolate
widget_control, smoothit, set_button = descr.smooth
widget_control, cdrawbutton, set_button = descr.cdraw
widget_control, lmaxbutton, set_button = descr.lmax
widget_control, profilebutton, set_button = descr.profile
widget_control, ldbutt, set_button = descr.ld
widget_control, lndbutt, set_button = descr.lnd



;vykresleni widgetove struktury a zapis datove struktury
widget_control, app, /realize
widget_control, twindow, get_value = twin
descr.TWindow = twin


widget_control, swindow, get_value = swin
descr.SWindow = swin
wset,swin
;device,decomposed=0,retain=2
wset,twin
;device,decomposed=0,retain=2


widget_control, app, set_uvalue = descr
;GoldPalette

;spusteni aplikace
if OK then call_procedure, 'Overview_OpenFiles', app, data, description = descr
xmanager, 'STMA', app, event_handler = 'Overview_AtTLBEvent'
list = *OUTPUT_INTERFACE_GATE
ptr_free, OUTPUT_INTERFACE_GATE
return, list
end

pro Overview_DestructApp, id
widget_control, id, get_uvalue = descr

;extrakce vystupniho parametru z widgetove casti aplikace
list = ''
for i = 0, descr.n - 1 do begin
 item = (*descr.Data)[i].ParFile
 if (*descr.Selected)[i] then begin
   if not keyword_set(list) then list = item else list = [list, item]
 endif
endfor
*descr.OUTPUT_INTERFACE_GATE = list

;ruseni dynamickych promenych
if ptr_valid(descr.Data) then begin
  ClearSTM, *descr.Data
  ptr_free, descr.Data
endif
ptr_free, descr.Selected

;obnova grafiky (cernobila paleta)
Palette = descr.OldPalette
tvlct, Palette.r, Palette.g, Palette.b
end


pro Overview_Quit, ev
;Ukonceni programu
;answer = dialog_message('Do you really want to quit the application?', /question, $
;  dialog_parent = ev.top)
;if answer EQ 'Yes' then $
widget_control, ev.top, /destroy
end


pro Overview_AtTLBEvent, ev
;Osetreni udalosti tykajicich se hlavniho okna programu
case tag_names(ev, /structure_name) of
'WIDGET_KILL_REQUEST': Overview_Quit, ev; application close button pressed
;'WIDGET_BASE': widgetcontrol, ev.top, scr_xsize = ev.x, scr_ysize = ev.y
else: print, !ERROR_STATE.MSG_PREFIX + 'Unprocessed event'
endcase
end


pro Overview_RedrawTopography, top, result,description = descr, win = win
;Procedura prekresli topograficky obrazek v souladu s aktualnim stavem popisujici promenne
;top = identifikacni cislo vrcholoveho widgetu aplikace
;descr = strukturovana promenna popisujici stav aplikace
;win = cislo grafickeho okna, do nehoz se ma kreslit (pri kresleni do okna programu netreba zadavat)
;result = promenna do niz se zapise vysledek prekresleni


if not keyword_set(descr) then widget_control, top, get_uvalue = descr
if n_elements(win) EQ 0 then win = descr.TWindow
ImagePointer = (*descr.Data)[descr.Index].Images[descr.TChannel - 1]
if ptr_valid(ImagePointer) then img = *ImagePointer else img = 0
wset,descr.Twindow

if not keyword_set(img) then begin
  ;neni co kreslit
  oldwin = !D.WINDOW
  wset, win
  device, decomposed = 1
  tv, intarr(!D.X_SIZE, !D.Y_SIZE)
  device, decomposed = 0
  if oldwin GE 0 then wset, oldwin
  return
endif


if descr.InvertColors then img = -img
;if descr.TruncExtremes then img = Truncate(img,2,/avr)

;if not(descr.LocalPlane) then begin ;only global filters

;if descr.SubtrPlane then img = SubtrPlane(img)

;end

if descr.smooth then begin ;universal filters

img = smooth(img,3,/edge_truncate) 

end




xsize = (size(img))[1]
ysize = (size(img))[2]
x1 = descr.tx1 < (xsize-1) 
x2 = descr.tx2 < (xsize-1)
y1 = descr.ty1 < (ysize-1)
y2 = descr.ty2 < (ysize-1)
img = img[x1:x2, y1:y2]

;if descr.LocalPlane then begin ;only local filters

if descr.SubtrPlane then img = SubtrPlane(img)

if descr.LocalPlane then img = RowsEqual(img,/backplane) else img = RowsEqual(img)

;end

results=img 				;!! 



img = TvScaled(img, mincolor = 1, maxcolor = !D.TABLE_SIZE - 2)
xsize = x2 - x1 + 1
ysize = y2 - y1 + 1

xmaxpix = (*descr.Data)[descr.Index].Parameters.XPixels
ymaxpix = (*descr.Data)[descr.Index].Parameters.YPixels
xgrid = (*descr.Data)[descr.Index].Parameters.XGrid
ygrid = (*descr.Data)[descr.Index].Parameters.YGrid    
schannels = (*descr.Data)[descr.Index].Parameters.SChannels

if (descr.ShowGrid) and (schannels GT 0) and (descr.TopoZoom EQ 0) then begin
  ;vyznaceni mrizky bodu, v nichz se snimala spektra
  irr = where((*descr.Data)[descr.Index].IrregularGrid.n GT 0, countirr)
  if (countirr EQ 0) and (xgrid GT 0) and (ygrid GT 0) and (xgrid * ygrid GT 1) then begin
    ;pravidelna mrizka
    nx = (xmaxpix - 1) / xgrid + 1
    ny = (ymaxpix - 1) / ygrid + 1
    grid = bytarr(xgrid, nx, ygrid, ny)
    grid[0, *, 0, *] = 1
    grid = (reform(grid, nx * xgrid, ny * ygrid))[0: xmaxpix-1, 0: ymaxpix-1]
    grid = grid[x1:x2, y1:y2]
    img = img * (1 - grid) + 0B * grid
  endif
  if (countirr GT 0) then begin
    ;nepraidelna mrizka
    grid = bytarr(xmaxpix, ymaxpix)
    irr = min(irr)
    xcoords = *(*descr.Data)[descr.Index].IrregularGrid[irr].x
    ycoords = *(*descr.Data)[descr.Index].IrregularGrid[irr].y
    ncoords = (*descr.Data)[descr.Index].IrregularGrid[irr].n
    incrx = (*descr.Data)[descr.Index].Parameters.IncrementX
    incry = (*descr.Data)[descr.Index].Parameters.IncrementY
    textx = intarr(ncoords)
    texty = intarr(ncoords)
    texti = strarr(ncoords)
    winxsize = !D.X_SIZE
    winysize = !D.Y_SIZE
    for i = 0, ncoords - 1 do begin
      texti[i] = strcompress(string(i + 1), /remove_all)
      nx = 0 > fix(xcoords[i] / incrx + 0.5) < (xmaxpix - 1)
      ny = 0 > fix(ycoords[i] / incry + 0.5) < (ymaxpix - 1)
      grid[nx, ny] = 1
      nx = (nx - x1) * long(winxsize) / (x2 - x1 + 1)
      ny = (ny - y1) * long(winysize) / (y2 - y1 + 1)
      xps = winxsize / (x2 - x1 + 1)
      yps = winysize / (y2 - y1 + 1)
      if (nx + 10 + xps) GE winxsize then nx = nx - 10 else nx = nx + xps
      if (ny + 10 + yps) GE winysize then ny = ny - 10 else ny = ny + yps 
      if (nx LT 0) or (nx GE winxsize) then begin
        nx = 0
        texti[i] = ''
      endif
      if (ny LT 0) or (ny GE winysize) then begin
        ny = 0
        texti[i] = ''
      endif
      textx[i] = nx
      texty[i] = ny
    endfor
    grid = grid[x1:x2, y1:y2]
    img = img * (1 - grid)
  endif
endif

oldwin = !D.WINDOW
wset, win


if (xsize EQ !D.X_SIZE) and (ysize EQ !D.Y_SIZE) then img= img $
else begin
if descr.Interpolate then img=congrid(img, !D.X_SIZE, !D.Y_SIZE, cubic=-0.5) else $
img=congrid(img, !D.X_SIZE, !D.Y_SIZE)
help,img
img=tvscaled(img, maxcolor=!D.TABLE_SIZE-2, mincolor=1)
endelse

tv,img


if descr.profile then begin
print,'drawing profile'
device,set_graphics_function=6
print,descr.px1,descr.px2
print,descr.py1,descr.py2

plots,[descr.px1,descr.px2],[descr.py1,descr.py2],thick=2,color=255,/device

device,set_graphics_function=3
end


if keyword_set(result) then begin

print,'returning raw image'
if descr.Interpolate then result=congrid(results, !D.X_SIZE, !D.Y_SIZE, cubic=-0.5) else $
result=congrid(results, !D.X_SIZE, !D.Y_SIZE)


;result=congrid(results, !D.X_SIZE, !D.Y_SIZE)

help,result
end

if keyword_set(texti) then for i = 0, n_elements(texti) - 1 do begin
  device,set_graphics_function=6
  xyouts, textx[i], texty[i], texti[i], size=1.5, charthick=2.0,color = 255, /device
  plots, textx[i], texty[i],thick=2.0,color=255,psym=1,/device
  device,set_graphics_function=3
endfor

if oldwin GE 0 then wset, oldwin
end


pro Overview_UpdateTopography, top, description = descr
;Aktualizuje topograficky widget - obrazek i popisky - s nasledujicimi vyjimkami:
; - nevytvari novou nabidku kanalu, to je zalezitosti procedury UpdateApp
; - neaktualizuje popisek vybraneho kanalu, to je zalezitosti procedury TChannelSelect
;top = identifikacni cislo vrcholoveho widgetu aplikace
;descr = stavova promenna aplikace

if not keyword_set(descr) then widget_control, top, get_uvalue = descr
Par = (*descr.Data)[descr.Index].Parameters
descr.TChannel = 1 > descr.TChannel < Par.TChannels
id1 = widget_info(top, find_by_uname = 'Top')
id2 = widget_info(top, find_by_uname = 'Tools')
if Par.TChannels LE 0 then begin
  ;zadne topograficke kanaly
  widget_control, id1, map = 0
  return
endif
widget_control, id1, /map
widget_control, id2, /map
inx = descr.TChannel - 1
filename = Par.Topography[inx].FileName
resolution = Par.Topography[inx].Resolution
unit = Par.Topography[inx].Unit
direction = Par.Topography[inx].Direction
if direction EQ 'forward' then begin
  voltage = Par.VoltageForward
  current = Par.CurrentForward
endif
if direction EQ 'backward' then begin
  voltage = Par.VoltageBackward
  current = Par.CurrentBackward
endif
incrx = Par.IncrementX
incry = Par.IncrementY
xsize = descr.tx2 - descr.tx1 + 1
ysize = descr.ty2 - descr.ty1 + 1

label = widget_info(top, find_by_uname = 'TFileName')
widget_control, label, set_value = 'FILE: ' + filename
label = widget_info(top, find_by_uname = 'TProperties')
if (direction EQ 'forward') or (direction EQ 'backward') then widget_control, label, set_value = $
  string(voltage, current, format = '("FEEDBACK: ", F7.3, "V, ", F7.3, "nA")') $
else widget_control, label, set_value = ''
widget_control, widget_info(top, find_by_uname = 'TArea'), set_value = $
  string(xsize * incrx, ysize * incry, format = '("AREA:   ", F7.2, "nm x ", F7.2, "nm")')
widget_control, top, set_uvalue = descr
Overview_RedrawTopography, top, description = descr
end


pro Overview_UpdateApp, top, description = descr
;Nejobecnejsi aktualizacni procedura. Nastavi vsechny vystupy i ovladaci prvky aplikace
;v souladu s aktualnim staven popisujici promenne
;top = identifikacni cislo vrcholoveho widgetu aplikace
;descr = strukturovana promenna popisujici stav aplikace


if not keyword_set(descr) then widget_control, top, get_uvalue = descr
if not ptr_valid(descr.Data) then descr.n = 0 $
else if not keyword_set(*descr.Data) then descr.n = 0 else descr.n = n_elements(*descr.Data)
if descr.n GT 0 then begin
  descr.Index = descr.Index < (descr.n - 1)
  Par = (*descr.Data)[descr.Index].Parameters 
  descr.TopoZoom = 0
  descr.tx1 = 0
  descr.tx2 = Par.XPixels - 1
  descr.ty1 = 0
  descr.ty2 = Par.YPixels - 1
  parfile = (*descr.Data)[descr.Index].ParFile
  if keyword_set(Par.Time) then timeh = Par.Time else timeh="N/A"
  headertext = '.par FILE: ' + parfile + " TIME: " + timeh
  k = (*descr.Data)[descr.Index].Parameters.schannels[0]
  ;help,k
;  timeh=timeh + ' SPECTRAL CHANNELS: ' + strcompress(string(k))
  widget_control, widget_info(top, find_by_uname = 'Header'), set_value = headertext
;  widget_control, widget_info(top, find_by_uname = 'Timeh'), set_value = timeh
  comment = Par.Comment
  if keyword_set(comment) then comment =  'COMMENT: ' + comment

  widget_control, widget_info(top, find_by_uname = 'Comment'), set_value = comment

  ;vytvoreni nove nabidky topografickych kanalu
  descr.TChannel = 1 > descr.TChannel < Par.TChannels
  inx = descr.TChannel
  channels = widget_info(top, find_by_uname = 'TChannelList')
  item = widget_info(channels, /child)
  while item NE 0L do begin 
    destr = item
    item = widget_info(item, /sibling)
    widget_control, destr, /destroy
  endwhile
  if Par.TChannels LE 0 then begin
    widget_control, channels, set_value = '                     '
  endif else for i = 1, Par.TChannels do begin
    text =  strcompress(string(i), /remove_all) + '(' + Par.Topography[i-1].Type + ')'
    if i EQ inx then widget_control, channels, set_value = 'CHANNEL: ' + text
    item = widget_button(channels, value = text, uvalue = i, event_pro = 'Overview_TChannelSelect')
  endfor

  ;vytvoreni nove nabidky spektroskopickych kanalu
  descr.SChannel = 1 > descr.SChannel < Par.SChannels
  sinx = descr.SChannel
  schannels = widget_info(top, find_by_uname = 'SChannelList')
  sitem = widget_info(schannels, /child)
  while sitem NE 0L do begin 
    sdestr = sitem
    sitem = widget_info(sitem, /sibling)
    widget_control, sdestr, /destroy
  endwhile
  if Par.SChannels LE 0 then begin
    widget_control, schannels, set_value = '    N/A    '
  endif else for i = 1, Par.SChannels do begin
    text =  strcompress(string(i), /remove_all) + '(' + Par.spectroscopy[i-1].Type + ')'
    if i EQ sinx then widget_control, schannels, set_value = 'SPECTRUM: ' + text
    sitem = widget_button(schannels, value = text, uvalue = i, event_pro = 'Overview_SChannelSelect')
  endfor



  ;nastaveni podoby nekterych ovladacich prvku
  widget_control, widget_info(top, find_by_uname = 'CloseFiles'), sensitive = 1
  widget_control, widget_info(top, find_by_uname = 'NextFile'), sensitive = $
    ((descr.Index + 1) LT descr.n) mod 2
  widget_control, widget_info(top, find_by_uname = 'PreviousFile'), sensitive = $
    (descr.Index GT 0) mod 2
  widget_control, widget_info(top, find_by_uname = 'SaveList'), sensitive = $
    (total(*descr.Selected) GT 0) mod 2
  widget_control, widget_info(top, find_by_uname = 'SelectToList'), set_button = (*descr.Selected)[descr.Index]

  Overview_UpdateTopography, top, description = descr
  

endif else begin
  widget_control, widget_info(top, find_by_uname = 'Header'), set_value = ''
;  widget_control, widget_info(top, find_by_uname = 'Timeh'), set_value = ''

  widget_control, widget_info(top, find_by_uname = 'Comment'), set_value = ''
  widget_control, widget_info(top, find_by_uname = 'Top'), map = 0
  widget_control, widget_info(top, find_by_uname = 'Tools'), map = 0
  widget_control, widget_info(top, find_by_uname = 'CloseFiles'), sensitive = 0
  widget_control, widget_info(top, find_by_uname = 'NextFile'), sensitive = 0
  widget_control, widget_info(top, find_by_uname = 'PreviousFile'), sensitive = 0
  widget_control, widget_info(top, find_by_uname = 'SaveList'), sensitive = 0
  
  ;zacerneni okna
  oldwin = !D.WINDOW
  wset, descr.TWindow
  device, decomposed = 1
  tv, intarr(!D.X_SIZE, !D.Y_SIZE)
  device, decomposed = 0 
  if oldwin GE 0 then wset, oldwin

  widget_control, top, set_uvalue = descr
endelse
end


pro Overview_CloseFiles, top, mask, description = descr, indices = ind1
;Vymaze vybrane datove polozky  pameti programu
;top = identifikacni cislo vrcholoveho widgetu aplikace
;mask = booleeovske pole, urcujici, ktere polozky maji byt smazany
;  1 = smazat
;  0 = nemazat
;descr = strukturovana promenna popisujici stav aplikace
;ind1 = pole indexu, oznacujicich datove polozky ke smazani (nahrazuje pole mask)

if not keyword_set(descr) then widget_control, top, get_uvalue = descr
if descr.n LE 0 then return
if keyword_set(ind) then begin
  mask = bytarr(descr.n)
  mask[ind1] = 1
endif else begin
  if not keyword_set(mask) then return
  if n_elements(mask) LT descr.n then mask = [mask, replicate(0B, descr.n -n_elements(mask))]
  if n_elements(mask) GT descr.n then mask = mask[0: descr.n-1]
  ind1 = where(mask EQ 1, count1)
endelse
ind0 = where(mask EQ 0, count0)
void = where((mask EQ 1) and (indgen(descr.n) LT descr.Index), count)
if count1 GT 0 then begin
  ClearStm, (*descr.Data)[ind1]
endif
if count0 GT 0 then begin
  *descr.Data = (*descr.Data)[ind0]
  *descr.Selected = (*descr.Selected)[ind0]
endif else begin
  *descr.Data = 0
  *descr.Selected = 0
endelse
descr.n = count0
descr.Index = (descr.Index - count) < (count0 - 1)
Overview_UpdateApp, top, description = descr
end


pro Overview_OpenFiles, top, newdata, description = descr
;Prida data z nove otevrenych souboru do pameti programu
;top = identifikacni cislo vrcholoveho widgetu aplikace
;newdata = pole novych datovych polozek
if not keyword_set(descr) then widget_control, top, get_uvalue = descr
if not keyword_set(newdata) then return
n = n_elements(newdata)
if descr.n EQ 0 then begin
  if not ptr_valid(descr.Data) then descr.Data = ptr_new(newdata) else *descr.Data = newdata
  if not ptr_valid(descr.Selected) then descr.Selected = ptr_new(bytarr(n)) else *descr.Selected = bytarr(n)
endif else begin
  *descr.Data = [*descr.Data, newdata]
  *descr.Selected = [*descr.Selected, bytarr(n)]
endelse
descr.Index = descr.n
descr.n = descr.n + n

;Serazeni datovych polozek podle jmena souboru
;Pouzivam bublinkove trideni
indices = indgen(descr.n)
last = descr.n
while last GT 0 do begin
  last_swap = 0
  i = 1
  while i LT last do begin
  if not Sorted((*descr.Data)[indices[i-1]].ParFile, (*descr.Data)[indices[i]].ParFile) then begin
    j = indices[i-1]
    indices[i-1] = indices[i]
    indices[i] = j
    last_swap = i
  endif
  i = i + 1
  endwhile
  last = last_swap
endwhile
*descr.data = (*descr.data)[indices]
*descr.Selected = (*descr.Selected)[indices]
descr.Index = (where(indices GE descr.Index))[0]

Overview_UpdateApp, top, description = descr
end


pro Overview_OpenFileDialog, ev, dir
;Otevre soubory s novymi daty - nejprve interaktivne parametricky soubor *.par,
;pak soubory s topografii a spektry uvedene v parametrickem souboru
;Data z drive otevrenych souboru budou vymazana z pameti


NewData = LoadSTM(filez, directory = directory, OK = OK, ParentID = ev.top)
if keyword_set(directory) then cd, directory
if not OK then return
widget_control, ev.top, get_uvalue = descr, update = 0
if descr.n GT 0 then Overview_CloseFiles, ev.top, replicate(1B, descr.n), description = descr; close all
Overview_OpenFiles, ev.top, NewData, description = descr


widget_control, ev.top, /update
end

pro Overview_OpenDirList, ev
widget_control, ev.top, get_uvalue = descr, update = 0
dirlist_path=dialog_pickfile()
print,dirlist_path
if (dirlist_path eq "") then return 
directory=dialog_pickfile(/directory, title='Select a directory to read from')
if (directory eq "") then return
;spawn,'cat '+dirlist_path,dirlist

dirlist_arr=strarr(9999)
openr,1,dirlist_path
i=0
while not eof(1) do begin
line=''
readf,1,line
print,line,i
dirlist_arr(i)=line

i=i+1
end
close,1

dirlist=dirlist_arr(0:i-1)

help,dirlist
;print,dirlist
*descr.dirlist=dirlist

directory=directory+dirlist(0)
print,directory
;spawn,'ls '+directory+'/*.par',filez
if keyword_set(directory) then cd, directory
filez=file_search('*.par')
if filez(0) then begin
NewData = LoadSTM(filez, directory = directory, OK = OK, ParentID = ev.top)
if keyword_set(directory) then cd, directory
if not OK then return
end else print,'Error, giving up.'

widget_control, ev.top, get_uvalue = descr, update = 0
if descr.n GT 0 then Overview_CloseFiles, ev.top, replicate(1B, descr.n), description = descr; close all
Overview_OpenFiles, ev.top, NewData, description = descr
widget_control, ev.top, /update
end

pro Overview_OpenDirectory, ev
widget_control, ev.top, get_uvalue = descr, update = 0
directory=dialog_pickfile(/directory)
if (directory eq "") then return
print,directory
if keyword_set(directory) then cd, directory
filez=file_search('*.par')
if filez(0) then begin
NewData = LoadSTM(filez, directory = directory, OK = OK, ParentID = ev.top)
if keyword_set(directory) then cd, directory
if not OK then return
end else print,'Error, giving up.'

widget_control, ev.top, get_uvalue = descr, update = 0
if descr.n GT 0 then Overview_CloseFiles, ev.top, replicate(1B, descr.n), description = descr; close all
Overview_OpenFiles, ev.top, NewData, description = descr
*descr.dirlist=0
widget_control, ev.top, /update
end


pro Overview_NextDir, ev
;Otevre soubory s novymi daty - nejprve interaktivne parametricky soubor *.par,
;pak soubory s topografii a spektry uvedene v parametrickem souboru
;Data z drive otevrenych souboru budou vymazana z pameti
widget_control, ev.top, get_uvalue = descr, update = 0

directory=(*descr.data).dir
directory=directory(descr.Index)
dirlist=*descr.dirlist
;help,dirlist
;print,dirlist
;help,*descr.dirlist
directory=updown_dir(directory, 1,dirlist=dirlist)

if directory eq "false" then return else cd,directory
print,directory

filez=file_search('*.par')

NewData = LoadSTM(filez, directory = directory, OK = OK, ParentID = ev.top)
if keyword_set(directory) then cd, directory
if not OK then return
widget_control, ev.top, get_uvalue = descr, update = 0
if descr.n GT 0 then Overview_CloseFiles, ev.top, replicate(1B, descr.n), description = descr; close all
Overview_OpenFiles, ev.top, NewData, description = descr
widget_control, ev.top, /update
end




pro Overview_PrevDir, ev
;Otevre soubory s novymi daty - nejprve interaktivne parametricky soubor *.par,
;pak soubory s topografii a spektry uvedene v parametrickem souboru
;Data z drive otevrenych souboru budou vymazana z pameti
widget_control, ev.top, get_uvalue = descr, update = 0

directory=(*descr.data).dir
directory=directory(descr.Index)
dirlist=*descr.dirlist
;help,dirlist
;print,dirlist
;help,*descr.dirlist
directory=updown_dir(directory, -1,dirlist=dirlist)

if directory eq "false" then return else cd,directory
print,directory
filez=file_search('*.par')


NewData = LoadSTM(filez, directory = directory, OK = OK, ParentID = ev.top)
if keyword_set(directory) then cd, directory
if not OK then return
widget_control, ev.top, get_uvalue = descr, update = 0
if descr.n GT 0 then Overview_CloseFiles, ev.top, replicate(1B, descr.n), description = descr; close all
Overview_OpenFiles, ev.top, NewData, description = descr
widget_control, ev.top, /update
end



pro Overview_AddFiles, ev
;Otevre soubory s novymi daty (nejprve interaktivne parametricky soubor *.par,
;pak soubory s topografii a spektry uvedene v parametrickem souboru)
;Data z drive otevrenych souboru zustavaji z pameti


NewData = LoadSTM(directory = directory, OK = OK, ParentID = ev.top)
if keyword_set(directory) then cd, directory
if not OK then return
widget_control, ev.top, update = 0
Overview_OpenFiles, ev.top, NewData, description = descr
widget_control, ev.top, /update
end


pro Overview_CloseFileDialog, ev
;Vytvori dialogove okno, v nemz si uzivatel muze vybrat soubory ke smazani
;Data pochazejici z vybranych souboru budou pak vymazana z pameti

widget_control, ev.top, get_uvalue = descr
if descr.n EQ 0 then return

base = widget_base(group_leader = ev.top, /column, title = 'Select data to remove', $
  event_pro = 'Overview_AtCloseFilesEv', uvalue = {root: ev.top, sel: bytarr(descr.n)})
;root = identifikacni cislo zakladniho widgetu aplikace
;sel = booleovske pole, urcujici, ktere soubory byly vybrany k uzavreni

list = widget_base(base, /column, /nonexclusive, uname = 'ListOfFiles')
for i = 0, descr.n - 1 do begin
  filename = (*descr.Data)[i].ParFile
  ExtPos = strpos(filename, '.par')
  if (ExtPos GE 0) and ((ExtPos + 4) EQ strlen(filename)) then $ 
    filename = strmid(filename, 0, ExtPos); odstraneni pripony ".par"
  item = widget_button(list, value = filename, uname = 'Item', uvalue = i)
endfor
control = widget_base(base, /row)
ok = widget_button(control, value = 'OK', uname = 'OK')
cancel = widget_button(control, value = 'Cancel', uname = 'Cancel')
widget_control, base, /realize
end


pro Overview_AtCloseFilesEv, ev
;Osetreni udalosti v dialogovem okne otevrenem procedurou CloseFiles

widget_control, ev.top, get_uvalue = descr
case widget_info(ev.id, /uname) of
'Item': begin
  widget_control, ev.id, get_uvalue = i
  descr.sel[i] = ev.select
  widget_control, ev.top, set_uvalue = descr
  end
'OK': begin
  widget_control, ev.top, /destroy
  widget_control, descr.root, update = 0
  Overview_CloseFiles, descr.root, descr.sel
  widget_control, descr.root, /update
  end  
'Cancel': widget_control, ev.top, /destroy
endcase
end


pro Overview_SaveList, ev
filename = dialog_pickfile(/write, get_path = directory)
if filename EQ '' then return
if keyword_set(directory) then cd, directory
widget_control, ev.top, get_uvalue = descr
if descr.n LE 0 then return
openw, LUN, filename, /get_LUN
for i = 0, descr.n - 1 do begin
  if (*descr.Selected)[i] then printf, LUN, (*descr.Data)[i].ParFile
endfor
free_LUN, LUN
end


pro Overview_NextFile, ev
;posun k nasledujicimu otevrenemu souboru
widget_control, ev.top, get_uvalue = descr
if (descr.Index + 1) LT descr.n then begin
  descr.Index = descr.Index + 1
  widget_control, ev.top, update = 0, set_uvalue = descr
  Overview_UpdateApp, ev.top, description = descr
  widget_control, ev.top, /update 
print,'?'
endif
end


pro Overview_PrevFile, ev
;posun k predchazejicimu otevrenemu souboru
widget_control, ev.top, get_uvalue = descr
if descr.Index GT 0 then begin
  descr.Index = descr.Index - 1
  widget_control, ev.top, update = 0, set_uvalue= descr
  Overview_UpdateApp, ev.top, description = descr
  widget_control, ev.top, /update 
endif
end


pro Overview_TChannelSelect, ev
;zmeni aktualni topograficky kanal
widget_control, ev.top, get_uvalue = descr, update = 0
widget_control, ev.id, get_uvalue = channel, get_value = text
widget_control, widget_info(ev.id, /parent), set_value = 'CHANNEL: ' + text
descr.TChannel = channel
widget_control, ev.top, set_uvalue = descr
Overview_UpdateTopography, ev.top, description = descr
widget_control, ev.top, /update
end

pro Overview_SChannelSelect, ev
;zmeni aktualni topograficky kanal
widget_control, ev.top, get_uvalue = descr, update = 0
widget_control, ev.id, get_uvalue = schannel, get_value = text
widget_control, widget_info(ev.id, /parent), set_value = 'SPECTRAL CHANNEL: ' + text
descr.SChannel = schannel
widget_control, ev.top, set_uvalue = descr
Overview_Spectrum_Select, ev.top,-1
widget_control, ev.top, /update
end


pro Overview_TruncExtremes, ev
;vybrano nebo zruseno orezavani extremnich hodnot
widget_control, ev.top, get_uvalue = descr
descr.Trunc_Extremes = ev.select
widget_control, ev.top, set_uvalue = descr
Overview_RedrawTopography, ev.top, description = descr
end

pro Overview_SubtrPlaneSelect, ev
;vybrano nebo zruseno odecitani sklonu
widget_control, ev.top, get_uvalue = descr
descr.SubtrPlane = ev.select
widget_control, ev.top, set_uvalue = descr
Overview_RedrawTopography, ev.top, description = descr
end


pro Overview_cdrawSelect, ev
;vybrano nebo zruseno 
widget_control, ev.top, get_uvalue = descr
descr.cdraw = ev.select
widget_control, ev.top, set_uvalue = descr
Overview_Spectrum_Redraw, ev.top
end

pro Overview_ldSelect, ev
;vybrano nebo zruseno 
widget_control, ev.top, get_uvalue = descr
descr.ld = ev.select
widget_control, ev.top, set_uvalue = descr
Overview_Spectrum_Redraw, ev.top
end

pro Overview_lndSelect, ev
;vybrano nebo zruseno 
widget_control, ev.top, get_uvalue = descr
descr.lnd = ev.select
widget_control, ev.top, set_uvalue = descr
Overview_Spectrum_Redraw, ev.top
end

pro Overview_InterpSel, ev
;vybrano nebo zruseno odecitani sklonu
widget_control, ev.top, get_uvalue = descr
descr.Interpolate = ev.select
widget_control, ev.top, set_uvalue = descr
Overview_RedrawTopography, ev.top, description = descr
end


pro Overview_LocalPlaneSelect, ev
;zapnuto nebo vypnuto vyrovnavani radku
widget_control, ev.top, get_uvalue = descr
descr.LocalPlane = ev.select
widget_control, ev.top, set_uvalue = descr
Overview_RedrawTopography, ev.top, description = descr
end


pro Overview_SmoothSelect, ev
;zapnuto nebo vypnuto vyhlazeni
widget_control, ev.top, get_uvalue = descr
descr.smooth = ev.select
widget_control, ev.top, set_uvalue = descr
Overview_RedrawTopography, ev.top, description = descr
end


pro Overview_InvertColorSelect, ev
;zapnuti nebo vypnuti inverze barevne skaly
widget_control, ev.top, get_uvalue = descr
descr.InvertColors = ev.select
widget_control, ev.top, set_uvalue = descr
Overview_RedrawTopography, ev.top, description  = descr
end

pro Overview_ShowGridSelect, ev
;zapnuto nebo vypnuto zobrazovani spektroskopicke mrizky v topografickem okne
widget_control, ev.top, get_uvalue = descr
descr.ShowGrid = ev.select
widget_control, ev.top, set_uvalue = descr
Overview_RedrawTopography, ev.top, description = descr
end


pro Overview_SelectToList, ev
widget_control, ev.top, get_uvalue = descr
(*descr.Selected)[descr.Index] = ev.select
widget_control, ev.top, set_uvalue = descr
end

pro Overview_ShowAllTopo, ev
;zobrazeni cele topografie namisto vyrezu
widget_control, ev.top, get_uvalue = descr
descr.TopoZoom = 0
widget_control, ev.id, sensitive = 1
descr.tx1 = 0
descr.tx2 = (*descr.Data)[descr.Index].Parameters.XPixels - 1
descr.ty1 = 0
descr.ty2 = (*descr.Data)[descr.Index].Parameters.YPixels - 1
widget_control, ev.top, set_uvalue = descr, update = 0
Overview_UpdateTopography, ev.top, description = descr
widget_control, ev.top, /update
end


pro Overview_ZoomIn, top, x1, y1, x2, y2
;Zobrazeni detailniho vyrezu z topografie

widget_control, top, get_uvalue = descr
wset, descr.TWindow
WinXSize = !D.X_SIZE
WinYSize = !D.Y_SIZE
ImgXSize = (*descr.Data)[descr.Index].Parameters.XPixels
ImgYSize = (*descr.Data)[descr.Index].Parameters.YPixels
xo = descr.tx1
yo = descr.ty1
dx = long(descr.tx2 - descr.tx1 + 1)
dy = long(descr.ty2 - descr.ty1 + 1)
x1 = 0 > (xo + (x1 * dx) / WinXSize) < (ImgXSize - 1)
y1 = 0 > (yo + (y1 * dy) / WinYSize) < (ImgYSize - 1)
x2 = 0 > (xo + (x2 * dx) / WinXSize) < (ImgXSize - 1)
y2 = 0 > (yo + (y2 * dy) / WinYSize) < (ImgYSize - 1)
descr.tx1 = x1 < x2
descr.tx2 = x1 > x2
descr.ty1 = y1 < y2
descr.ty2 = y2 > y1

;uprava vyrezu na ctvercovy tvar
descr.tx2 = descr.tx2 > (descr.tx1 + descr.ty2 - descr.ty1)
descr.ty2 = descr.ty2 > (descr.ty1 + descr.tx2 - descr.tx1)

if not descr.TopoZoom then begin
  widget_control, widget_info(top, find_by_uname = 'ShowAllTopoButton'), /sensitive
endif
descr.TopoZoom = 1
widget_control, top, set_uvalue = descr, update = 0
Overview_UpdateTopography, top, description = descr
widget_control, top, /update
end

pro Overview_Spectrum_Select, top,x,y
;print,x,y
widget_control, top, get_uvalue = descr
dtt=(*descr.data)[descr.Index]

;print,(ptr_valid(dtt.spectra))

;print,descr.TOpozoom


if (descr.TopoZoom ne 0) or (not(ptr_valid(dtt.spectra[0]))) then return

ddt=*(dtt.spectra)[descr.Schannel-1]


;help,*(descr.data),/struct


;help,(dtt.irregulargrid),/struct


if x eq -1 then i=0 else begin
  ;spektroskopie na nepravidelne mrizi                                                    
  n = (size(ddt))[1]                                                      
 np = (size(ddt))[2]  
        
;print,n,np 
                                             
xsize = dtt.Parameters.XPixels
ddt=*(dtt.spectra)[descr.Schannel-1]                                   
ysize = dtt.Parameters.YPixels  


    winxsize = !D.X_SIZE
    winysize = !D.Y_SIZE
;print,x,y

x=x*xsize/winxsize
y=y*ysize/winysize


  incrx = dtt.Parameters.IncrementX                                                  
  incry = dtt.Parameters.IncrementY                                                  
  irrgrid = dtt.IrregularGrid[descr.SChannel-1]                    
  n = n < irrgrid.n                                                                       
  xcoords = 0 > fix((*irrgrid.x) / incrx + 0.5) < (xsize-1)                               
  ycoords = 0 > fix((*irrgrid.y) / incry + 0.5) < (ysize-1)
  
                                 
;  if descr.SinglePoint then begin                                                         
    r = abs(x - xcoords) + abs(y - ycoords)                                 
;   print,x,y                                                 
    r = min(r, i)                                                                         
    r=r(0)         

end
                                                                           
    print,'Using spectrum:',i+1                                                        
    as = ddt
    s=reform(as[i,*]); spektrum z jedineho bodu                              

axs = *(dtt.Xscl)[descr.SChannel-1]

as=reform(axs[i,*]); plus jeho xova souradnice

help,as
help,s


;print,as
;    descr.xpos = xcoords[i]                                                                  
;    descr.ypos = ycoords[i]                                                                  
    ;descr.NSpectraUsed = 1                                                                
 ; endif else begin                                                                        
;    reg = (*descr.Region)                                                                 
;    s = (*descr.Spectroscopy)                                                             
;    i = where(reg[xcoords, ycoords] EQ 1, count)                                          
;    if count GT 0 then s = total(s[i, *], 1) / count $; prumerne spektrum                 
;    else s = 0 * s[0, *]                                                                  
;    descr.NSpectraUsed = count                                                            
 ; endelse                                                                                 
;endelse           
*descr.spectrumx=as
*descr.spectrumy=float(s)
descr.sindex=i
widget_control, top, set_uvalue = descr, update = 0
Overview_Spectrum_Redraw,top
end

pro Overview_Spectrum_Redraw, top
;Zobrazeni krivky ze spektroskopie

widget_control, top, get_uvalue = descr


wset,descr.Swindow

yvl=*descr.spectrumy
xvl=*descr.spectrumx
mx=max(*(descr.spectrumy))
mn=min(*(descr.spectrumy))
xmx=max(*(descr.spectrumx))
xmn=min(*(descr.spectrumx))
;help,xvl
;print,min(xvl),max(xvl)
;help,yvl
;print,min(yvl),max(yvl)
srt=sort(xvl)
xvl=xvl(srt)
yvl=yvl(srt)
yy=yvl
xxvl=xvl

if descr.ld then begin
yy=didv(xvl,yvl)
xxvl=xvl(1:*)
xmx=max((xvl))
xmn=min((xvl))
end

if descr.lnd then begin
yy=dlnidlnv(xvl,yvl)
xxvl=xvl(1:*)
xmx=max((xvl))
xmn=min((xvl))
end

help,yy
;print,min(yy),max(yy)
;hh=h
;h=fltarr(2,n_elements(yy))
;h(0,*)=yy
;h(1,*)=yy
;if descr.cdraw then $
;contour,transpose(h),xvl,findgen(2)*(mx-mn)+mn,nlevels=60,/cell_fill,xst=1,yst=1 $
;else contour,transpose(h),xvl,findgen(2)*(mx-mn)+mn,nlevels=60,/cell_fill,xst=1,yst=1,/nodata

;device,set_graphics_function=6
mx=max((yy))
mn=min((yy))
plot,xxvl,yy,xrange=[xmn,xmx],yrange=[mn,mx],xst=1,yst=1;,color=255,thick=3
;device,set_graphics_function=3


if descr.lmax then begin
hh=bytscl(local_max(yy,n_elements(yy)/40))

ii=where(hh gt 0.)
ii=float(ii)/n_elements(hh)*(xmx-xmn)+xmn
for k=0,n_elements(ii)-1 do begin
plots,[ii(k),ii(k)],[mn,mx],color=255
device,set_graphics_function=6
xyouts,ii(k)-0.01*(xmx-xmn),(mx+mn)/2,strtrim(string(ii(k),format='(F5.2)'),2),orientation=90,color=255,charsize=1.3
device,set_graphics_function=3

end
end

wset,descr.Twindow

widget_control, top, /update
end

pro Overview_profile, top


;Zobrazeni profilu
widget_control, top, get_uvalue = descr
x1=descr.px1
x2=descr.px2
y1=descr.py1
y2=descr.py2

;      Overview_RedrawTopography,ev.top,img
;      if (x1 NE x2) or (y1 NE y2) then plots, [x1,x2], [y1,y2], thick=2,/device

img='true'
Overview_RedrawTopography,top,img

;      if ((x1 NE x2) or (y1 NE y2)) and descr.profile then plots, [x1,x2], [y1,y2], thick=2,/device
      
wset,descr.Swindow
res=(*descr.data)[descr.Index].parameters.topography[descr.TChannel-1].resolution
print,res
img=img*res
if img(0) ne 0 then plot,mprofile(img,x1,x2,y1,y2),xst=1,yst=1,yticklen=0.5
wset,descr.Twindow
Overview_RedrawTopography,top
widget_control, top, /update
end


pro Overview_ExportAsTiff, ev                                                                                

widget_control, ev.top, get_uvalue = descr
help,(*descr.Data)[descr.Index],/struct
filename = (*descr.Data)[descr.Index].ParFile
pos = strpos(filename, '.', /reverse_search)                                                               
if pos GE 0 then filename = strmid(filename, 0, pos)                                                       
filename = filename + '.tiff'                                                                              
filename = dialog_pickfile(/write, file = filename, filter = '*.tif', get_path = directory)               
if filename EQ '' then return                                                                                                                                                                    
print,filename
widget_control, ev.top, set_uvalue = descr, update = 0
tvlct, red, green, blue, /get                                                                              
;loadct, 0; loading grayscale for palette version                                                  
result='true'
Overview_RedrawTopography, ev.top, result, description = descr
help,result                                                                                 
;tvlct, red, green, blue                                                                                    
write_tiff, filename, result, 1, red = red, green = green, blue = blue                                    
cd, directory                                                                                              
widget_control, ev.top, /update

end                                                                                                        

pro Overview_ExportAsPNG, ev                                                                                

widget_control, ev.top, get_uvalue = descr
help,(*descr.Data)[descr.Index],/struct
filename = (*descr.Data)[descr.Index].ParFile
pos = strpos(filename, '.', /reverse_search)                                                               
if pos GE 0 then filename = strmid(filename, 0, pos)                                                       
filename = filename + '.png'                                                                              
filename = dialog_pickfile(/write, file = filename, filter = '*.png', get_path = directory)               
if filename EQ '' then return                                                                                                                                                                    
print,filename
widget_control, ev.top, set_uvalue = descr, update = 0
tvlct, red, green, blue, /get                                                                              

loadct, 0; loading grayscale for palette version                                                  

Overview_RedrawTopography, ev.top, description = descr                                                          
write_PNG, filename, tvrd(0), red, green, blue                                    

tvlct, red, green, blue                                                                                    

cd, directory                                                                                              
Overview_RedrawTopography, ev.top, description = descr                                                          

widget_control, ev.top, /update

end                                                                                                        

pro Overview_rmdrift, ev                                                                                

widget_control, ev.top, get_uvalue = descr
filename = (*descr.Data)[descr.Index].ParFile
pos = strpos(filename, '.', /reverse_search)                                                               
if pos GE 0 then filename = strmid(filename, 0, pos)                                                       
filename = filename + '.png'                                                                              
widget_control, ev.top, set_uvalue = descr, update = 0
tvlct, red, green, blue, /get                                                                              

loadct, 0; loading grayscale for palette version                                                  

Overview_RedrawTopography, ev.top, description = descr

;incrx=(*descr.Data)[descr.Index].PARAMETERS.INCREMENTX
;pxls=(*descr.Data)[descr.Index].PARAMETERS.XPIXELS
;print,descr.cellsize/(incrx*pxls)*float(descr.xze)/abs(descr.tx1-descr.tx2)

;fsize=(descr.cellsize/(incrx*pxls))*(float(descr.xze)/abs(descr.tx2-descr.tx1))*descr.xze

resl=removedrift2(smooth(tvrd(0),3,/edge),/hard)

filename = dialog_pickfile(/write, file = filename, filter = '*.png', get_path = directory)               
if filename EQ '' then return                                                                                                                                                                    
print,filename

write_PNG, filename, resl, red, green, blue                                    

tvlct, red, green, blue                                                                                    

cd, directory       
                                                                                       
;Overview_RedrawTopography, ev.top, description = descr                                                          

widget_control, ev.top, /update
end


pro Overview_rmdriftg, ev                                                                                

widget_control, ev.top, get_uvalue = descr
help,(*descr.Data)[descr.Index],/struct
widget_control, ev.top, set_uvalue = descr, update = 0
tvlct, red, green, blue, /get                                                                              

loadct, 0; loading grayscale for palette version                                                  

Overview_RedrawTopography, ev.top, description = descr
a=smooth(tvrd(0),3,/edge)                         
;reload

cnt = (*descr.Data)[descr.Index].PARAMETERS.TCHANNELS
print, "No of channels:",cnt
;if ptr_valid(ImagePointer) then img = *ImagePointer else img = 0

;help,ImagesPointer
;cnt=n_elements(ImagesPointer)
b=intarr(cnt,descr.xze,descr.yze)
bckup=descr.TChannel

for i=0,cnt-1 do begin
descr.TChannel=i+1
widget_control, ev.top, set_uvalue = descr, update = 0
Overview_ShowAllTopo,ev
b(i,*,*)=tvrd(0)
end
descr.TChannel=bckup
widget_control, ev.top, set_uvalue = descr, update = 0


;incrx=(*descr.Data)[descr.Index].PARAMETERS.INCREMENTX
;pxls=(*descr.Data)[descr.Index].PARAMETERS.XPIXELS
;print,descr.cellsize/(incrx*pxls)*float(descr.xze)/abs(descr.tx1-descr.tx2)

;fsize=(descr.cellsize/(incrx*pxls))*(float(descr.xze)/abs(descr.tx2-descr.tx1))*descr.xze

res=removedrift2(a,/hard,im_ori=b)

filename = (*descr.Data)[descr.Index].ParFile
pos = strpos(filename, 'ori.', /reverse_search)                                                               
if pos GE 0 then filename = strmid(filename, 0, pos)                                                       
filename = dialog_pickfile(/write, file = filename, get_path = directory)
if filename EQ '' then return

for i=0,cnt-1 do begin
filenam = filename + strtrim(string(i),2)
filenam = filenam +'.png'
print,filenam
write_PNG, filenam, reform(res(i,*,*)), red, green, blue
end

tvlct, red, green, blue

cd, directory

;Overview_RedrawTopography, ev.top, description = descr

widget_control, ev.top, /update
end


pro Overview_ExportSAsPNG, ev                                                                                

widget_control, ev.top, get_uvalue = descr

filename = (*descr.Data)[descr.Index].ParFile

filename = filename + '_S.png'                                                                              
filename = dialog_pickfile(/write, file = filename, filter = '*.png', get_path = directory)               
wset,descr.Swindow
tvlct, red, green, blue, /get                                                                              
loadct,0
if descr.profile then Overview_profile,ev.top else Overview_Spectrum_Redraw, ev.top
wset,descr.Swindow
result=tvrd(0)
write_PNG, filename, result, red, green, blue                                    
cd, directory  
tvlct, red, green, blue
if descr.profile then Overview_profile,ev.top else Overview_Spectrum_Redraw, ev.top

wset,descr.Twindow                                                                                            
widget_control, ev.top, /update
end                                                                                                        

pro Overview_xppts, ev                                                                                

widget_control, ev.top, get_uvalue = descr

if descr.profile then begin

img='true'
Overview_RedrawTopography,ev.top,img

x1=descr.px1
x2=descr.px2
y1=descr.py1
y2=descr.py2

res=(*descr.data)[descr.Index].parameters.topography[descr.TChannel-1].resolution
img=img*res
if img(0) ne 0 then yy=mprofile(img,x1,x2,y1,y2)
xxvl=indgen(n_elements(yy))

end $
else $
begin

yvl=*descr.spectrumy
xvl=*descr.spectrumx
mx=max(*(descr.spectrumy))
mn=min(*(descr.spectrumy))
xmx=max(*(descr.spectrumx))
xmn=min(*(descr.spectrumx))
;help,xvl
;print,min(xvl),max(xvl)
;help,yvl
;print,min(yvl),max(yvl)
srt=sort(xvl)
xvl=xvl(srt)
yvl=yvl(srt)
yy=yvl
xxvl=xvl

 if descr.ld then begin
 yy=didv(xvl,yvl)
 xxvl=xvl(1:*)
 xmx=max((xvl))
 xmn=min((xvl))
 end

 if descr.lnd then begin
 yy=dlnidlnv(xvl,yvl)
 xxvl=xvl(1:*)
 xmx=max((xvl))
 xmn=min((xvl))
 end

end

print,'Saving'
help,yy
help,xxvl

filename = (*descr.Data)[descr.Index].ParFile

filename = filename + '_S.dat'                                                                              
filename = dialog_pickfile(/write, file = filename, filter = '*.dat', get_path = directory)               

openw,LUN,filename,/get_LUN
 for i=0,n_elements(xxvl)-1 do begin
 printf,LUN,xxvl(i),yy(i)
 end

free_LUN, LUN
cd, directory  
widget_control, ev.top, /update
end


pro Overview_AtDrawEv, ev
;Osetreni udalosti, vyvolane mysi v kreslicim okne
;Oznaceni obdelnikove oblasti metodou tahni a pust zpusobi zobrazeni vyrezu
widget_control, ev.top, get_uvalue = descr
widget_control, ev.id, get_value = win, get_uvalue = MouseStat
if not keyword_set(MouseStat) then begin
  MouseStat = {x1:0, y1:0, x2:0, y2:0, down:0}
  ;x1, y1, x2. y2 = souradnice oznaceneho obdelnika
  ;down = tlacitko mysi stisknuto
  endif
case ev.type of
0: if not MouseStat.down then begin; pressed
  MouseStat.x1 = ev.x
  MouseStat.x2 = ev.x
  MouseStat.y1 = ev.y
  MouseStat.y2 = ev.y
  MouseStat.down = 1
  widget_control, ev.id, set_uvalue = MouseStat, draw_motion_events = MouseStat.down
  end
1: begin; released
  wset, win
  device, set_graphics_function = 6; nastaveni XOR grafiky
  x1 = MouseStat.x1
  y1 = MouseStat.y1
  x2 = MouseStat.x2
  y2 = MouseStat.y2
  if (x1 NE x2) or (y1 NE y2) then plots, [x1, x2, x2, x1, x1,x2], [y1, y1, y2, y2, y1,y2], /device
    ;mazani posledniho obdelnika
  x2 = ev.x
  y2 = ev.y

    r=max([abs(x2-x1),abs(y2-y1)])
    sx=sgn(x2-x1)
    sy=sgn(y2-y1)
if not descr.profile then $
begin    
    x2=x1+sx*r
    y2=y1+sy*r    
end      


  device, set_graphics_function = 3; obnoveni prekreslovaci grafiky
  MouseStat.down = 0
  widget_control, ev.id, set_uvalue = MouseStat, draw_motion_events = MouseStat.down

  ;konecne zpracovani udalosti


  
  if (abs(x2 - x1) GT 8) or (abs(y1 - y2) GT 8) then $
   begin
      if not descr.profile then Overview_ZoomIn, ev.top, x1, y1, x2, y2 $
      else begin
      descr.px1=x1
      descr.px2=x2
      descr.py1=y1
      descr.py2=y2
      widget_control, ev.top, set_uvalue = descr
      Overview_Profile,ev.top
      end 
    end else Overview_Spectrum_Select,ev.top,(x1+x2)/2,(y1+y2)/2
   

end

2: begin; pohyb mysi
  if MouseStat.down then begin
    wset, win
    device, set_graphics_function = 6; nastaveni XOR grafiky
    x1 = MouseStat.x1
    y1 = MouseStat.y1
    x2 = MouseStat.x2
    y2 = MouseStat.y2
    
    
    if (x1 NE x2) or (y1 NE y2) then plots, [x1, x2, x2, x1, x1,x2], [y1, y1, y2, y2, y1,y2], /device
      ;smazani stareho obdelnika
    
    x2 = ev.x
    y2 = ev.y
    
    r=max([abs(x2-x1),abs(y2-y1)])
    sx=sgn(x2-x1)
    sy=sgn(y2-y1)
if not descr.profile then $
begin    
    x2=x1+sx*r
    y2=y1+sy*r    
end      
    if (x1 NE x2) or (y1 NE y2) then plots, [x1, x2, x2, x1, x1,x2], [y1, y1, y2, y2, y1,y2], /device
      ;kresleni noveho obdelnika
    MouseStat.x2 = x2
    MouseStat.y2 = y2
    device, set_graphics_function = 3; obnoveni prekreslovaci grafiky
  endif
  widget_control, ev.id, set_uvalue = MouseStat
  end
endcase
end
