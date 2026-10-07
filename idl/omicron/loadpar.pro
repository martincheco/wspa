;Tento soubor obsahuje definici funkce LoadPar, ktera nacte parametry STM mereni
;ze souboru typu *.par
;Funkce vraci strukturu typu ParStruct
;POLOZKY STRUKTURY:
;Time = datum a cas mereni
;XPixels, YPixels = rozmery obrazku v pixelech (topografickych bodech)
;IncrementX, IncrementY = fyzikalni vzdalenosti [nm] odpovidajici jednomu pixelu ve smerech X a Y
;XGrid, YGrid = pocet topografickych bodu ve smeru X a Y na jeden bod, v nemz byla sejmuta spektra
;XPoints, YPoints = pocet topografickych bodu ve smerech X a Y, v nichz byla snimana spektra
;VoltageForward = napeti pri skenovani vpred [V]
;VoltageBackward = napeti pri skenovani zpet [V]
;CurrentForward = proud udrzovany zpetnou vazbou pri skenovani vpred [nA];
;CurrentBackward = proud udrzovany zpetnou vazbou pri skenovani zpet [nA];
;ScanSpeed = rychlost skenovani [nm/s]
;XDrif, YDrift = drift ve smerech X a Y [nm/s]
;Comment = komentar uzivatele
;TChannels = pocet topografickych kanalu
;Topography = pole struktur popisujicich jednotlive topograficke kanaly
;  Type = typ topografickeho kanalu
;    ('Z' = sledovani vysky hrotu nad vzorkem pri konstantnim proudu)
;  Direction = smer skenovani ('forward' = vpred, 'backward' = zpet)
;  Resolution = vyjadreni zmeny dat kanalu o 1.0 ve fyzikalnich jednotkach
;  Unit = oznaceni fyzikalni jednotky, ve ktere je vyjadrena promenna Resolution
;  FileName = jmeno souboru s daty z daneho topografickeho kanalu
;SChannels = pocet spektroskopickych kanalu
;Spectroscopy = pole struktur popisujicich jednotlive spektroskopicke kanaly
;  Parameter = oznaceni nezavisle promenne veliciny v merenych spektrech
;  Type = oznaceni zavisle promenne veliciny v merenych spektrech, urcuje typ spektroskopie
;  Direction = smer skenovani, pri kterem byla snimana spektra ('forward', 'backward')
;  Start = pocatecni hodnota nezavisle promenne pri snimani spektra
;  Increment = zmena nezavisle promenne v jednom kroku pri snimani spektra
;  Points = pocet spektralnich bodu v jednom spektru
;  Resolution = vyjadreni zmeny zavisle promenne o 1.0 ve fyzikalnich jednotkach
;  Unit = oznaceni fyzikalni jednotky zavisle promenne veliciny
;  FileName = jmeno souboru se spektry
;KONEC STRUKTURY


pro ReadNamedFValue, s, name, v, OK, found = found
;Precte realnou ciselnou hodnotu z retezce,
;pokud se v retezci jako podretezec vyskytuje zadane jmeno
;Ciselnou hodnotu v retezci procedura hleda za dvojteckou,
;neni-li dvojtecka pritomna, pak tesne za jmenem
;s = zdrojovy (vstupni) retezec
;name = jmeno hodnoty (hledany podretezec)
;v = promenna pro ulozeni ciselne hodnoty
;found = TRUE pokud bylo nalezeno zadane jmeno
;OK = promenna, do niz se v pripade chyby zapise 0

;s = strlowcace(strcompress(s)) & name = strlowcase(strcompress(name))
;po zarazeni vyse napsaneho radku do procedury neni procedura citliva na
;velka a mala pismena ani na pocet mezer mezi slovy
;print,"reading:",name
on_ioerror, failed
found = (strpos(s, name) GE 0)
if found then begin
  p = strpos(s, ':')
  if p GE 0 then s1 = strmid(s, p+1) else s1 = strmid(s, strpos(s, name) + strlen(name))
  v = 0.0
  reads, s1, v
endif
return
failed: OK = 0
print, !ERROR_STATE.MSG_PREFIX + 'Floating point value expected in the following line:'
print, s
print,"position:",p
print,"searched name",name
end

pro ReadNamedIValue, s, name, v, OK, found = found
;Precte celociselnou hodnotu z retezce,
;pokud se v retezci jako podretezec vyskytuje zadane jmeno
;Ciselnou hodnotu v retezci procedura hleda za dvojteckou,
;neni-li dvojtecka pritomna, pak tesne za jmenem
;s = zdrojovy (vstupni) retezec
;name = jmeno hodnoty (hledany podretezec)
;v = promenna pro ulozeni ciselne hodnoty
;found = TRUE pokud bylo nalezeno zadane jmeno
;OK = promenna, do niz se v pripade chyby zapise 0

