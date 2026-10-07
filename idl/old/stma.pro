;Scanning Tunneling Microscopy - Anlalysis

;Polozky struktury, popisujici stav aplikace STMA (struktura definovana v procedure STMA):
;n = Pocet datovych polozek (1 polozka = 1 mereni)
;Data = ukazatel na pole datovych polozek
;Index = index aktualni (zobrazovane a zpracovavane) datove polozky
;TWindow = cislo zobrazovaciho okna pro topografii
;SWindow = cislo zobrazovaciho okna pro spektroskopii
;TChannel = cislo zobrazeneho topografickeho kanalu
;SChannel = cislo zobrazeneho spektroskopickeho kanalu
;Parameters = ukazatel na parametry aktualniho mereni
;Topography = ukazatel na orginal prave zobrazenene topografie
;Image =  ukazatel na zpracovanou podobu zobrazovane topografie - topograficky obrazek
;Curve = ukazatel na zpracovanou podobu zobrazovane spektroskopie
;Spectroscopy = ukazatel na orginal prave zobrazene spektroskopie
;Region: ukazatel na definici vybrane oblasti
;Regions = ukazatel na pole ukazatelu na definici vybranych oblasti
;OldPalette = definice palety nastavene pred spustenim programu (polozky R, G, B)
;SubtrPlane = od toporafickeho obrazku se odecita prolozena rovina - kompenzace sklonu
;SinglePoint = zobrazuje se spektrum z jedineho spektroskopickeho bodu
;ShowGrid = v topografickem obrazku se zobrazi spektroskopicka mrizka
;TopoZoom = 1: Zobrazovan pouze vyrez z celeho topografickeho obrazku
;tx1, ty1 = souradnice jednoho (leveho horniho) rohu vyrezu z topografie
;ty1, ty2 = souradnice protilehleho (praveho dolniho) rohu vyrezu z topografie
;Interpolate = interpolacni vyhlazovani obrazku
;InvertColors = prevraceni barevne skaly: vysoke hodnoty tmave, nizke svetle
;ShowDifferences = zobraovani rozdilu souradnic mezi poslednim kliknutim a aktualni pozici mysi
;x0, y0 = souradnice bodu, na ktery se naposledy kliknulo mysi
;x,y = souradnice vybraneho bodu (v rezimu SinglePoint)
;NSpectraUsed = pocet spekter pouzitych k vypoctu zobrazeneho grafu
;AddDelMode = 0: rezim pridavani k vybrane oblasti
;AddDelMode = 1: rezim odebirani od vybrane oblasti
;TScreenXSize = vodorovny rozmer vyuzite casti topografickeho okna
;TScreenYSize = svisly rozmer vyuzite casti topografickeho okn

pro STMA_Quit, ev
;Ukonceni programu
answer = dialog_message('Do you really want to quit the application?', /question, $
  dialog_parent = ev.top)
if answer EQ 'Yes' then widget_control, ev.top, /destroy
end


pro STMA_NewApp, ev
g = widget_info(ev.top, /geometry)
STMA, xsize = g.scr_xsize, ysize = g.scr_ysize
end


pro STMA_NewMonospec, ev

monospecM
end

pro STMA_AtTlbEvent, ev
;Osetreni udalosti tykajicich se hlavniho okna programu
case tag_names(ev, /structure_name) of
'WIDGET_KILL_REQUEST': STMA_Quit, ev; application close button pressed
;'WIDGET_BASE': widgetcontrol, ev.top, scr_xsize = ev.x, scr_ysize = ev.y
else: print, !ERROR_STATE.MSG_PREFIX + 'Unprocessed event'
endcase
end


pro STMA_UpdateFileControl, top, description = descr
;Nastavi aktivitu nekterych ovladacich prvku souvisejicich s praci se soubory
;v souladu s aktualnim stavem popisujici promenne
;top = identifikacni cislo vrcholoveho widgetu aplikace
;descr = strukturovana promenna popisujici stav aplikace

if not keyword_set(descr) then widget_control, ev.top, get_uvalue = descr
closef = widget_info(top, find_by_uname = 'CloseFiles')
nextf = widget_info(top, find_by_uname = 'NextFile')
prevf = widget_info(top, find_by_uname = 'PreviousFile')
widget_control, closef, sensitive = (descr.n GT 0) mod 2
widget_control, nextf, sensitive = ((descr.Index + 1) LT descr.n) mod 2
widget_control, prevf, sensitive = (descr.Index GT 0) mod 2
end


pro STMA_RecalcImage, top, description = descr
;Procedura prepocita podobu topografickeho obrazku
;Provede filtraci obrazku nebo jinou operaci s nim
;Nutno volat pred prekreslenim obrazku, ma-li se obrazek zmenit

if not keyword_set(descr) then widget_control, top, get_uvalue = descr
if ptr_valid(descr.Topography) then img = *descr.Topography else img = 0
if not keyword_set(img) then begin
  if ptr_valid(descr.Image) then *descr.Image = 0 else descr.Image = ptr_new(0)
  return
endif

if descr.SubtrPlane then $ 
begin
img = Truncate(img)
img = SubtrPlane(img)
img = RowsEqual(img)
end

if ptr_valid(descr.Image) then *descr.Image = img else descr.Image = ptr_new(img)
end


pro STMA_RedrawTopography, top, description = descr, win = win, grayscale = grayscale
;Procedura prekresli topograficky obrazek v souladu s aktualnim stavem popisujici promenne
;top = identifikacni cislo vrcholoveho widgetu aplikace
;descr = strukturovana promenna popisujici stav aplikace
;win = cislo grafickeho okna, do nehoz se ma kreslit (pri kresleni do okna programu netreba zadavat)
;/grayscale = cernobily obraz

if not keyword_set(descr) then widget_control, top, get_uvalue = descr
if n_elements(win) EQ 0 then win = descr.TWindow
if not(ptr_valid(descr.Image)) then img = 0 else img = *descr.Image
if not keyword_set(img) then begin; neni co kreslit
  oldwin = !D.WINDOW
  wset, win
  device, decomposed = 1
  tv, intarr(!D.X_SIZE, !D.Y_SIZE)
  if oldwin GE 0 then wset, oldwin
  return
endif

device, decomposed = 0
if keyword_set(grayscale) then begin
  loadct, 0, /silent
endif else begin
  GoldPalette
  ;loadct, 0, /silent
  ;tvlct, red, green, blue, /get
  ;red[0] = 0
  ;green[0] = 255
  ;blue[0] = 0
  ;tvlct, red, green, blue
endelse

oldwin = !D.WINDOW
wset, win
winxsize = !D.X_SIZE
winysize = !D.Y_SIZE
xsize = (size(img))[1]
ysize = (size(img))[2]
if descr.TopoZoom then begin
  ;zobrazuje se pouze vyrez
  x1 = 0 > (descr.tx1 < descr.tx2) < (xsize-1) 
  x2 = 0 > (descr.tx1 > descr.tx2) < (xsize-1)
  y1 = 0 > (descr.ty1 < descr.ty2) < (ysize-1)
  y2 = 0 > (descr.ty1 > descr.ty2) < (ysize-1)
  img = img[x1:x2, y1:y2]
endif else begin
  x1 = 0
  x2 = xsize - 1
  y1 = 0
  y2 = ysize - 1
endelse

;vyznaceni hranic vybrane oblasti
xsize = (*descr.Parameters).XPixels
ysize = (*descr.Parameters).YPixels
if not descr.SinglePoint then begin
  region = *descr.Region
  borders = bytarr(xsize, ysize, /nozero)  
  shiftreg = shift(region, 1, 0)
  shiftreg[0, *] = 0
  borders = not shiftreg; lezi levy sousedni bod mimo oblast?
  shiftreg = shift(region, -1, 0)
  shiftreg[xsize-1, *] = 0
  borders = borders or not shiftreg; lezi pravy sousedni bod mimo oblast?
  shiftreg = shift(region, 0, 1)
  shiftreg[*, 0] = 0
  borders = borders or not shiftreg; lezi dolni sousedni bod mimo oblast?
  shiftreg = shift(region, 0, -1)
  shiftreg[*, ysize-1] = 0
  borders = borders or not shiftreg; lezi horni sousedni bod mimo oblast?
  ;hranice: lezi bod uvnitr oblasti a nektery ze sousednich bodu mimo oblast?
  borders = region and borders
  borders = borders[x1:x2, y1:y2]
endif

;vyznaceni mrizky bodu, v nichz se snimala spektra
if (descr.ShowGrid) and ((*descr.Parameters).SChannels GT 0) then begin
  xgrid = (*descr.Parameters).XGrid
  ygrid = (*descr.Parameters).YGrid
  sindex = descr.SChannel - 1
  reg = (*descr.Data)[descr.Index].IrregularGrid[sindex].n LE 0
  if (xgrid GT 0) and (ygrid GT 0) and reg then begin
    ;pravidelna mrizka
    xgrid = (*descr.Parameters).XGrid
    ygrid = (*descr.Parameters).YGrid
    nx = (xsize - 1) / xgrid + 1
    ny = (ysize - 1) / ygrid + 1
    grid = bytarr(xgrid, nx, ygrid, ny)
    grid[0, *, 0, *] = 1
    grid = (reform(grid, nx * xgrid, ny * ygrid))[0: xsize-1, 0: ysize-1] 
    grid = grid[x1:x2, y1: y2]
  endif
  if (reg EQ 0) then begin
    ;nepraidelna mrizka
    grid = bytarr(xsize, ysize)
    xcoords = *(*descr.Data)[descr.Index].IrregularGrid[sindex].x
    ycoords = *(*descr.Data)[descr.Index].IrregularGrid[sindex].y
    ncoords = (*descr.Data)[descr.Index].IrregularGrid[sindex].n
    incrx = (*descr.Data)[descr.Index].Parameters.IncrementX
    incry = (*descr.Data)[descr.Index].Parameters.IncrementY
    for i = 0, ncoords - 1 do begin
      nx = 0 > fix(xcoords[i] / incrx + 0.5) < (xsize - 1)
      ny = 0 > fix(ycoords[i] / incry + 0.5) < (ysize - 1)
      grid[nx-2:nx+2, ny] = 1
      grid[nx-2:nx+2, ny+3] = 1
      grid[nx-2:nx+2, ny-3] = 1
      
      grid[nx-3, ny-2:ny+2] = 1
      grid[nx, ny-2:ny+2] = 1
      grid[nx+3, ny-2:ny+2] = 1
    endfor
    grid = grid[x1:x2, y1: y2]
  endif
