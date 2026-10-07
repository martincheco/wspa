function CW_Sliders, parent, mincolor = mincolor, maxcolor = maxcolor, minreal = minreal, maxreal = maxreal, $
    value1 = value1, value2 = value2, unit = unit, size = size, uname = uname, uvalue = uvalue

;Dvojice posuvnych list, ktere dovoluji uzivateli nastavit interval hodnot
;mincolor = index barvy odpovidajici nejnizsi nastavitelne hodnote
;maxcolor = index barvy odpovidajici nejvyssi nastavitelne hodnote
;minreal = nejnizsi nastavitelna hodnota zobrazovane veliciny
;maxreal = nejvyssi nastavitelna hodnota zobrazovane veliciny
;unit = oznaceni fyzikalni jednotky zobrazovane veliciny
;value1 = pocatecni nastaveni prveho slideru
;value2 = pocatecni nastaveni druheho slideru
;uname = jmeno widgetu
;size  = rozmer widgetu

;widget_control, get_value = interaktivne nastavena hodnota
;widget_control, set_value = programove nastaveni vlastnosti

;wiget_control, set_value = {minreal, maxreal, Type: "RealRangeSet"} or
;                           {mincolor, maxcolor, Type: "ColorRangeSet"} or
;                           {value1, value2, Type: "ActualValueSet"} or
;                           {color1, color2, Type: "ActualColorSet"}
;                           {unit, Type: "UnitNameSet"}

if not keyword_set(mincolor) then mincolor = 0
if not keyword_set(maxcolor) then maxcolor = !D.TABLE_SIZE - 1
if not keyword_set(minreal) then minreal = 0.0
if not keyword_set(maxreal) then maxreal = minreal + 1.0
if not keyword_set(value1) then value1 = minreal
if not keyword_set(value2) then value2 = maxreal
if not keyword_set(unit) then unit = ""

mini = 0
maxi = 255
i1 = (value1 - minreal) / (maxreal - minreal) * (maxi - mini) + mini
i2 = (value2 - minreal) / (maxreal - minreal) * (maxi - mini) + mini

base = widget_base(parent, /column, uname = uname, $
  pro_set_value = 'CWSliders_SetValue', func_get_value = 'CWSliders_GetValue', event_func = 'CWSliders_AtEvent')
base1 = widget_base(base, /row, frame = 0, xpad = 0, /base_align_center)
base2 = widget_base(base, /row, frame = 0, xpad = 0, /base_align_center)
slider1 = widget_slider(base1, /suppress_value, scroll = 1, /drag, $
   minimum = mini, maximum = maxi, value = i1, uname = 'Slider1')
slider2 = widget_slider(base2, /suppress_value, scroll = 1, /drag, $
   minimum = mini, maximum = maxi, value = i2, uname = 'Slider2')
colorbox1 = widget_draw(base1, /button_events, uname = 'ColorBox1')
colorbox2 = widget_draw(base2, /button_events, uname = 'ColorBox2')
numbox1 = widget_text(base1, /editable, frame = 1, xsize = 8, uname = 'NumBox1')
numbox2 = widget_text(base2, /editable, frame = 1, xsize = 8, uname = 'NumBox2')
unit1 = widget_label(base1, value = unit, uname = 'Unit1')
unit2 = widget_label(base2, value = unit, uname = 'Unit2')

height1 = (widget_info(slider1, /geometry)).scr_ysize
height2 = (widget_info(slider2, /geometry)).scr_ysize
widget_control, colorbox1, xsize = height1, ysize = height1, scr_xsize = height1, scr_ysize = height1
widget_control, colorbox2, xsize = height2, ysize = height2, scr_xsize = height2, scr_ysize = height2
if keyword_set(size) then begin
  offset = (widget_info(base, /geometry)).xpad
  space1 = (widget_info(base1, /geometry)).space
  space2 = (widget_info(base2, /geometry)).space
  cbsize1 = (widget_info(colorbox1, /geometry)).scr_xsize + 2 * (widget_info(colorbox1, /geometry)).margin
  cbsize2 = (widget_info(colorbox2, /geometry)).scr_xsize + 2 * (widget_info(colorbox2, /geometry)).margin
  nbsize1 = (widget_info(numbox1, /geometry)).scr_xsize + 2 * (widget_info(numbox1, /geometry)).margin
  nbsize2 = (widget_info(numbox2, /geometry)).scr_xsize + 2 * (widget_info(numbox2, /geometry)).margin 
  ulsize1 = (widget_info(unit1, /geometry)).scr_xsize + 2 * (widget_info(unit1, /geometry)).margin
  ulsize2 = (widget_info(unit2, /geometry)).scr_xsize + 2 * (widget_info(unit2, /geometry)).margin
  widget_control, slider1, xsize = (size - 2 * offset - cbsize1 - nbsize1 - ulsize1 - 3 * space1) > 100
  widget_control, slider2, xsize = (size - 2 * offset - cbsize2 - nbsize2 - ulsize2 - 3 * space2) > 100
endif
if keyword_set(uvalue) then widget_control, set_uvalue = uvalue
data = {minimum:mini, maximum:maxi, minreal:minreal, maxreal:maxreal, mincolor:mincolor, maxcolor:maxcolor, val1:i1, val2:i2}
widget_control, widget_info(base, /child), set_uvalue = data
return, base
end
