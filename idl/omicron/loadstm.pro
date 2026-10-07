function LoadSTM, filename, directory = directory, OK = OK, ParentID = ParentID, nospectra = nospectra 
;Funkce LoadSTM precte data o STM mereni a vraci je jako pole struktur STMDataStruct
;Neni-li zadano jmeno souboru (jmena souboru) parametrem, 
;muze jej uzivatel zvolit interaktivne
;filename = jmeno parametrickeho souboru (i vice souboru) vcetne pripony ".par"
;directory = adresar se soubory
;OK = alespon jedno mereni se nacetlo spravne
;ParentID = identifikacni cislo volajiciho widgetu, je-li funkce pouzita ve widgetove aplikaci
;/nospectra = nectou se spektroskopicke soubory

;Polozky struktury typu STMDataStruct:
;Parameters = struktura typu ParStruct obsahujici parametry mereni
;ParFile = jmeno parametrickeho souboru vcetne cesty
;Dir = adresar, ve kterem se nachazi parametricky soubor a ostatni soubory s namerenymi daty
;Images = pole ukazetelu na topograficke obrazky z jednotlivych kanalu
;Spectra = pole ukazatelu na spektra z jednotlivych kanalu
;xscl = analogicke spectra, xova osa
;IrregularGrid = pole struktur IrrGridDescr popisujicich nepravidelnou mrizku
;                pro jednotlive spektroskopicke kanaly
;GridType = typ mrizky topografickych bodu, v nichz se smimala spektra 
;  1 = pravidelna mrizka (urcena v *.par souboru)
;  2 = nepravidelna mrizka (prectna z *.cs souboru)

;Polozky struktury IrrGridDescr:
;x = ukazatel na pole horizontalnich souradnic bodu mrizky
;y = ukazatel na pole vertikalnich souradnic bodu mrizky
;n = pocet bodu nepravidelne mrizky

if keyword_set(directory) then begin 
print ,'LoadSTM got a dir'

if File_Test(directory,/directory) then cd, directory $
else begin
print,directory
directory=dialog_pickfile(path='/', /directory)
end
print, 'Using the directory'+directory
spawn,'ls '+directory+'/*.par',filename
end



if not keyword_set(filename) then begin
  interactive = 1
  files = dialog_pickfile(/read, /must_exist, filter = '*.par', /multiple, get_path = directory)
endif else begin
  interactive = 0
  files = filename
endelse