;s = strlowcase(strcompress(s)) & name = strlowcase(strcompress(name))
;po zarazeni vyse napsaneho radku do procedury neni procedura citliva na
;velka a mala pismena ani na pocet mezer mezi slovy

on_ioerror, failed
found = (strpos(s, name) GE 0)
if found then begin
  p = strpos(s, ':')
  if p GE 0 then s1 = strmid(s, p+1) else s1 = strmid(s, strpos(s, name) + strlen(name))
  v = 0L
  reads, s1, v
endif
return
failed: OK = 0
print, !ERROR_STATE.MSG_PREFIX + 'Integer value expected in the following line:'
print, s
end

pro ReadNamedSValue, s, name, v, OK, found = found
;Precte podretezec z retezce,
;pokud se v retezci jako dalsi podretezec vyskytuje zadane jmeno
;Cteny podretezec v retezci procedura hleda za dvojteckou
;neni-li dvojtecka pritomna, pak tesne za jmenem
;V prectenem podretezci jsou vynechany pocatecni a koncove mezery
;a vicnasobne mezery mezi slovy jsou nahrazeny jednoduchymi
;s = zdrojovy (vstupni) retezec
;name = jmeno hodnoty (hledany podretezec)
;v = promenna pro ulozeni precteneho podretezce
;found = TRUE pokud bylo nalezeno zadane jmeno
;OK = promenna, do niz se v pripade chyby zapise 0 (nevyuziva se)

;s = strlowcase(strcompress(s)) & name = strlowcase(strcompress(name))
;po zarazeni vyse napsaneho radku do procedury neni procedura citliva na
;velka a mala pismena ani na pocet mezer mezi slovy

found = (strpos(s, name) GE 0)
if found then begin
  p = strpos(s, ':')
  if p GE 0 then s1 = strmid(s, p+1) else s1 = strmid(s, strpos(s, name) + strlen(name))
  v = strcompress(strtrim(s1, 2))
endif
end

pro ReadFValue, s, v, OK
;Precte realnou ciselnou hodnotu z retezce
;s = zdrojovy (vstupni) retezec
;v = promenna pro ulozeni ciselne hodnoty
;OK = promenna, do niz se v pripade chyby zapise 0

on_ioerror, failed
v = 0.0
reads, s, v
return
failed: OK = 0
print, !ERROR_STATE.MSG_PREFIX + 'Floating point value expected in the following line:'
print, s
print,"error occured in ReadFValue"
end

pro ReadIValue, s, v, OK
;Precte celociselnou hodnotu z retezce
;s = zdrojovy (vstupni) retezec
;v = promenna pro ulozeni ciselne hodnoty
;OK = promenna, do niz se v pripade chyby zapise 0

on_ioerror, failed
v = 0L
reads, s, v
return
failed: OK = 0
print, !ERROR_STATE.MSG_PREFIX + 'Integer value expected in the following line:'
print, s
end

pro ReadSValue, s, v, OK
;Precte podretezec z retezce
;V prectenem podretezci jsou vynechany pocatecni a koncove mezery
;a vicnasobne mezery mezi slovy jsou nahrazeny jednoduchymi
;s = zdrojovy (vstupni) retezec
;v = promenna pro ulozeni precteneho podretezce
;OK = promenna, do niz se v pripade chyby zapise 0 (nevyuziva se)

v = strcompress(strtrim(s, 2))
end


function LoadPar, filename, OK = OK, MaxChannels = mcn
;Nacteni  dat ze souboru *.par do datove struktury
;filename = jmeno souboru vcetne pripony ".par"
;OK = nacteni proehlo vporadku
;MaxChannels = maximalni pocet kanalu jednoho druhu (topografickych nebo spektroskopickych)
if not keyword_set(mcn) then mcn = 8
;print, mcn
Par = {ParStruct, Time:'', XPixels:0, YPixels:0, IncrementX:0.0, IncrementY:0.0, $
  XGrid:0, YGrid:0, XPoints:0, YPoints:0, VoltageForward:0.0, VoltageBackward:0.0, $
  CurrentForward:0.0, CurrentBackward:0.0, ScanSpeed:0.0, XDrift:0.0, YDrift:0.0, Comment:'', $
  Topography: replicate({TStruct, Type:'', Direction:'', Resolution:0.0, Unit:'', FileName:''}, mcn), $
  Spectroscopy: replicate({SStruct, Parameter: '', Type:'', Direction:'', Start:0.0, $
    Increment:0.0, Points:0, Resolution:0.0, Unit:'', FileName:''}, mcn), $
  TChannels:0, SChannels:0}

;Struktura Par typu ParStruct slouzi pro ulozeni parametru nactenych ze souboru "*.par" 
;Vyznam jednotlivych polozek - viz zacatek souboru