endif

xsize = x2 - x1 + 1
ysize = y2 - y1 + 1

;resizing
winysize = winysize < (long(winxsize) * long(ysize) + xsize - 1) / xsize
winxsize = winxsize < (long(winysize) * long(xsize) + ysize - 1) / ysize
if descr.InvertColors then img = -img

if (xsize NE winxsize) or (ysize NE winysize) then begin
  if descr.Interpolate then interpolate = -0.5 else interpolate = 0.0


  if descr.maxfilter then img=maxfilter(img)
  if descr.smooth then img=smooth(img,3)
  img = congrid(img, winxsize, winysize, cubic = interpolate)
  if keyword_set(grid) then grid = congrid(grid, winxsize, winysize)
  if keyword_set(borders) then borders = congrid(borders, winxsize, winysize)
endif

img = TvScaled(img, mincolor = 1, maxcolor = !D.TABLE_SIZE - 2)

;adding grid and borders
if keyword_set(grid) then img = img * (1 - grid) + 0B * grid
if keyword_set(borders) then img = img * (1 - borders) + 0B * borders

;completing window with blind area
if (winxsize NE !D.X_SIZE) or (winysize NE !D.Y_SIZE) then begin
  background = intarr(!D.X_SIZE, !D.Y_SIZE)
  background[0:winxsize-1, !D.Y_SIZE-winysize:*] = img
  img = background
  ;erase, color=0
endif

if (win EQ descr.TWindow) then begin
  descr.TScreenXSize = winxsize
  descr.TScreenYSize = winysize
endif

tv, img 
if oldwin GE 0 then wset, oldwin
widget_control, top, set_uvalue = descr
end


pro STMA_RecalcSpectrum, top, description = descr
;Procedura vypocita (prepocita) spektroskopickou krivku pred jejim zobrazenim
;top = identifikacni cislo vrcholoveho widgetu aplikace
;descr = strukturovana promenna popisujici stav aplikace

if not keyword_set(descr) then widget_control, top, get_uvalue = descr
if not ptr_valid(descr.Spectroscopy) or ((*descr.Parameters).SChannels LE 0) then return
start = (*descr.Parameters).Spectroscopy[descr.SChannel-1].Start
increment = (*descr.Parameters).Spectroscopy[descr.SChannel-1].Increment
xsize = (*descr.Parameters).XPixels
ysize = (*descr.Parameters).YPixels
resolution = (*descr.Parameters).Spectroscopy[descr.SChannel-1].Resolution
griddim = size(*descr.Spectroscopy, /n_dimensions) - 1
if griddim EQ 2 then begin

  ;spekskopie na pravidelne mrizi
  nx = (size(*descr.Spectroscopy))[1]
  ny = (size(*descr.Spectroscopy))[2]
  np = (size(*descr.Spectroscopy))[3]
  xgrid = (*descr.Parameters).XGrid
  ygrid = (*descr.Parameters).YGrid

  if descr.SinglePoint then begin
    x = (descr.x + (xgrid-1) / 2) / xgrid < (nx-1)
    y = (descr.y + (ygrid-1) / 2) / ygrid < (ny-1)
    s = (*descr.Spectroscopy)[x, y, *]; spektrum z jedineho bodu 
    descr.NSpectraUsed = 1
  endif else begin
    s = reform(*descr.Spectroscopy, nx * ny, np)
    if (xgrid * nx NE xsize) or (ygrid * ny NE ysize) then begin
      n1x = nx * xgrid
      n1y = ny * ygrid
      n2x = n1x < nx
      n2y = n1y < ny
      reg = bytarr(n1x, n1y)
      reg[0:n2x-1, 0:n2y-1] = (*descr.Region)[0:n2x-1, 0:n2y-1]
      reg = (reform(reg, xgrid, nx, ygrid, ny))[0, *, 0, *]
    endif else begin
      reg = (reform(*descr.Region, xgrid, nx, ygrid, ny))[0, *, 0, *]
    endelse
    i = where(reg EQ 1, count)
    if count GT 0 then s = total(s[i, *], 1) / count $; prumerne spektrum
    else s = 0 * s[0, *]
    descr.NSpectraUsed = count
  endelse
endif else begin

  ;spektroskopie na nepravidelne mrizi
  n = (size(*descr.Spectroscopy))[1]
  np = (size(*descr.Spectroscopy))[2]
  incrx = (*descr.Parameters).IncrementX
  incry = (*descr.Parameters).IncrementY
  irrgrid = (*descr.Data)[descr.Index].IrregularGrid[descr.SChannel-1]
  n = n < irrgrid.n
  xcoords = 0 > fix((*irrgrid.x) / incrx + 0.5) < (xsize-1)
  ycoords = 0 > fix((*irrgrid.y) / incry + 0.5) < (ysize-1)
  if descr.SinglePoint then begin
    r = abs(descr.x - xcoords) + abs(descr.y - ycoords) 
    print,descr.x-xcoords,descr.y-ycoords
    r = min(r, i)
    r=r(0)
    ;print,i,xcoords,ycoords,r^0.5
    s = (*descr.Spectroscopy)[i,*]; spektrum z jedineho bodu
    descr.x = xcoords[i]
    descr.y = ycoords[i]
    descr.NSpectraUsed = 1
  endif else begin
    reg = (*descr.Region)
    s = (*descr.Spectroscopy)
    i = where(reg[xcoords, ycoords] EQ 1, count)
    if count GT 0 then s = total(s[i, *], 1) / count $; prumerne spektrum
    else s = 0 * s[0, *]
    descr.NSpectraUsed = count
  endelse
endelse

p = start + increment * indgen(np); nezavisle promenna
s = reform(s) * resolution
if ptr_valid(descr.Curve) then *descr.Curve = [[p], [s]] $
else descr.Curve = ptr_new([[p], [s]])
widget_control, top, set_uvalue = descr
end


pro STMA_RedrawSpectrum, top, description = descr, win = win, filename = filename
;Procedura prekresli spektrum v souladu s aktualnim staven popisujici promenne
;top = identifikacni cislo vrcholoveho widgetu aplikace
;descr = strukturovana promenna popisujici stav aplikace
;win = cislo grafickeho okna, do nehoz se ma kreslit (pri kresleni do okna programu netreba zadavat)

if not keyword_set(descr) then widget_control, top, get_uvalue = descr
if n_elements(win) EQ 0 then win = descr.SWindow
if not ptr_valid(descr.Spectroscopy) or ((*descr.Parameters).SChannels LE 0) then begin
  ; neni co kreslit
  oldwin = !D.WINDOW
  wset, win
  device, decomposed = 1
  tv, intarr(!D.X_SIZE, !D.Y_SIZE) 
  if oldwin GE 0 then wset, oldwin
  return
endif

xtitle = (*descr.Parameters).Spectroscopy[descr.SChannel-1].Parameter
ytitle = (*descr.Parameters).Spectroscopy[descr.SChannel-1].Type
yunit = (*descr.Parameters).Spectroscopy[descr.SChannel-1].Unit
ytitle = ytitle + ' [' + yunit + ']'
  
device, decomposed = 0
loadct, 0, /silent

oldwin = !D.WINDOW
wset, win
if keyword_set(filename) then begin
  xsize = !D.X_SIZE
  ysize = !D.Y_SIZE
  window, xsize = xsize, ysize = ysize, /free, /pixmap
endif

p = (*descr.Curve)[*,0]; nezavisle promenna
s = (*descr.Curve)[*,1]; zavisle promenna
plot, p, s, background=1, xtitle = xtitle, ytitle = ytitle

if keyword_set(filename) then begin
  write_tiff, filename, tvrd(/order), 1
  wdelete, !D.WINDOW
  wset, descr.SWindow
endif
if oldwin GE 0 then wset, oldwin
widget_control, top, set_uvalue = descr
end


pro STMA_PositionInfo, top, x, y, description = descr
;Zobrazi udaj o  poloze (x, y) a vysce (intenzite) topogafickeho bodu
;x, y = souradnice topografickeho bodu v pixelech

