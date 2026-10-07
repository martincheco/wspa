function BinomFilter, y, width = width, OK = OK, resize = resize
;y = puvodni data
;width = sirka filtru
;OK = indikator bezchybneho prubehu
;/resize = povoleno, aby filtrovane pole melo mensi rozmery nez puvodni

OK = 1
if not keyword_set(y) then begin
  OK = 0
  return, 0
endif
if not keyword_set(width) then width = 3 else width = abs(fix(width))
if (width mod 2 EQ 0) and (not keyword_set(resize)) then begin
  message, 'Filter width must be an odd number unless "/resize" is set', /continue
  OK = 0
  return, y
endif

rank = size(y, /n_dimensions)
if ((width mod 2) EQ 0) and (not keyword_set(resize)) then begin
  OK = 0
  print, 'WARNING: Filter width (',width,') should be an odd number unless "/resize" is set.'
  if ((width + 1) LE min((size(array))[1:rank])) then width = width + 1 else width = width - 1
  print, 'Filter width changed to ', width, '.'
  print
endif

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

    ;generovani binomialni masky
    ker = fltarr(width)
    ker[0] = 1
    for i = 2, width do ker = (ker + shift(ker, 1)) / 2

    ;konvoluce dat a masky
    if keyword_set(resize) then begin
      return, (convol(float(y), ker, center = 0))[width-1: *]
    endif else begin
      return, convol(float(y), ker, /edge_truncate)
    endelse
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

    ;generovani binomialni masky
    ker = fltarr(width, width)
    ker[0] = 1
    for i = 2, width do $
      ker = (ker + shift(ker, 1, 0) + shift(ker, 0, 1) + shift(ker, 1, 1)) / 4

    ;konvoluce dat a masky
    if keyword_set(resize) then begin
      return, (convol(float(y), ker, center = 0))[width-1: *, width-1: *]
    endif else begin
      return, convol(float(y), ker, /edge_truncate)
    endelse
  end
  else: begin
    message, 'Only 1 and 2-dimensional data allowed.', /continue
    OK = 0
    return, y
  end
endcase
end