if not keyword_set(filename) then begin
  OK = 0
  return, Par
endif


catch, ErrOpening
if keyword_set (ErrOpening) then begin
  OK = 0
  print, !ERROR_STATE.MSG_PREFIX + 'loadpar: Unable to open file "' + filename + '"'
  return, Par
endif

;print,'opening',filename

;openr, LUN, filename, /get_LUN

;help,filename
;help,!GDL,/struct

catch, /cancel
openr, LUN, filename,/get_LUN

OK = 1
tcn = 0; pocet topografickych kanalu
scn = 0; pocet spektroskopickych kanalu
DualMode = 'off'

while not eof(LUN) do begin
  ;Hledani klicovych jmen a odpovidajicich udaju v nactenem radku, zapis do datove struktury
  line = ReadLine(LUN)
  ReadNamedSValue, line, 'Original run/scan cycle identification', Matrixid, OK
  ReadNamedSValue, line, 'Date', Time, OK
  ReadNamedSValue, line, 'Comment', Comment, OK
  ReadNamedIValue, line, 'Image Size in X', XPixels, OK
  ReadNamedIValue, line, 'Image Size in Y', YPixels, OK
  ReadNamedFValue, line, 'Increment X', IncrementX, OK
  ReadNamedFValue, line, 'Increment Y', IncrementY, OK
  ReadNamedSValue, line, 'Topographic Channel', Type, OK, found = ReadingTopography
  if ReadingTopography then if tcn LT mcn then begin 
    ;Ctou se parametry topografickeho kanalu
    line = ReadLine(LUN)
    ReadSValue, line, Direction, OK  ;Forward or Backward
    Direction = strlowcase(Direction)
    line = ReadLine(LUN)
    ReadIValue, line, Ignored, OK  ;Minimum raw value
    line = ReadLine(LUN)
    ReadIValue, line, Ignored, OK  ;Maximum raw value
    line = ReadLine(LUN)
    ReadFValue, line, Ignored, OK  ;Minimum value in physical unit
    line = ReadLine(LUN)
    ReadFValue, line, Ignored, OK  ;Maximum value in physical unit
    line = ReadLine(LUN)
    ReadFValue, line, Resolution, OK  ;Resolution
    line = ReadLine(LUN)
    ReadSValue, line, Unit, OK  ;Physical unit
    line = ReadLine(LUN)
    ReadSValue, line, File, OK  ;Filename
    line = ReadLine(LUN)
    ReadSValue, line, Ignored, OK  ;Display name
    if keyword_set(Type) then Par.Topography[tcn].Type = Type
    if keyword_set(Direction) then Par.Topography[tcn].Direction = Direction
    if (Direction NE 'forward') and (Direction NE 'backward') then begin
      OK = 0
      print, !ERROR_STATE.MSG_PREFIX + '"forward" or "backward" expected instead of "' + Direction + "'"
    endif
    if keyword_set(Resolution) then Par.Topography[tcn].Resolution = Resolution
    if keyword_set(Unit) then Par.Topography[tcn].Unit = Unit
    if keyword_set(File) then Par.Topography[tcn].FileName = File
    tcn = tcn + 1
  endif else begin
    OK = 0
    print, !ERROR_STATE.MSG_PREFIX + 'Too much topographic channels'
  endelse


  ReadNamedSValue, line, 'Spectroscopy Channel', Type, OK, found = ReadingSpectroscopy
  if ReadingSpectroscopy then if scn LT mcn then begin
    ;Ctou se parametry spektroskopickeho kanalu
    line = ReadLine(LUN)
    ReadSValue, line, Parameter, OK  ;Parameter
    line = ReadLine(LUN)
    ReadSValue, line, Direction, OK  ;forward or backward
    Direction = strlowcase(Direction)
    line = ReadLine(LUN)
    ReadIValue, line, Ignored, OK  ;Minimum raw value
    line = ReadLine(LUN)
    ReadIValue, line, Ignored, OK  ;Maximum raw value
    line = ReadLine(LUN)
    ReadFValue, line, Ignored, OK  ;Minimum value in physical unit
    line = ReadLine(LUN)
    ReadFValue, line, Ignored, OK  ;Maximum value in physical unit
    line = ReadLine(LUN)
    ReadFValue, line, Resolution, OK ; Resolution
    line = ReadLine(LUN)
    ReadSValue, line, Unit, OK  ;Physical unit
    line = ReadLine(LUN)
    ReadIValue, line, Points, OK  ;Number of spectroscopy points
    line = ReadLine(LUN)
    ReadFValue, line, Start, OK  ;Start point spectroscopy
    line = ReadLine(LUN)
    ReadFValue, line, Ignored, OK  ;End point spectroscopy
    line = ReadLine(LUN)
    ReadFValue, line, Increment, OK  ;Increment point spectroscopy
    line = ReadLine(LUN)
    ReadFValue, line, Ignored, OK  ;Acquisition time per spectroscopy point
    line = ReadLine(LUN)
    ReadFValue, line, Ignored, OK  ;Delay time per spectroscopy point
    line = ReadLine(LUN)
    ReadSValue, line, Ignored, OK  ;Feedback On/Off
    line = ReadLine(LUN)
    ReadSValue, line, File, OK  ;Filename
    line = ReadLine(LUN)
    ReadSValue, line, Ignored, OK  ;Display name
    Points = abs(Points)
    if keyword_set(Parameter) then Par.Spectroscopy[scn].Parameter = Parameter
    if keyword_set(Type) then Par.Spectroscopy[scn].Type = Type
    if keyword_set(Direction) then Par.Spectroscopy[scn].Direction = Direction
    if (Direction NE 'forward') and (Direction NE 'backward') then begin
      OK = 0
      print, !ERROR_STATE.MSG_PREFIX + '"forward" or "backward" expected instead of "' + Direction + "'"
    endif
    if keyword_set(Start) then Par.Spectroscopy[scn].Start = Start
    if keyword_set(Increment) then Par.Spectroscopy[scn].Increment = Increment
    if keyword_set(Points) then Par.Spectroscopy[scn].Points = Points
    if keyword_set(Resolution) then Par.Spectroscopy[scn].Resolution = Resolution
    if keyword_set(Unit) then Par.Spectroscopy[scn].Unit = Unit
    if keyword_set(File) then Par.Spectroscopy[scn].FileName = File
    scn = scn + 1
  endif else begin
    OK = 0
    print, !ERROR_STATE.MSG_PREFIX + 'Too much spectroscopic channels'
  endelse
  ReadNamedSValue, line, 'Dual mode', DualMode, OK


 if not(keyword_set(VoltageForward)) then begin ; tweak for 'Measured Gap Voltage'
  
  ReadNamedFValue, line, 'Gap Voltage', VoltageForward, OK, found = ReadingVoltage
  if ReadingVoltage then begin
    if strlowcase(DualMode) EQ 'on' then begin
      line = ReadLine(LUN)
      ReadFValue, line, VoltageBackward, OK
    endif else VoltageBackward = VoltageForward
  endif
  
 endif
  
  ReadNamedFValue, line, 'Feedback Set', CurrentForward, OK, found = ReadingCurrent
  if ReadingCurrent then begin
    if strlowcase(DualMode) EQ 'on' then begin
      line = ReadLine(LUN)
      ReadFValue, line, CurrentBackward, OK
    endif else CurrentBackward = CurrentForward
  endif
  ReadNamedFValue, line, 'Scan Speed', ScanSpeed, OK
  ReadNamedFValue, line, 'X Drift', XDrift, OK
  ReadNamedFValue, line, 'Y Drift', YDrift, OK
  ReadNamedIValue, line, 'Spectroscopy Grid Value in X', XGrid, OK
  ReadNamedIValue, line, 'Spectroscopy Grid Value in Y', YGrid, OK
  ReadNamedIValue, line, 'Spectroscopy Points in X', XPoints, OK
  ReadNamedIValue, line, 'Spectroscopy Lines in Y', YPoints, OK