if not keyword_set(descr) then widget_control, top, get_uvalue = descr, update = 0
Par = (*descr.Parameters)
inx = descr.TChannel - 1
type = Par.Topography[inx].Type
unit = Par.Topography[inx].Unit
incrx = Par.IncrementX
incry = Par.IncrementY
resolution = Par.Topography[inx].Resolution
z = (*descr.Image)[x,y]
stringx = 'X: ' + string(x * incrx, format = '(F7.3)') + 'nm'
stringy = 'Y: ' + string(y * incry, format = '(F7.3)') + 'nm'
stringz = type + ': ' + string(z * resolution, format = '(G9.3)') + unit 
label = widget_info(top, find_by_uname = 'PositionInfo')
widget_control, label, set_value = stringx + '  ' + stringy + '  ' + stringz
descr.x0 = x
descr.y0 = y
widget_control, top, set_uvalue = descr
end


pro STMA_DifferenceInfo, top, x, y, description = descr
;Zobrazi udaj o rozdilu v poloze a vysce (intenzite) mezi aktualnim bodem a poslednim kliknutim
;x, y = aktualni souradnice v pixelech

if not keyword_set(descr) then widget_control, top, get_uvalue = descr, update = 0
Par = (*descr.Parameters)
inx = descr.TChannel - 1
type = Par.Topography[inx].Type
unit = Par.Topography[inx].Unit
incrx = Par.IncrementX
incry = Par.IncrementY
resolution = Par.Topography[inx].Resolution
z = (*descr.Image)[x,y]
x0 = descr.x0
y0 = descr.y0
z0 = (*descr.Image)[x0, y0]
stringx = 'dR:' + string((((x - x0) * incrx)^2 + ((y - y0) * incry)^2)^0.5, format = '(F7.3)') + 'nm'
stringy = 'Phi:' + string(ATAN(abs(y - y0)*incrx, abs(x - x0)*incry)*180./!PI, format = '(F7.3)') + 'DEG'
;stringx = 'dX:' + string((x - x0) * incrx, format = '(F7.3)') + 'nm'
;stringy = 'dY:' + string((y - y0) * incry, format = '(F7.3)') + 'nm'
stringz = 'd' + type + ':' + string((z - z0) * resolution, format = '(G9.3)') + unit 
label = widget_info(top, find_by_uname = 'DifferenceInfo')
widget_control, label, set_value = stringx + '  ' + stringy + '  ' + stringz
end


pro STMA_SpectInfo, top, description = descr
;Vypise pod grafem spektra udaj o tom, z kolika spekter se pocital zobrazeny graf,
;v pripade grafu jedineho spektra informaci o bodu, ze ktereho graf pochazi

if not keyword_set(descr) then widget_control, top, get_uvalue =descr, update = 0
Par = (*descr.Parameters)
incrx = Par.IncrementX
incry = Par.IncrementY
n = descr.NSpectraUsed
if n EQ 1 then begin
  stringx = string(descr.x * incrx, format = '(F7.3)') + 'nm'
  stringy = string(descr.y * incry, format = '(F7.3)') + 'nm'
  string = 'Spectrum at point (' + stringx + ', ' + stringy + ')'
  ;help,*descr.Index,/struct

endif else begin
  string = 'Averrage of ' + string(n, format = '(I6)') + ' spectra'
endelse
label = widget_info(top, find_by_uname = 'SpInfo')
widget_control, label, set_value = string
end


pro STMA_UpdateTopography, top, description = descr
;Aktualizuje topograficky widget - obrazek i popisky - s nasledujicimi vyjimkami:
; - nevytvari novou nabidku kanalu, to je zalezitosti procedury STMA_UpdateApp
; - neaktualizuje popisek vybraneho kanalu, to je zalezitosti procedury STMA_TChannelSeclet
;top = identifikacni cislo vrcholoveho widgetu aplikace
;descr = stavova promenna aplikace

if not keyword_set(descr) then widget_control, top, get_uvalue = descr, update = 0
Par = (*descr.Parameters)
descr.TChannel = 1 > descr.TChannel < Par.TChannels
id = widget_info(top, find_by_uname = 'Topography')
if Par.TChannels LE 0 then begin
  widget_control, id, map = 0
  descr.Topography = ptr_new()
  return
endif
widget_control, id, /map 
inx = descr.TChannel - 1
descr.Topography = (*descr.Data)[descr.Index].Images[inx]
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
xsize = abs(descr.tx2-descr.tx1)+1 ;(size(*descr.Topography))[1]
ysize = abs(descr.ty2-descr.ty1)+1 ;(size(*descr.Topography))[2]
label = widget_info(top, find_by_uname = 'TFileName')
widget_control, label, set_value = 'FILE: ' + filename
label = widget_info(top, find_by_uname = 'TProperties')
if (direction EQ 'forward') or (direction EQ 'backward') then widget_control, label, set_value = $
  string(voltage, current, format = '("FEEDBACK: ", F7.3, "V, ", F7.3, "nA")') $
else widget_control, label, set_value = ''
widget_control, widget_info(top, find_by_uname = 'TArea'), set_value = $
  string(xsize * incrx, ysize * incry, format = '("AREA:   ", F7.3, "nm x ", F7.3, "nm")')
STMA_RecalcImage, top, description = descr
STMA_RedrawTopography, top, description = descr
STMA_PositionInfo, top, 0, 0, descr = descr
if descr.ShowDifferences then STMA_DifferenceInfo, top, 0, 0, descr = descr
widget_control, top, set_uvalue = descr
end


pro STMA_UpdateSpectroscopy, top, description = descr
;Aktualizuje spektroskopicky widget - obrazek i popisky - s nasledujicimi vyjimkami:
; - nevytvari novou nabidku kanalu, to je zalezitosti procedury STMA_UpdateApp
; - neaktualizuje popisek vybraneho kanalu, to je zalezitosti procedury STMA_SChannelSect
;top = identifikacni cislo vrcholoveho widgetu aplikace
;descr = stavova promenna aplikace

if not keyword_set(descr) then widget_control, top, get_uvalue = descr, update = 0
Par = (*descr.Parameters)
descr.SChannel = 1 > descr.SChannel < Par.SChannels
id = widget_info(top, find_by_uname = 'Spectroscopy')
if Par.SChannels LE 0 then begin
  widget_control, id, map = 0
  descr.Spectroscopy = ptr_new()
  return
endif
widget_control, id, /map
inx = descr.SChannel - 1
descr.Spectroscopy = (*descr.Data)[descr.Index].Spectra[inx]
filename = Par.Spectroscopy[inx].FileName
label = widget_info(top, find_by_uname = 'SFileName')
widget_control, label, set_value = 'FILE: ' + filename
STMA_RecalcSpectrum, top, description = descr
STMA_RedrawSpectrum, top, description = descr
STMA_SpectInfo, top, description = descr
widget_control, top, set_uvalue = descr
end


pro STMA_UpdateApp, top, description = descr
;Nejobecnejsi aktualizacni procedura. Nastavi vsechny vystupy i ovladaci prvky aplikace
;v souladu s aktualnim staven popisujici promenne
;top = identifikacni cislo vrcholoveho widgetu aplikace
;descr = strukturovana promenna popisujici stav aplikace

if not keyword_set(descr) then widget_control, top, get_uvalue = descr
if not ptr_valid(descr.Data) then descr.n = 0 $
else if not keyword_set(*descr.Data) then descr.n = 0 $
else descr.n = n_elements(*descr.Data)
if descr.n GT 0 then begin
  descr.Index = descr.Index < (descr.n - 1)
  Par = (*descr.Data)[descr.Index].Parameters 
  descr.Region = (*descr.Regions)[descr.Index]
  descr.x = descr.x < Par.XPixels
  descr.y = descr.y < Par.YPixels
  descr.x0 = 0
  descr.y0 = 0
  descr.NSpectraUsed = 0
  descr.TopoZoom = 0
  descr.tx1 = 0
  descr.tx2 = Par.XPixels - 1
  descr.ty1 = 0
  descr.ty2 = Par.YPixels - 1
  if not ptr_valid(descr.Parameters) then descr.Parameters = ptr_new(Par) else *descr.Parameters = Par
  parfile = (*descr.Data)[descr.Index].ParFile
  headertext = 'PARAMETER FILE: ' + parfile
  time = (*descr.Parameters).Time
  if keyword_set(time) then headertext = headertext + '  TIME: ' + time
  comm = (*descr.Parameters).Comment
  if keyword_set(comm) then comm = 'COMMENT: ' + comm
  widget_control, widget_info(top, find_by_uname = 'Header'), set_value = headertext
  widget_control, widget_info(top, find_by_uname = 'Comment'), set_value = comm

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
    if i EQ inx then widget_control, channels, set_value = 'TOPOGRAPHIC CHANNEL: ' + text
    item = widget_button(channels, value = text, uvalue = i, event_pro = 'STMA_TChannelSelect')
  endfor
  
  ;vytvoreni nove nabidky spektroskopickych kanalu
  descr.SChannel = 1 > descr.SChannel < Par.SChannels
  inx = descr.SChannel
  channels = widget_info(top, find_by_uname = 'SChannelList')
  item = widget_info(channels, /child)
  while item NE 0L do begin
    destr = item
    item = widget_info(item, /sibling)
    widget_control, destr, /destroy
  endwhile
  if Par.SChannels LE 0 then begin
    widget_control, channels, set_value = '                       '
  endif else for i = 1, Par.SChannels do begin
    text =  strcompress(string(i), /remove_all) + '(' + Par.Spectroscopy[i-1].Type + ')'
    if i EQ inx then widget_control, channels, set_value = 'SPECTROSCOPY CHANNEL: ' + text
    item = widget_button(channels, value = text, uvalue = i, event_pro = 'STMA_SChannelSect')
  endfor
  
  STMA_UpdateTopography, top, description = descr
  STMA_UpdateSpectroscopy, top, description = descr
  widget_control, widget_info(top, find_by_uname = 'Top'), /map
  ;widget_control, widget_info(top, find_by_uname = 'Subtop'), /map
  widget_control, widget_info(top, find_by_uname = 'Main'), /map
  widget_control, widget_info(top, find_by_uname = 'SaveTopography'), sensitive = (Par.TChannels GT 0) mod 2
  widget_control, widget_info(top, find_by_uname = 'SaveSpectroscopy'), sensitive = (Par.SChannels GT 0) mod 2
