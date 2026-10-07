function BoxcarFilter, y, width = width, OK = OK, resize = resize
;metoda plovouciho prumeru (neboli okenkovy ci tez obdelnikovy filtr)
;y = puvodni data
;width = sirka filtru
;OK = indikator bezchybneho prubehu
;/resize = povoleno, aby filtrovane pole melo mensi rozmery nez puvodni
;print,'Using: BoxcarFilter.pro:b!"

OK = 1
if not keyword_set(y) then begin
  OK = 0
  return, 0
endif
if not keyword_set(width) then width = 3 else width = abs(fix(width))
rank = size(y, /n_dimensions)
case rank of
  0: return, float(y)
  1: begin
    n = n_elements(y)
    if (width GT n) then begin
      OK = 0
      print, 'WARNING: Filter width (',width,') should not exceed array size (',n,').'
      width = n
      if (not keyword_set(resize)) and ((width mod 2) EQ 0) then width = width - 1
      print, 'Filter width changed to ', width, '.'
      print
    endif
  end
  2: begin
    m = (size(y))[1]
    n = (size(y))[2]
    if (width GT m) or (width GT n) then begin
      OK = 0
      print, 'WARNING: Filter width (',width,') should not exceed either array dimensions.'
      width = m < n
      if (not keyword_set(resize)) and ((width mod 2) EQ 0) then width = width -1
      print, 'Filter width reduced to ', width, '.' 
      print
    endif
  end
  else: begin
    OK = 0
    message, 'Only 1 or 2-dimensional data allowed.', /continue
    return, y
  end
endcase

if (width EQ 1) then return, float(y)
if keyword_set(resize) then case rank of
  1: begin
    ker = replicate(1.0 / width, width)
    return, (convol(float(y), ker, center = 0))[width-1: *]
  end
  2: begin
    ker = replicate((1.0/width)^2, width, width)
    return, (convol(float(y), ker, center = 0))[width-1: *, width-1: *]
  end
endcase else begin
  if (width mod 2) EQ 0 then begin
    OK = 0
    print, 'WARNING: Filter width (',width,') should be an odd number unless "/resize" is set.'
    if ((width + 1) LE min((size(array))[1:rank])) then width = width + 1 else width = width - 1
    print, 'Filter width changed to ', width, '.'
    print
  endif
  return, smooth(float(y), width, /edge_truncate)
endelse
end