endwhile
Par.TChannels = tcn
Par.SChannels = scn
if keyword_set(Time) then Par.Time = Time
if keyword_set(Comment) then Par.Comment = Comment
if keyword_set(Matrixid) then Par.Comment = Par.Comment+Matrixid
;print,"Matrixid"+matrixid
if keyword_set(XPixels) then Par.XPixels = abs(XPixels)
if keyword_set(YPixels) then Par.YPixels = abs(YPixels)
if keyword_set(IncrementX) then Par.IncrementX = IncrementX
if keyword_set(IncrementY) then Par.IncrementY = IncrementY
if keyword_set(VoltageForward) then Par.VoltageForward = VoltageForward
if keyword_set(VoltageBackward) then Par.VoltageBackward = VoltageBackward
if keyword_set(CurrentForward) then Par.CurrentForward = CurrentForward
if keyword_set(CurrentBackward) then Par.CurrentBackward = CurrentBackward
if keyword_set(ScanSpeed) then Par.ScanSpeed = ScanSpeed
if keyword_set(XDrift) then Par.XDrift = XDrift
if keyword_set(YDrift) then Par.YDrift = YDrift
if scn GT 0 then begin
  if keyword_set(XGrid) then Par.XGrid = abs(XGrid)
  if keyword_set(YGrid) then Par.YGrid = abs(YGrid)
  if keyword_set(XPoints) then Par.XPoints = abs(XPoints)
  if keyword_set(YPoints) then Par.YPoints = abs(YPoints)
endif
free_LUN, LUN
return, Par
end