endif else begin
  widget_control, widget_info(top, find_by_uname = 'Top'), map = 0
  ;widget_control, widget_info(top, find_by_uname = 'Subtop'), map = 0
  widget_control, widget_info(top, find_by_uname = 'Main'), map = 0
  widget_control, widget_info(top, find_by_uname = 'SaveTopography'), sensitive = 0
  widget_control, widget_info(top, find_by_uname = 'SaveSpectroscopy'), sensitive = 0
endelse
STMA_UpdateFileControl, top, description = descr
widget_control, top, set_uvalue = descr
end


pro STMA_CloseFiles, top, mask, description = descr, indices = ind1
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
  ptr_free, (*descr.Regions)[ind1]
endif
if count0 GT 0 then begin
  *descr.Data = (*descr.Data)[ind0]
  *descr.Regions = (*descr.Regions)[ind0]
endif else begin
  *descr.Data = 0
  *descr.Regions = 0
endelse
descr.n = count0
descr.Index = (descr.Index - count) < (count0 - 1)
widget_control, top, set_uvalue = descr
STMA_UpdateApp, top, description = descr
end


pro STMA_AddNewData, top, newdata, description = descr
;Prida data z nove otevrenych souboru do pameti programu
;top = identifikacni cislo vrcholoveho widgetu aplikace
;newdata = pole novych datovych polozek

if not keyword_set(descr) then widget_control, top, get_uvalue = descr
if not keyword_set(newdata) then return
n = n_elements(newdata)
regions = ptrarr(n, /allocate_heap)
for i = 0, n - 1 do begin
  if (newdata[i].Parameters.TChannels GT 0) then begin
    xsize = newdata[i].Parameters.XPixels
    ysize = newdata[i].Parameters.YPixels
    *regions[i] = bytarr(xsize, ysize)
  endif
endfor
if descr.n EQ 0 then begin
  if not ptr_valid(descr.Data) then descr.Data = ptr_new(newdata) else *descr.Data = newdata
  if not ptr_valid(descr.Regions) then descr.Regions = ptr_new(regions) else *descr.Regions = regions
endif else begin
  *descr.Data = [*descr.Data, newdata]
  *descr.Regions = [*descr.Regions, regions]
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
*descr.Data = (*descr.Data)[indices]
*descr.Regions = (*descr.Regions)[indices]
descr.Index = (where(indices GE descr.Index))[0]

widget_control, top, set_uvalue = descr
STMA_UpdateApp, top, description = descr
end


pro STMA_OpenFileDialog, ev
;Otevre soubory s novymi daty - nejprve interaktivne parametricky soubor *.par,
;pak soubory s topografii a spektry uvedene v parametrickem souboru
;Data z drive otevrenych souboru budou vymazana z pameti

NewData = LoadSTM(directory = directory, OK = OK, ParentID = ev.top)
if not OK then return
if keyword_set(directory) then cd, directory
widget_control, ev.top, get_uvalue = descr, update = 0
if descr.n GT 0 then STMA_CloseFiles, ev.top, replicate(1B, descr.n), description = descr; close all
STMA_AddNewData, ev.top, NewData, description = descr
widget_control, ev.top, /update
end

pro STMA_AddFiles, ev
;Otevre soubory s novymi daty (nejprve interaktivne parametricky soubor *.par,
;pak soubory s topografii a spektry uvedene v parametrickem souboru)
;Data z drive otevrenych souboru zustavaji z pameti

NewData = LoadSTM(directory = directory, OK = OK, ParentID = ev.top)
if keyword_set(directory) then cd, directory
if not OK then return
widget_control, ev.top, update = 0
STMA_AddNewData, ev.top, NewData, description = descr
widget_control, ev.top, /update
end


pro STMA_OpenListDialog, ev
;Otevre sobory ze seznamu, ktery je ulozen ve zvolenem souboru
;Data nactena z drive otevrenych souboru budou vymazana z pameti
list = Content(/compress, directory = directory, parentID = ev.top)
if not keyword_set(list) then return
if keyword_set(directory) then cd, directory
NewData = LoadSTM(list, OK = OK)
if not OK then return
widget_control, ev.top, get_uvalue = descr, update = 0
if descr.n GT 0 then STMA_CloseFiles, ev.top, replicate(1B, descr.n), description = descr; close all
STMA_AddNewData, ev.top, NewData, description = descr
widget_control, ev.top, /update
end


pro STMA_AddListDialog, ev
;Otevre sobory ze seznamu, ktery je ulozen ve zvolenem souboru
;Data nactena z drive otevrenych souboru zustavaji v pameti
list = Content(/compress, directory = directory, parentID = ev.top)
if not keyword_set(list) then return
if keyword_set(directory) then cd, directory
NewData = LoadSTM(list, OK = OK)
if not OK then return
widget_control, ev.top, get_uvalue = descr, update = 0
STMA_AddNewData, ev.top, NewData, description = descr
widget_control, ev.top, /update
end


pro STMA_CloseFileDialog, ev
;Vytvori dialogove okno, v nemz si uzivatel muze vybrat soubory ke smazani
;Data pochazejici z vybranych souboru budou pak vymazana z pameti

widget_control, ev.top, get_uvalue = descr
if descr.n EQ 0 then return

base = widget_base(group_leader = ev.top, /column, title = 'Select data to remove', $
  event_pro = 'STMA_AtCloseFilesEv', uvalue = {root: ev.top, sel: bytarr(descr.n)})
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


pro STMA_AtCloseFilesEv, ev
;Osetreni udalosti v dialogovem okne otevrenem procedurou STMA_CloseFiles

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
  STMA_CloseFiles, descr.root, descr.sel
  widget_control, descr.root, /update
  end  
'Cancel': widget_control, ev.top, /destroy
endcase
end


pro STMA_NextFile, ev
;posun k nasledujicimu otevrenemu souboru
widget_control, ev.top, get_uvalue = descr
if (descr.Index + 1) LT descr.n then begin
  descr.Index = descr.Index + 1
  widget_control, ev.top, update = 0, set_uvalue = descr
  STMA_UpdateApp, ev.top, description = descr
  widget_control, ev.top, /update 
endif
end


pro STMA_PrevFile, ev
;posun k predchazejicimu otevrenemu souboru
widget_control, ev.top, get_uvalue = descr
if descr.Index GT 0 then begin
  descr.Index = descr.Index - 1
  widget_control, ev.top, update = 0, set_uvalue= descr
  STMA_UpdateApp, ev.top, description = descr
  widget_control, ev.top, /update 
endif
end


pro STMA_MenuSwitchSelect, id, select = select
;Invertuje stav prepinace
;Stav je ulozen jako uvalue (= 1 nebo 0) 
;a indikovan znamenkem + nebo - pred jmenem prepinace
;id = ID widgetu, slouziciho jako prepinac
;select = konecny stav prepinace

widget_control, id, get_value = name, get_uvalue = select
select = 1 - select
if select then begin
  name = '+' + strmid(name,1)
endif else begin
  name = '-' + strmid(name,1)
endelse
widget_control, id, set_value = name, set_uvalue = select
end


pro STMA_MenuSwitchPreset, id, select
;Nastavi stav prepinace
;id = ID widgetu, slouziciho jako prepinac
;select = 1: zapnuty
;select = 0: vypnuty

widget_control, id, get_value = name
if select then begin
  name = '+' + strmid(name,1)
endif else begin
  name = '-' + strmid(name,1)
endelse
widget_control, id, set_value = name, set_uvalue = select
end


pro STMA_TChannelSelect, ev
;zmeni aktualni topograficky kanal
widget_control, ev.top, get_uvalue = descr, update = 0
widget_control, ev.id, get_uvalue = channel, get_value = text
widget_control, widget_info(ev.id, /parent), set_value = 'TOPOGRAPHIC CHANNEL: ' + text
descr.TChannel = channel
STMA_UpdateTopography, ev.top, description = descr
widget_control, ev.top, /update
end


pro STMA_SChannelSect, ev
;zmeni aktualni spektroskopicky kanal
widget_control, ev.top, get_uvalue = descr, update = 0
widget_control, ev.id, get_uvalue = channel, get_value = text
widget_control, widget_info(ev.id, /parent), set_value = 'SPECTROSCOPY CHANNEL: ' + text
descr.SChannel = channel
STMA_UpdateSpectroscopy, ev.top, description = descr
widget_control, ev.top, /update
end


pro STMA_SubtrPlaneSelect, ev
;vybrano nebo zruseno odecitani sklonu
widget_control, ev.top, get_uvalue = descr
STMA_MenuSwitchSelect, ev.id, select = select
descr.SubtrPlane = select
STMA_RecalcImage, ev.top, description = descr
STMA_RedrawTopography, ev.top, description = descr
end


pro STMA_ShowGridSelect, ev
;zapnuto nebo vypnuto zobrazovani spektroskopicke mrizky v topografickem okne
widget_control, ev.top, get_uvalue = descr
STMA_MenuSwitchSelect, ev.id, select = select
descr.ShowGrid = select
STMA_RecalcImage, ev.top, description = descr
STMA_RedrawTopography, ev.top, description = descr
end


