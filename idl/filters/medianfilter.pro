function MedianFilter, y, width = width, OK = OK, resize = resize
;medianovy filtr
;y = puvodni data
;width = sirka filtru
;OK = indikator bezchybneho prubehu
;/resize = povoleno, aby filtrovane pole melo mensi rozmery nez puvodni
;print,'Using: MedianFilter.pro'
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
if ((width mod 2) EQ 0) and (not keyword_set(resize)) then begin
  OK = 0
  print, 'WARNING: Filter width (',width,') should be an odd number unless "/resize" is set'
  if ((width + 1) LE min((size(array))[1:rank])) then width = width + 1 else width = width - 1
  print, 'Filter width changed to ', width, '.'
  print
endif

fy = median(y, width, /even)
if keyword_set(resize) then begin
  case rank of
    1: begin
      fy = fy[width/2: n-(width+1)/2]
      if (width mod 2) EQ 0 then begin
        fy[n-width] = median(y[n-width: n-1], /even)
      endif
      return, fy
    end
    2: begin
      fy = fy[width/2: m - (width+1)/2, width/2: n - (width+1)/2]
      if (width mod 2) EQ 0 then begin
        for i=0, m-width do fy[i, n-width] = $
          median(y[i: i+width-1, n-width: n-1], /even)
        for j=0, n-width-1 do fy[m-width, j] = $
          median(y[m-width: m-1, j: j+width-1], /even)
      endif
      return, fy
    end
  endcase
endif else begin
  case rank of
    1: begin
      for i = 0, width/2 - 1 do fy[i] = median(y[0: i+(width-1)/2], /even)
      for i = n-width/2, n-1 do fy[i] = median(y[i-width/2: n-1], /even)
      return, fy
    end
    2: begin
      for i = 0, m - 1 do for j = 0, width/2 - 1 do $
        fy[i,j] = median(y[(i-width/2) > 0: i+(width-1)/2 < (m-1), 0: j+(width-1)/2], /even)
      for i = 0, m - 1 do for j = n - width/2, n - 1 do $
        fy[i,j] = median(y[(i-width/2) > 0: i+(width-1)/2 < (m-1), j - width/2: n-1], /even)
      for i = 0, width/2 - 1 do for j = width/2, n - 1 - width/2 do $
        fy[i,j] = median(y[0: i+(width-1)/2, j-width/2: j+(width-1)/2], /even)
      for i = m - width/2, m - 1 do for j = width/2, n - 1 - width/2 do $
        fy[i,j] = median(y[i-width/2: m-1, j-width/2: j+(width-1)/2], /even)
      return, fy
    end
  endcase 
endelse
end
