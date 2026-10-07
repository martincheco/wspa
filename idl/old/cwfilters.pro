;Dialogove okno pro volbu filtru jako compound-widget

pro CWfilters_AnalyzeHeader, header, name = name, paramnames = paramnames, paramtypes = paramtypes, $
  nparams = nparams
;Procedura analyzuje hlavicku filtru (hlavicky jednotlivych filtru
;jsou prislusne polozky promenne FilterTypes) a vraci ziskanou
;informaci o filtru v pojmenovanych parametrech
;header = hlavicka
;name = jmeno filtru
;paramnames = nazvy parametru
;paramtypes = pismenove kody, udavajici typ parametru
;nparams = pocet parametru

leftparen = strpos(header, '(' ); left parenthesis position
if leftbrace LT 0 then begin
  name = strtrim(header, 2)
  nparams = 0
  paramnames = ''
  paramtypes = ''
endif else begin
  name = strmid(header,0,leftparen-1)
  name = strtrim(name, 2)
  nparams = 0
  pos = leftbrace + 1
  rightbrace = strpos(header, ')' ,pos); right parenthesis position
  if rightbrace LT 0 then rightbrace = strlen(header) - 1; no right parenthesis
  while pos LT rightbrace do begin ;until right parenthesis reached
    comma = strpos(header, ',', pos); next comma position
    if comma LT 0 then comma = rightbrace; no comma before the end
    semicol = strpos(header, ';', pos); next semicolon position
    if semicol LT 0 then semicol = rightbrace ; no semicolon before the end
    delimiter = comma < semicolon; next delimiter
    arg = strmid(header, pos, delimiter-pos-1)
    arg = strtrim(arg, 2)
    pos = delimiter + 1
    if arg NE '' then begin; another argument
      colon = strpos(arg, ':'); colon position
      if colon LT 0 then begin
        paramname = arg
        paramtype = ''
      endif else begin
        argname = strmid(arg, 0, colon)
        argtype = strmid(arg, colon)
        argname = strtrim(argname, 2)
        argtype = strtrim(argtype, 2)
      endelse
      if nparams EQ 0 then begin
        paramnames = [argname]
        paramtypes = [argtype]
      endif else begin
        paremnames = [paramnames, argname]
        paramtypes = [paramtypes, argtype]  
      endelse
      nparams = nparams + 1
    end
  endwhile
endelse  
end


function CWfilters, top, event_pro = event_pro
;Vytvarejici funkce widgetu
;Pozn.: Tento compound widget predstavuje samostatne okenko v operacnim systemu. Proto neni formalne potomkem 
;  zadneho jineho widgetu. Informaci o svem "nadrizenem" si tento CW uchovava ve sve uzivatelske promenne
;  jako polozku uvalue.top, pri generovani udalosti je vsak ev.top nastaveno na ID tohoto compound widgetu 
;  a ne na ID "nadrizeneho".
;top = ID nadrizeneho widgetu (mel by to byt vrcholovy widget materske aplikace)
;event_pro = procedura pro osetreni udalost

FilterTypes = ["Boxcar Smooth(width:I)", $
               "Binomial Smooth(width:I)", $
               "Polynomial Smooth(width:I,order:I)", $
               "Raw Derivative()", $
               "Polynomial Derivative(width:I,order:I)", $
               "Higher Order Pol. Deriv. (width:I,pol.order:I,der.order:I)" ]

widget_control, top, get_uvalue = descr
if keyword_set(descr) then FilterList = descr.FilterList else FilterList = ptr_new()

CWdescr = {top: top, FilterTypes: FilterTypes, FilterList: FilterList}

title = "Select or edit filter(s) for spectroscopy"
dialog = widget_base(event_pro = event_pro, group_leader = top, /column, title = title, uvalue = CWdescr)
menus = widget_base(dialog, /row)
left = widget_base(menus, /column, frame = 0)
right = widget_base(menus, /column, frame = 0)
add = widget_button(left, /menu, uname = 'AddMenu', event_pro = 'CWfilters_AddFilter')
remove = widget_button(left, /menu, uname = 'RemoveMenu', eveent_pro = 'CWfilters_RemoveFilter')
label = widget_label(right, vale = 'Edit filter:')
list = widget_list(right, ysize = 4, uname = 'List')

param1 = widget_base(dialog, /row, uname = 'Parameter1', visible = 0)
label1 = widget_label(param1, value = "Parameter 1:", /dynamic_resize, uname = 'Label1')
dialog1 = widget_text(param1, xsize = 6, ysize = 1, /editable, uname = 'Value1')
param2 = widget_base(dialog, /row, uname = 'Parameter1', visible = 0)
label2 = widget_label(param2, value = "Parameter 2:", /dynamic_resize, uname = 'Label2')
dialog2 = widget_text(param2, xsize = 6, ysize = 1, /editable, uname = 'Value2')

bb = widget_base(dialog, /row, frame = 0)
apply = widget_button(bb, value = "Apply", event_pro = 'CWfilters_Apply')
ok = widget_button(bb, value = "OK", event_pro = 'CWfilters_OK')
cancel = widget_button(bb, value = "Cancel", event_pro = 'CWfilters_Cancel')
return, base
end