pro STMA_InterpolateSelect, ev
;zapnuta nebo vypnuta interpolace (vyhlazovani detailnich snimku)
widget_control, ev.top, get_uvalue = descr
STMA_MenuSwitchSelect, ev.id, select = select
descr.Interpolate = select
STMA_RedrawTopography, ev.top, description = descr
end


pro STMA_InvertColorSelect, ev
;zapnuta nebo vypnuta inverze barevne skaly
widget_control, ev.top, get_uvalue = descr
STMA_MenuSwitchSelect, ev.id, select = select
descr.InvertColors = select
STMA_RedrawTopography, ev.top, description = descr
end


pro STMA_SmoothSelect, ev
widget_control, ev.top, get_uvalue = descr
STMA_MenuSwitchSelect, ev.id, select = select
descr.Smooth = select
STMA_RedrawTopography, ev.top, description = descr
end


pro STMA_ShowDifSelect, ev
;zapnuto nebo vypnuto zobrazovani rozdilu souradnic
widget_control, ev.top, get_uvalue = descr
descr.ShowDifferences = ev.select
if descr.ShowDifferences then begin
  STMA_DifferenceInfo, ev.top, descr.x0, descr.y0, descr = descr
  widget_control, widget_info(ev.top, find_by_uname = 'TWindow'), /draw_motion_events
endif else begin
   widget_control, widget_info(ev.top, find_by_uname = 'DifferenceInfo'), $
     set_value = '                                          '
   widget_control, widget_info(ev.top, find_by_uname = 'TWindow'), /draw_motion_events
endelse
widget_control, ev.top, set_uvalue = descr
end


pro STMA_SinglePointMode, ev
;vybrano nebo zruseno zobrazovani spekter z jednotlivych bodu

widget_control, ev.top, get_uvalue = descr, update = 0
descr.SinglePoint = ev.select
STMA_RecalcImage, ev.top, description = descr
STMA_RedrawTopography, ev.top, description = descr
STMA_RecalcSpectrum, ev.top, description = descr
STMA_RedrawSpectrum, ev.top, description = descr
STMA_SpectInfo, ev.top, description = descr
widget_control, /update
end


pro STMA_AddRegMode, ev
;zapnut mod, kdy se k vybrane oblasti pridava
widget_control, ev.top, get_uvalue = descr
descr.AddDelMode = 1
descr.SinglePoint = 0
widget_control, ev.top, set_uvalue = descr
end


pro STMA_DelRegMode, ev
;zapnut mod, kdy se od vybrane oblasti odebira
widget_control, ev.top, get_uvalue = descr
descr.AddDelMode = 0
descr.SinglePoint = 0
widget_control, ev.top, set_uvalue = descr
end


pro STMA_ShowAllTopo, ev
;zobrazeni cele topografie namisto vyrezu
widget_control, ev.top, get_uvalue = descr
descr.TopoZoom = 0
widget_control, ev.id, sensitive = 1
descr.tx1 = 0
descr.tx2 = (*descr.Parameters).XPixels - 1
descr.ty1 = 0
descr.ty2 = (*descr.Parameters).YPixels - 1
widget_control, ev.top, set_uvalue = descr
STMA_UpdateTopography, ev.top, description=descr
end


function STMA_AtDrawEv, ev
;Osetreni udalosti, vyvolane mysi v kreslicim okne.
;Funkce vraci udalost pri uvolneni tlacitka mysi
;Pritom rozhodne, jestli se jednalo o obycejne kliknuti, 
;nebo o vyber obdelnikove oblasti (stylem tahni a pust) 
;Prave tlacitko lze nahradit levym tlacitkem za soucasneho drzeni klavesy Shift
;Typ udalosti posilane vyse je oznacen v ev.type jako retezec:
;LeftClick = kliknuti levym tlacitkem
;RightClick = kliknuti levym tlacitkem za soucasneho drzeni klavesy Shift (alespon pri uvolneni tlacitka)
;LeftDrag = vyber obdelnikove olasti metodou tahni a pust (levym tlacitkem)
;RightDrag = vyber obdelnikove olasti metodou tahni a pust (pravym tlacitkem)
;Souradnice se zapisi v hardwarovem souradnem systemu

widget_control, ev.id, get_value = win, get_uvalue = MouseStat
widget_control, ev.top, get_uvalue = descr
if not keyword_set(MouseStat) then begin
  MouseStat = {xl1:0, yl1:0, xl2:0, yl2:0, leftdown:0, xr1:0, yr1:0, xr2:0, yr2:0, rightdown:0}
  ;leftdown = leve tlacitko drzeno
  ;rightdown = prave tlacitko drzeno
  ;xl1, yl1, xl2. yl2 = souradnice obdelnika vybraneho ("pretazeneho") levym tlacitkem
  ;xr1, yr1, xr2. yr2 = souradnice obdelnika vybraneho ("pretazeneho") pravym tlacitkem
  endif
case ev.type of
0: begin; pressed
  if (ev.press AND 1B) then if not MouseStat.leftdown then begin
    ;leve tlacitko stisknuto
    MouseStat.xl1 = ev.x
    MouseStat.xl2 = ev.x
    MouseStat.yl1 = ev.y
    MouseStat.yl2 = ev.y
    MouseStat.leftdown = 1
  endif
  if (ev.press AND 6B) GT 0 then if not MouseStat.rightdown then begin
    ;prave tlacitko stisknuto
    MouseStat.xr1 = ev.x
    MouseStat.xr2 = ev.x
    MouseStat.yr1 = ev.y
    MouseStat.yr2 = ev.y
    MouseStat.rightdown = 1
  endif
  widget_control, ev.id, set_uvalue = MouseStat, draw_motion_events = $
    (MouseStat.leftdown or MouseStat.rightdown) mod 2
  end
1: begin; released
  if (ev.release AND 1B) then if MouseStat.leftdown then begin    
    ;leve tlacitko uvolneno
    button = 'Left'
    wset, win
    device, set_graphics_function = 6; nastaveni XOR grafiky
    x1 = MouseStat.xl1
    y1 = MouseStat.yl1
    x2 = MouseStat.xl2
    y2 = MouseStat.yl2
    if (x1 NE x2) or (y1 NE y2) then plots, [x1, x2, x2, x1, x1], [y1, y1, y2, y2, y1], /device
      ;mazani posledniho obdelnika
    x2 = ev.x
    y2 = ev.y
    device, set_graphics_function = 3; obnoveni prekreslovaci grafiky
    MouseStat.leftdown = 0
  endif
  if (ev.release AND 6B) GT 0 then if MouseStat.rightdown then begin    
    ;prave tlacitko uvolneno
    button = 'Right'
    wset, win
    device, set_graphics_function = 6; nastaveni XOR grafiky
    x1 = MouseStat.xr1
    y1 = MouseStat.yr1
    x2 = MouseStat.xr2
    y2 = MouseStat.yr2
    if (x1 NE x2) or (y1 NE y2) then plots, [x1, x2, x2, x1, x1], [y1, y1, y2, y2, y1], /device
      ;mazani posledniho obdelnika
    x2 = ev.x
    y2 = ev.y
    device, set_graphics_function = 3; obnoveni prekreslovaci grafiky
    MouseStat.rightdown = 0
  endif
  widget_control, ev.id, set_uvalue = MouseStat, draw_motion_events = $
    (MouseStat.leftdown or MouseStat.rightdown or descr.ShowDifferences) mod 2

  ;Predani udalosti
  if keyword_set(button) then begin
    if (ev.modifiers AND 1B) then button = 'Right'; Shift modifikuje leve tlacitko na prave
    if (abs(x2 - x1) GT 8) or (abs(y1 - y2) GT 8) then begin
      return, {id:ev.id, top:ev.top, handler:0L, type: button + 'Drag', x1:x1, y1:y1, x2:x2, y2:y2, win:win} 
    endif else begin
      return, {id:ev.id, top:ev.top, handler:0L, type: button + 'Click', x:x1, y:y1, win:win}
    endelse
  endif
  end

2: begin; pohyb mysi
  if MouseStat.leftdown then begin
    wset, win
    device, set_graphics_function = 6; nastaveni XOR grafiky
    x1 = MouseStat.xl1
    y1 = MouseStat.yl1
    x2 = MouseStat.xl2
    y2 = MouseStat.yl2
    if (x1 NE x2) or (y1 NE y2) then plots, [x1, x2, x2, x1, x1], [y1, y1, y2, y2, y1], /device
      ;smazani stareho obdelnika
    x2 = ev.x
    y2 = ev.y
    if (x1 NE x2) or (y1 NE y2) then plots, [x1, x2, x2, x1, x1], [y1, y1, y2, y2, y1], /device
      ;kresleni noveho obdelnika
    MouseStat.xl2 = x2
    MouseStat.yl2 = y2
    device, set_graphics_function = 3; obnoveni prekreslovaci grafiky
  endif
  if MouseStat.rightdown then begin
    wset, win
    device, set_graphics_function = 6; nastaveni XOR grafiky
    x1 = MouseStat.xr1
    y1 = MouseStat.yr1
    x2 = MouseStat.xr2
    y2 = MouseStat.yr2
    if (x1 NE x2) or (y1 NE y2) then plots, [x1, x2, x2, x1, x1], [y1, y1, y2, y2, y1], /device
      ;smazani stareho obdelnika
    x2 = ev.x
    y2 = ev.y
    if (x1 NE x2) or (y1 NE y2) then plots, [x1, x2, x2, x1, x1], [y1, y1, y2, y2, y1], /device
      ;kresleni noveho obdelnika
    MouseStat.xr2 = x2
    MouseStat.yr2 = y2
    device, set_graphics_function = 3; obnoveni prekreslovaci grafiky
  endif
  widget_control, ev.id, set_uvalue = MouseStat
  if descr.ShowDifferences then return, {id:ev.id, top:ev.top, handler:0L, type: 'MovedTo', x: ev.x, y: ev.y, win:win}
  end