if size(files, /n_dimensions) EQ 0 then files = [files]
if keyword_set(ParentID) then widget_control, /hourglass
n = 0
for i = 0, n_elements(files) - 1 do begin  
file = files[i]; jmeno parametrickeho souboru
  if not interactive then directory = Autodir(file)
  if keyword_set(file) then begin
    ;Cteni parametrickeho souboru
    ;print, 'Reading "'  + file + '" ...'
    Par = LoadPar(file, OK = ReadOK)
    if not ReadOK then begin
      ;print, 'Readig file failed'
      Err = 'Reading parameters from "' + file + '" unsuccessful'
      print, Err
      ;if interactive then void = dialog_message(Err, /error, dialog_parent = ParentID)
    endif else begin
      ;print, 'Reading file succeeded'
      MaxTChannels = n_elements(Par.Topography)
      MaxSChannels = n_elements(Par.Spectroscopy)
      Images = ptrarr(MaxTChannels)
      Spectra = ptrarr(MaxSChannels)
      Xscl = ptrarr(MaxSChannels)
      GridType = 0
      IrrGrid = replicate({IrrGridDescr, x: ptr_new(), y: ptr_new(), n: 0}, $
        MaxSChannels)

      ;Cteni topografickych dat
      if Par.TChannels GT 0 then if (Par.XPixels LE 0) or (Par.YPixels LE 0) then begin
        Err = 'No image dimension should be zero or negative'
        print, !ERROR_STATE.MSG_PREFIX + Err
        Par.TChannels = 0
      endif else begin
        m = 0
        max = (Par.TChannels < MaxTChannels) - 1
        for j = 0, max do begin
          file1 = directory + Par.Topography[m].FileName; jmeno topografickeho souboru
          if not keyword_set(file1) then ReadOK = 0 else begin
            ;Cteni topografickeho souboru
            ;print, 'Reading "' + file1 + '"...'
            img = LoadTopo(file1, Par.XPixels, Par.YPixels, OK = ReadOK)
	    
	    if not ReadOK then begin
	      ;Druhy pokus o cteni topografickeho souboru
	      ;Jmeno topografickeho souboru bude tentokrat odvozeno od jmena souboru parametrickeho
	      pp1 = strpos(file1, '.', /reverse_search); pozice pripony
	      if pp1 GE 0 then begin
	        pp = strpos(files[i], '.', /reverse_search)
	        if pp GE 0 then file2 = strmid(files[i], 0, pp) else file2 = files[i] 
		file2 = file2 + strmid(file1, pp1); pridani pripony
              endif
              img = LoadTopo(file2, Par.XPixels, Par.YPixels, OK = ReadOK)
	      if ReadOK then begin
	        if strpos(file2, directory) EQ 0 then file2 = strmid(file2, strlen(directory)); odstraneni cesty
	        Par.Topography[m].FileName = file2	      
	      endif  
	    endif
	    
            if not ReadOK then begin
              ;print, 'Reading topo file failed'
              Err = 'Reading image from "' + file1 + '" unsuccessful'
              print, Err
	      ;if interactive then void = dialog_message(Err, /error, dialog_parent = ParentID)
            endif else begin
              ;print, 'Reading topo file succeeded'
              Images[m] = ptr_new(img, /no_copy)
              m = m + 1
            endelse
          endelse
          if not ReadOK then begin
            if m NE max then Par.Topography[m:max] = shift(Par.Topography[m:max] , -1)
            Par.TChannels = (Par.TChannels < MaxTChannels) - 1
          endif
        endfor
      endelse


      ;Cteni spektroskopickych dat
      if not keyword_set(nospectra) then begin
      if Par.SChannels GT 0 then if NOT((Par.XPoints GT 0) and (Par.YPoints GT 0)) then begin
        Err = 'No dimension of spectral array should be zero or negative'
        print, !ERROR_STATE.MSG_PREFIX + Err
        Par.SChannels = 0
	
	
	
      endif else begin
        m = 0
        max = (Par.SChannels < MaxSChannels) - 1
        for j = 0, max do begin
          file1 = directory + Par.Spectroscopy[m].FileName; jmeno spektroskopickeho souboru
          points = Par.Spectroscopy[m].Points
          if points LE 0 then begin
            ReadOK = 0
            Err = 'Number of points per spectrum cannot be zero or negative'
            print, !ERROR_STATE.MSG_PREFIX + Err
          endif else if not keyword_set(file1) then ReadOK = 0 else begin
            ;Cteni spektroskopickeho souboru 
            ;print, 'Reading "' + file1 + '"...'
              
            if strpos(strlowcase(file1), '.cs') GE 0 then begin
              ;Spektroskopie na nepravidelne mrizce
              if (m GT 0) and (GridType NE 2) then GridType = 0 else GridType = 2
	      datacs = LoadCs(file1, npoints = points, OK = ReadOK)
	      
	      if not ReadOK then begin
	      print, 'another attempt to read it'
	        ;Druhy pokus o cteni spektroskopickeho souboru
	        ;Jmeno spektroskopickeho souboru bude tentokrat odvozeno od jmena souboru parametrickeho
	        pp1 = strpos(file1, '.', /reverse_search); pozice pripony
	        if pp1 GE 0 then begin
	          pp = strpos(files[i], '.', /reverse_search)
	          if pp GE 0 then file2 = strmid(files[i], 0, pp) else file2 = files[i] 
		  file2 = file2 + strmid(file1, pp1); pridani pripony
                endif
                datacs = LoadCs(file2, npoints = points, OK = ReadOK)
	        if ReadOK then begin
	          if strpos(file2, directory) EQ 0 then file2 = strmid(file2, strlen(directory)); odstraneni cesty
	          Par.Spectroscopy[m].FileName = file2	      
	        endif  
	      endif
	      
              if ReadOK then begin
                Spectra[m] = datacs.data
                IrrGrid[m].n = datacs.n 
                IrrGrid[m].x = datacs.x
                IrrGrid[m].y = datacs.y
		Xscl[m] = datacs.xscl
		;print,xscl(1,*)
		;help,datacs,/struct
		
              endif else if keyword_set(datacs) then begin
                ptr_free, datacs.data, datacs.x. datacs.y,datacs.xscl
	      endif
	    endif else begin
	      ;Spektroskopie na pravidelne mrizce
              if (m GT 0) and (GridType NE 1) then GridType = 0 else GridType = 1
              spc = LoadSpect(file1, Par.Xpoints, Par.YPoints, points, OK = ReadOK)

	      if not ReadOK then begin
	        ;Druhy pokus o cteni spektroskopickeho souboru
	        ;Jmeno spektroskopickeho souboru bude tentokrat odvozeno od jmena souboru parametrickeho
	        pp1 = strpos(file1, '.', /reverse_search); pozice pripony
	        if pp1 GE 0 then begin
	          pp = strpos(files[i], '.', /reverse_search)
	          if pp GE 0 then file2 = strmid(files[i], 0, pp) else file2 = files[i] 
		  file2 = file2 + strmid(file1, pp1); pridani pripony
                endif
                spc = LoadSpect(file2, Par.Xpoints, Par.YPoints, points, OK = ReadOK)
	        if ReadOK then begin
	          if strpos(file2, directory) EQ 0 then file2 = strmid(file2, strlen(directory)); odstraneni cesty
	          Par.Spectroscopy[m].FileName = file2	      
	        endif  
	      endif
	      
              if ReadOK then Spectra[m] = ptr_new(spc, /no_copy)
	    endelse
            
            if not ReadOK then begin
              print, 'Reading file failed'
              Err = 'Reading spectra from "' + file1 + '" unsuccessful'
              print, Err
	      ;if interactive then void = dialog_message(Err, /error, dialog_parent = ParentID)
            endif else begin
              ;print, 'Reading file succeeded'
              m = m + 1
            endelse

          endelse
          if not ReadOK then begin
            if m NE max then Par.Spectroscopy[m:max] = shift(Par.Spectroscopy[m:max] , -1)
            Par.SChannels = (Par.SChannels < MaxSChannels) - 1
          endif
        endfor
      endelse
      endif

      item = {STMDataStruct, Parameters: Par, ParFile: files[i], Dir: directory, $
        Images: Images, Spectra: Spectra, GridType: GridType, IrregularGrid: IrrGrid,xscl:xscl}
      if n EQ 0 then data = [item] else data = [data, item]
     ;print,n
     n = n + 1
    endelse
  endif
endfor

if n_elements(data) EQ 0 then begin
  print,'Everything empty'
  OK = 0
  return, 0
endif else begin
  ;print,'Something loaded'
  OK = 1
  return, data
endelse
end

function Autodir, filename                                                          
if size(h, /n_dimensions) EQ 0 then h = filename else h=filename[0]
case strupcase(!VERSION.OS_FAMILY) of
'UNIX': sep = '/'
'WINDOWS': sep = '\'
else: sep = ':'
endcase                                                                       
hpos = STRPOS(h, sep , /REVERSE_SEARCH)                                             
if hpos eq -1 then h='' else h=strmid(h,0,hpos+1)                                   
return,h
end                                                                           