endcase
return, 0
end


pro STMA_InvertPointSelection, top, x, y, description = descr
;K vybrane oblasti prida jeden bod se spektroskopii, pokud ve vybrane oblasti nelezel,
;nebo jej od vybrane oblasti odebere, pokud v ni lezel.
if not keyword_set(descr) then widget_control, top, get_uvalue = descr, update = 0
xgrid = (*descr.Parameters).XGrid
ygrid = (*descr.Parameters).YGrid
xsize = (*descr.Parameters).XPixels
ysize = (*descr.Parameters).XPixels
reg = descr.Region

;testing for an irregular grid (zeroes grid dimensions if it is irregular)
if (*descr.Data)[descr.Index].Parameters.SChannels GT 0 then begin
  if (*descr.Data)[descr.Index].IrregularGrid[descr.SChannel-1].n GT 0 then begin
    xgrid = 0
    ygrid = 0
  endif
endif

if (xgrid GT 0) and (ygrid GT 0) then begin
  x0 = 0 > ((x + (xgrid-1) / 2) / xgrid) * xgrid < (xsize-1)
  y0 = 0 > ((y + (ygrid-1) / 2) / ygrid) * ygrid < (ysize-1)
endif else begin
  x0 = 0 > x < (xsize-1)
  y0 = 0 > y < (ysize-1)
endelse
x2 = (x0 + xgrid / 2) < (xsize-1)
x1 = (x0 - (xgrid-1) / 2) > 0
y2 = (y0 + ygrid / 2) < (ysize-1)
y1 = (y0 - (ygrid-1) / 2) > 0
if (*reg)[x0, y0] then (*reg)[x1:x2, y1:y2] = 0 else (*reg)[x1:x2, y1:y2] = 1
STMA_RecalcImage, top, description = descr
STMA_RedrawTopography, top, description = descr
STMA_RecalcSpectrum, top, description = descr
STMA_RedrawSpectrum, top, description = descr
STMA_SpectInfo, top, description = descr
end


pro STMA_SinglePointSelection, top, x, y, description = descr
;Vyber bodu se spektrem v rezimu zobrazovan jednotlivych spekter
if not keyword_set(descr) then widget_control, top, get_uvalue = descr, update = 0
xgrid = (*descr.Parameters).XGrid 
ygrid = (*descr.Parameters).YGrid 
xsize = (*descr.Parameters).XPixels
ysize = (*descr.Parameters).XPixels

;testing for an irregular grid (zeroes grid dimensions if it is irregular)
if (*descr.Data)[descr.Index].Parameters.SChannels GT 0 then begin
  if size(*descr.Spectroscopy, /n_dimensions) NE 3 then begin
    xgrid = 0
    ygrid = 0
  endif
endif

if (xgrid GT 0) and (ygrid GT 0) then begin
  descr.x = 0 > ((x + (xgrid-1) / 2) / xgrid) * xgrid < (xsize-1)
  descr.y = 0 > ((y + (ygrid-1) / 2) / ygrid) * ygrid < (ysize-1)
endif else begin
  descr.x = 0 > x < (xsize-1)
  descr.y = 0 > y < (ysize-1)
endelse
STMA_RecalcImage, top, description = descr
STMA_RedrawTopography, top, description = descr
STMA_RecalcSpectrum, top, description = descr
STMA_RedrawSpectrum, top, description = descr
STMA_SpectInfo, top, description = descr
end


pro STMA_AddRegion, top, x1, y1, x2, y2, description = descr
;K vybrane oblasti prida obdelnikovou oblast
if not keyword_set(descr) then widget_control, top, get_uvalue = descr, update = 0
if x1 GT x2 then begin
  x = x1
  x1 = x2
  x2 = x
endif
if y1 GT y2 then begin
  y = y1
  y1 = y2
  y2 = y
endif
(*descr.Region)[x1:x2, y1:y2] = 1
STMA_RecalcImage, top, description = descr
STMA_RedrawTopography, top, description = descr
STMA_RecalcSpectrum, top, description = descr
STMA_RedrawSpectrum, top, description = descr
STMA_SpectInfo, top, description = descr
end


pro STMA_DelRegion, top, x1, y1, x2, y2, description = descr
;Odebere obdelnikovou obvlast od vybrane oblasti
if not keyword_set(descr) then widget_control, top, get_value = descr, update = 0
if x1 GT x2 then begin
  x = x1
  x1 = x2
  x2 = x
endif
if y1 GT y2 then begin
  y = y1
  y1 = y2
  y2 = y
endif
(*descr.Region)[x1:x2, y1:y2] = 0
STMA_RecalcImage, top, description = descr
STMA_RedrawTopography, top, description = descr
STMA_RecalcSpectrum, top, description = descr
STMA_RedrawSpectrum, top, description = descr
STMA_SpectInfo, top, description = descr
end


pro STMA_PointToRegion, top, x, y, description = descr
;K vybrane oblasti prida jeden bod se spektroskopii.

if not keyword_set(descr) then widget_control, top, get_uvalue = descr, update = 0
xgrid = (*descr.Parameters).XGrid 
ygrid = (*descr.Parameters).YGrid 
xsize = (*descr.Parameters).XPixels
ysize = (*descr.Parameters).XPixels
reg = descr.Region

;testing for an irregular grid (zeroes grid dimensions if it is irregular)
if (*descr.Data)[descr.Index].Parameters.SChannels GT 0 then begin
  if (*descr.Data)[descr.Index].IrregularGrid[descr.SChannel-1].n GT 0 then begin
    xgrid = 0
    ygrid = 0
  endif
endif

if (xgrid GT 0) and (ygrid GT 0) then begin
  x0 = 0 > ((x + (xgrid-1) / 2) / xgrid) * xgrid < (xsize-1)
  y0 = 0 > ((y + (ygrid-1) / 2) / ygrid) * ygrid < (ysize-1)
endif else begin
  x0 = 0 > x < (xsize-1)
  y0 = 0 > y < (ysize-1)
endelse
x2 = (x0 + xgrid / 2) < (xsize-1)
x1 = (x0 - (xgrid-1) / 2) > 0
y2 = (y0 + ygrid / 2) < (ysize-1)
y1 = (y0 - (ygrid-1) / 2) > 0
(*reg)[x1:x2, y1:y2] = 1
STMA_RecalcImage, top, description = descr
STMA_RedrawTopography, top, description = descr
STMA_RecalcSpectrum, top, description = descr
STMA_RedrawSpectrum, top, description = descr
STMA_SpectInfo, top, description = descr
end


pro STMA_PointOutOfRegion, top, x, y, description = descr
;Od vybrane oblasti odebere jeden bod se spektroskopii.

if not keyword_set(descr) then widget_control, top, get_uvalue = descr, update = 0
xgrid = (*descr.Parameters).XGrid
ygrid = (*descr.Parameters).YGrid
xsize = (*descr.Parameters).XPixels
ysize = (*descr.Parameters).XPixels

;testing for an irregular grid (zeroes grid dimensions if it is irregular)
if (*descr.Data)[descr.Index].Parameters.SChannels GT 0 then begin
  if (*descr.Data)[descr.Index].IrregularGrid[descr.SChannel-1].n GT 0 then begin
    xgrid = 0
    ygrid = 0
  endif
endif

reg = descr.Region
if (xgrid GT 0) and (ygrid GT 0) then begin
  x0 = 0 > ((x + (xgrid-1) / 2) / xgrid) * xgrid < (xsize-1)
  y0 = 0 > ((y + (ygrid-1) / 2) / ygrid) * ygrid < (ysize-1)
endif else begin
  x0 = 0 > x < (xsize-1)
  y0 = 0 > y < (ysize-1)
endelse
x2 = (x0 + xgrid / 2) < (xsize-1)
x1 = (x0 - (xgrid-1) / 2) > 0
y2 = (y0 + ygrid / 2) < (ysize-1)
y1 = (y0 - (ygrid-1) / 2) > 0
(*reg)[x1:x2, y1:y2] = 0
STMA_RecalcImage, top, description = descr
STMA_RedrawTopography, top, description = descr
STMA_RecalcSpectrum, top, description = descr
STMA_RedrawSpectrum, top, description = descr
STMA_SpectInfo, top, description = descr
end


pro STMA_ZoomTopoIn, top, x1, y1, x2, y2, description = descr
;Zobrazeni detainiho vyrezu z topografie
if not keyword_set(descr) then widget_control, top, get_uvalue = descr
if not descr.TopoZoom then begin
  widget_control, widget_info(top, find_by_uname = 'ShowAllTopoButton'), sensitive=1
endif
descr.TopoZoom = 1
descr.tx1 = x1
descr.tx2 = x2
descr.ty1 = y1
descr.ty2 = y2
STMA_UpdateTopography, top, description=descr
end


pro STMA_TopoWinEv, ev
;Procedura osetruje udalost v topografickem kreslicim okne
;Udalost je predzpracovana funkci STMA_AtDrawEv, uzivanou pro obe kreslici okna,
;a pak je predana teto procedure, ktera zajisti cinnost specifickou pro topografii.

;Prepocet souradnic z hardwaroveho do datoveho systemu:
widget_control, ev.top, get_uvalue = descr, update = 0
ImgXSize = (*descr.Parameters).Xpixels
ImgYSize = (*descr.Parameters).YPixels
wset, descr.TWindow
if keyword_set(descr.TScreenXSize) then WinXSize = descr.TScreenXSize else WinXSize = !D.X_SIZE
if keyword_set(descr.TScreenYSize) then WinYSize = descr.TScreenYSize else WinYSize = !D.Y_SIZE
;ImgXSize, ImgYSize = rozmery datoveho pole
;WinXSize, WinYsize = rozmery zobrazovaciho okna
if descr.TopoZoom then begin
  x01 = descr.tx1
  y01 = descr.ty1
  x02 = descr.tx2
  y02 = descr.ty2
endif else begin
  x01 = 0
  y01 = 0
  x02 = ImgXSize - 1
  y02 = ImgYSize - 1
endelse
xo = x01 < x02
yo = y01 < y02
dx = long(abs(x01 - x02) + 1)
dy = long(abs(y01 - y02) + 1)
if (strpos(ev.type, 'Click') GE 0) or (strpos(ev.type, 'Move') GE 0) then begin
  ev.y = ev.y + WinYSize - !D.X_SIZE
  
  x = 0 > (xo + (ev.x * dx) / WinXSize) < (ImgXSize - 1)
  y = 0 > (yo + (ev.y * dy) / WinYSize) < (ImgYSize - 1)
endif
if strpos(ev.type, 'Drag') GE 0 then begin
  ev.y1 = ev.y1 + WinYSize - !D.X_SIZE
  ev.y2 = ev.y2 + WinYSize - !D.Y_SIZE
  x1 = 0 > (xo + (ev.x1 * dx) / WinXSize) < (ImgXSize - 1)
  y1 = 0 > (yo + (ev.y1 * dy) / WinYSize) < (ImgYSize - 1)
  x2 = 0 > (xo + (ev.x2 * dx) / WinXSize) < (ImgXSize - 1)
  y2 = 0 > (yo + (ev.y2 * dy) / WinYSize) < (ImgYSize - 1)
endif

;Osetreni jednotlivych typu udalosti:
case ev.type of
'LeftClick': begin
  ;if not(descr.ShowDifferences) then begin ;M
  if descr.SinglePoint then begin
    STMA_SinglePointSelection, ev.top, x, y, descr = descr
  endif else begin
    STMA_InvertPointSelection, ev.top, x, y, descr = descr
  endelse 
  ;endif else begin ;M
  STMA_PositionInfo, ev.top, x, y, descr = descr
  ;endelse ;M
  end
'LeftDrag': begin

  ;uprava vyrezu na ctvercovy tvar
  if x2 GT x1 then x2 = x2 < (x1 + abs(y2 - y1)) else x2 = x2 > (x1 - abs(y2 - y1))
  if y2 GT y1 then y2 = y2 < (y1 + abs(x2 - x1)) else y2 = y2 > (y1 - abs(x2 - x1))

   STMA_ZoomTopoIn, ev.top, x1, y1, x2, y2, descr = descr
   end
'RightClick': if not descr.SinglePoint then case descr.AddDelMode of
     0: STMA_PointOutOfRegion, ev.top, x, y, descr = descr
     1: STMA_PointToRegion, ev.top, x, y, descr = descr
   endcase
'RightDrag': if not descr.SinglePoint then case descr.AddDelMode of
    0: STMA_DelRegion, ev.top, x1, y1, x2, y2, descr = descr
    1: STMA_AddRegion, ev.top, x1, y1, x2, y2, descr = descr
  endcase
'MovedTo': STMA_DifferenceInfo, ev.top, x, y, descr = descr
endcase
widget_control, ev.top, /update
end


pro STMA_SpectWinEv, ev
;Procedura osetruje udalost ve spektroskopickem kreslicim okne
;Udalost je predzpracovana funkci STMA_AtDrawEv, uzivanou pro obe kreslici okna,
;a pak je predana teto pocedure, ktera zajisti cinnost specifickou pro spektroskopii.

case ev.type of
'LeftClick':;no action
'LeftDrag':;no action
'RightClick':;no action
'RightDrag':;no action
endcase
end


pro STMA_SaveTopoAsTiff, ev                                                                                   
;ulozeni topografickeho obrazku ve formatu Tiff
                                                                                                         
widget_control, ev.top, get_uvalue = descr
win = descr.TWindow
filename = (*descr.Parameters).Topography[descr.TChannel-1].Filename
pos = strpos(filename, '.', /reverse_search)
if pos GE 0 then filename = strmid(filename, 0, pos)
filename = filename + '.tiff'
filename = dialog_pickfile(/write, file = filename, filter = '*.tiff', get_path = directory)
if filename EQ '' then return
wset, win
window, xsize = !D.x_size, ysize = !D.y_size, /free, /pixmap
tvlct, red, green, blue, /get
loadct, 0, /silent; loading grayscale for palette version
STMA_RedrawTopography, ev.top, win = !D.window, /grayscale
picture = tvrd(/order)
tvlct, red, green, blue
wdelete, !D.window
write_tiff, filename, picture, 1, red = red, green = green, blue = blue
cd, directory
end



pro STMA_SaveTopoAsPNG, ev                                                                                   
;ulozeni topografickeho obrazku ve formatu PNG
                                                                                                         
widget_control, ev.top, get_uvalue = descr
win = descr.TWindow
filename = (*descr.Parameters).Topography[descr.TChannel-1].Filename
pos = strpos(filename, '.', /reverse_search)
if pos GE 0 then filename = strmid(filename, 0, pos)
filename = filename + '.PNG'
filename = dialog_pickfile(/write, file = filename, filter = '*.PNG', get_path = directory)
if filename EQ '' then return
wset, win
window, xsize = !D.x_size, ysize = !D.y_size, /free, /pixmap
tvlct, red, green, blue, /get
loadct, 0, /silent; loading grayscale for palette version
STMA_RedrawTopography, ev.top, win = !D.window, /grayscale
picture = tvrd(/order)
PNG_save,filename, picture
cd, directory
end


pro STMA_SaveSpectAsCrv, ev
;ulozi spektroskopickou krivku jako soubor *.crv

widget_control, ev.top, get_uvalue = descr
filename = (*descr.Parameters).Topography[descr.SChannel-1].Filename
pos = strpos(filename, '.', /reverse_search)
if pos GE 0 then filename = strmid(filename, 0, pos)
filename = filename + '.crv'
filename = dialog_pickfile(/write, filter = '*.crv', file = filename, get_path = directory, dialog_parent = ev.top)
if keyword_set(directory) then cd, directory
if not keyword_set(filename) then return

;otevreni souboru pro zapis
catch, ErrOpening
if keyword_set (ErrOpening) then begin
  errtext = 'Unable to open file "' + filename + '"'
  print, !ERROR_STATE.MSG_PREFIX + errortext
  ok = dialog_message(errortext, /error, dialog_parent = ev.top)
  return
endif
openw, LUN, filename, /GET_LUN
catch, /cancel

;priprava dat
parfile = (*descr.Data)[descr.Index].ParFile
date = (*descr.Parameters).Time
type = (*descr.Parameters).Spectroscopy[descr.SChannel-1].Type
info = (*descr.Parameters).Comment
ncurves = 1
npoints = (size(*descr.Curve))[1]
xunit = (*descr.Parameters).Spectroscopy[descr.SChannel-1].Parameter
yunit = (*descr.Parameters).Spectroscopy[descr.SChannel-1].Unit
x = fltarr(npoints, ncurves, /nozero)
y = fltarr(npoints, ncurves, /nozero)
for i = 0, ncurves - 1 do begin
x[*,i] = (*descr.Curve)[*,0]
y[*,i] = (*descr.Curve)[*,1]
endfor

;zapis hlavicky
printf, LUN, ';'
printf, LUN, format = "(';', 15X, 'File for curve data.')"
printf, LUN, format = "(';', 15X, '  Written by STMA.  ')"
printf, LUN, ';'
printf, LUN, 'Parameter File             : ', parfile
printf, LUN, 'Date                       : ', date
printf, LUN, 'Type of Curve              : ', type
printf, LUN, 'Curve Information          : ', info
printf, LUN, 'Number of Curves           : ', strtrim(ncurves, 2)
printf, LUN, 'Number of Points per Curve : ', strtrim(npoints, 2)
printf, LUN, 'X Unit                     : ', xunit
printf, LUN, 'Y Unit                     : ', yunit

;zapis krivky
for i = 0, ncurves - 1 do begin
printf, LUN
printf, LUN, 'Curve                      : ', strtrim(i + 1, 2)
for j = 0, npoints - 1 do begin
  printf, LUN, format ="(F13.5, F15.6)", x[j,i], y[j,i]  
endfor
endfor

free_LUN, LUN
end


pro STMA_DestructApp, id
;ruseni dynamickych promenych
widget_control, id, get_uvalue = descr
if ptr_valid(descr.Data) then begin
  ClearSTM, *descr.Data
  ptr_free, descr.Data
endif
if ptr_valid(descr.Regions) then begin
  if keyword_set(*descr.Regions) then ptr_free, *descr.Regions
  ptr_free, descr.Regions
endif
ptr_free, descr.Parameters, descr.Topography, descr.Spectroscopy, descr.Region
ptr_free, descr.Image, descr.Curve
;obnova grafiky (cernobila paleta)
Palette = descr.OldPalette
tvlct, Palette.r, Palette.g, Palette.b
end


pro STMA, datalist, xsize = xsize, ysize = ysize

;xszie = vodorovny rozmer okna aplikace
;ysize = svisly rozmer okna aplikace

;Pocatecni cteni dat
if keyword_set(datalist) then begin
  data = LoadSTM(datalist, OK = OK)
endif else begin
  data = LoadSTM(directory = directory, OK = OK)
  if keyword_set(directory) then cd, directory
end


;Zjisteni barevne palety
tvlct, r, g, b, /get

;Struktura popisujici stav aplikace STMA:
descr = {n: 0, Data: ptr_new(0), Index: 0, TWindow: 0, SWindow: 0, $
  Parameters: ptr_new(0), TChannel: 1, SChannel: 1, $
  Topography: ptr_new(), Spectroscopy: ptr_new(), $
  Image: ptr_new(0), Curve: ptr_new(0), $
  Region: ptr_new(), Regions: ptr_new(0), $
  OldPalette: {r: r, g: g, b: b}, $
  SubtrPlane: 1, ShowGrid: 1, TopoZoom:0, tx1:0, tx2:0, ty1:0, ty2:0, $
  Interpolate: 0, InvertColors: 0, ShowDifferences: 0, x0: 0, y0: 0, $
  MaxFilter:0, Smooth: 0, SinglePoint: 1, AddDelMode:1, x: 0, y: 0, NSpectraUsed: 0, $
  TScreenXSize: 0, TScreenYSize: 0}

app = widget_base(/column, app_mbar = menu, title = 'STM Result Analysis', /tlb_kill_request_events, $
  kill_notify = 'STMA_DestructApp', scr_xsize = xsize, scr_ysize = ysize, uvalue = descr)

file = widget_button(menu, value = 'File', /menu)
open = widget_button(file, value = 'Open', event_pro = 'STMA_OpenFileDialog')
add = widget_button(file, value = 'Add', event_pro = 'STMA_AddFiles')
openlist = widget_button(file, value = 'OpenList', event_pro = 'STMA_OpenListDialog')
addlist = widget_button(file, value = 'AddList', event_pro = 'STMA_AddListDialog')
closef = widget_button(file, value = 'Close', event_pro = 'STMA_CloseFileDialog', uname = 'CloseFiles', $
  sensitive = 0, /separator)
savet = widget_button(file, value = 'SaveTopography', uname = 'SaveTopography', /menu) 
tiff = widget_button(savet, value = 'TIFF', uname = 'SaveTopoAsTiff', event_pro = 'STMA_SaveTopoAsTiff')
png = widget_button(savet, value = 'PNG', uname = 'SaveTopoAsPNG', event_pro = 'STMA_SaveTopoAsPNG')

saves = widget_button(file, value = 'SaveSpectroscopy', uname = 'SaveSpectroscopy', /menu)
crv = widget_button(saves, value = 'CRV', uname = 'SaveSpectAsCrv', event_pro = 'STMA_SaveSpectAsCrv', /separator)
newapp = widget_button(file, value = 'NewApplication', event_pro = 'STMA_NewApp')
mono = widget_button(file, value = 'MONOSPECm', event_pro = 'STMA_NewMonospec')
quit = widget_button(file, value = 'Quit', event_pro = 'STMA_Quit')

drawmenu = widget_button(menu, value = 'Filters', /menu)
;Pozn.: Volani 'STMA_MenuSwitchPreset' po definici tech polozek menu, ktere maji slouzit jako prepinace,
;je nutne k tomu, aby byl spravne nastaven pocatecni stav prepinace
SubtrPlaneButton = widget_button(drawmenu , value = ' Slope compensation', event_pro = 'STMA_SubtrPlaneSelect')
STMA_MenuSwitchPreset, SubtrPlaneButton, descr.SubtrPlane
ShowGridButton = widget_button(drawmenu, value = ' Show grid', event_pro = 'STMA_ShowGridSelect')
STMA_MenuSwitchPreset, ShowGridButton, descr.ShowGrid
InterpolateButton = widget_button(drawmenu, value = ' Interpolate', event_pro = 'STMA_InterpolateSelect')
STMA_MenuSwitchPreset, InterpolateButton, descr.Interpolate
InvertColorButton = widget_button(drawmenu, value = ' InvertColors', event_pro = 'STMA_InvertColorSelect')
STMA_MenuSwitchPreset, InvertColorButton, descr.InvertColors

SmoothButton = widget_button(drawmenu, value = ' Smooth', event_pro = 'STMA_SmoothSelect')
STMA_MenuSwitchPreset, SmoothButton, descr.Smooth


top = widget_base(app, /row, uname = 'Top')
subtop = widget_base(app, /row, uname = 'Subtop')
prev = widget_button(top, value = '<<Previous', uname = 'PreviousFile', event_pro = 'STMA_PrevFile', sensitive = 0)
next = widget_button(top, value = 'Next>>', uname = 'NextFile', event_pro = 'STMA_NextFile', sensitive = 0)
g1 = widget_info(prev, /geometry)
g2 = widget_info(next, /geometry)
headerbase = widget_base(top, /column, frame=0)
header = widget_label(headerbase, scr_xsize = 800-g1.xsize-g2.xsize, uname = 'Header', /align_left, value=' ')
comment = widget_label(headerbase, scr_xsize = 800-g1.xsize-g2.ysize, uname = 'Comment', /align_left, value=' ')

main = widget_base(app, /row, uname = 'Main')
topo = widget_base(main, /column, uname = 'Topography', event_pro = 'STMA_TopoWinEv')
t_top = widget_base(topo, /row)
lefttop = widget_base(t_top, /column, /base_align_left)
righttop = widget_base(t_top, /column, /base_align_left)
channel = widget_button(lefttop, /menu, uname = 'TChannelList', value =      'TOPOGRAPHIC CHANNEL:     ')
label1 = widget_label(lefttop, uname = 'TFileName', /dynamic_resize, value = 'FILE:                    ')
label2 = widget_label(righttop, uname = 'TProperties', /dynamic_resize, value = 'FEEDBACK:                    ')
label3 = widget_label(righttop, uname = 'TArea', /dynamic_resize, value =       'AREA:                        ')

twindow = widget_draw(topo, /button_events, xsize = 400, ysize = 400, event_func = 'STMA_AtDrawEv', uname = 'TWindow')

posinfo = widget_label(topo, uname = 'PositionInfo', /dynamic_resize, /align_left, $
  value = 'X:        nm  Y:        nm  Z:          nm')
difinfo = widget_label(topo, uname = 'DifferenceInfo', /dynamic_resize, /align_left, $
  value = '                                          ')
tools = widget_base(topo, /row)
buttons1 = widget_base(tools, frame = 0, /column)
buttons2 = widget_base(buttons1, /nonexclusive, frame = 0)
ShowDifButton = widget_button(buttons2, value = 'ShowDifferences', event_pro = 'STMA_ShowDifSelect')
showall = widget_button(buttons1, value = 'Reload', event_pro = 'STMA_ShowAllTopo', sensitive = 1, $
  uname = 'ShowAllTopoButton')

AddDelMode = widget_base(tools, frame = 0, /column, sensitive = 1, uname = 'AddDelMode')
label = widget_label(AddDelMode, value = 'Selection Mode:')
AddDelButtons = widget_base(AddDelMode, /exclusive, frame = 0)
single = widget_button(AddDelButtons, value = 'Single Spectrum', event_pro = 'STMA_SinglePointMode')
add = widget_button(AddDelButtons, value = 'AddToRegion', event_pro = 'STMA_AddRegMode')
del = widget_button(AddDelButtons, value = 'DeleteRegion', event_pro = 'STMA_DelRegMode')
if descr.SinglePoint then widget_control, single, /set_button $
else if descr.AddDelMode EQ 1 then widget_control, add, /set_button $
else if descr.AddDelMode EQ 0 then widget_control, del, /set_button
widget_control, ShowDifButton, set_button = descr.ShowDifferences

spect = widget_base(main, /column, uname = 'Spectroscopy', event_pro = 'STMA_SpectWinEv')
s_top = widget_base(spect, /row)
lefttop = widget_base(s_top, /column, /base_align_left)
righttop = widget_base(s_top, /column, /base_align_left)
channel = widget_button(lefttop, /menu, uname = 'SChannelList', value =      'SPECTROSCOPY CHANNEL:     ')
label1 = widget_label(lefttop, uname = 'SFileName', /dynamic_resize, value = 'FILE:                      ')
label2 = widget_label(righttop, value = '')
label3 = widget_label(righttop, uname = 'SArea', /dynamic_resize, value = '                             ')
swindow = widget_draw(spect, /button_events, xsize = 400, ysize = 400, event_func = 'STMA_AtDrawEv')
label4 = widget_label(spect, uname = 'SpInfo', /dynamic_resize, value = '                         ')

GoldPalette

widget_control, app, /realize
widget_control, twindow, get_value = win
descr.TWindow = win
widget_control, swindow, get_value = win
descr.SWindow = win
widget_control, app, set_uvalue = descr
if OK then STMA_AddNewData, app, data, description = descr
xmanager, 'STMA', app, event_handler = 'STMA_AtTlbEvent'
end
