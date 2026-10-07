function Sorted, a, b
;Provede porovnani retezcu a vers. b tak, 
;aby bylo razeni spravne i pro retezce obsahujici cisla.
;Vraci:
; 1 pokud a < b nebo a = b
; 0 pokud a > b

if (a EQ '') or (b EQ '') then return, a LE b

na = strlen(a)
nb = strlen(b)
a_code = byte(a); ASCII kod retezce a
b_code = byte(b); ASCII kod retezce b
if na LT nb then a_code = [a_code, replicate(0B, nb - na)] $
else if na GT nb then b_code = [b_code, replicate(0B, na - nb)]
n = na > nb
a_ciph = (a_code GE (byte('0'))[0]) and (a_code LE (byte('9'))[0]) ;ktery znak retezce a je cifra?
b_ciph = (b_code GE (byte('0'))[0]) and (b_code LE (byte('9'))[0]) ;ktery znak retezce b je cifra?
a_pnt = (a_code EQ (byte('.'))[0]); ktery znak retezce a je tecka?
b_pnt = (b_code EQ (byte('.'))[0]); ktery znak retezce b je tecka?

;Definice poli a_pri, b_pri, odpovidajicich retezcum a, b:
;Na pozici, kde se v retezci obevuje prvni ze souvisle rady cifer (prvni cifra cisla),
;bude prislusny prvek pole roven poctu cifer v souvisle rade (v cisle),
;na vsech ostatnich pozicich (odpovidajicich textovym znakum nebo nasledujicim cifram cisla)
;jsou prvky pole nulove.
;Nulovy prvek pole je i na pozici prvni cifry, pokud tato nasleduje za teckou 
;(jako by se tecka povazovala za desetinnou)
a_pri = intarr(n)
b_pri = intarr(n)
ca = 0 & cb = 0; pocitadla cifer
for i = n - 1, 0, -1 do begin
  if a_ciph[i] then ca = ca + 1 else ca = 0
  if b_ciph[i] then cb = cb + 1 else cb = 0
  if i EQ 0 then begin
    a_pri[i] = ca
    b_pri[i] = cb
  endif else begin
    if not(a_ciph[i-1] or a_pnt[i-1]) then a_pri[i] = ca
    if not(b_ciph[i-1] or b_pnt[i-1]) then b_pri[i] = cb
  endelse
endfor

comp = 2; vysledek porovnani
;comp = 0: a > b
;comp = 1: a <= b
;comp = 2: nerozhodnuto (nebo a = b)
i = 0
while (comp EQ 2) and (i LT n) do begin
  if (a_pri[i] EQ 0) or (b_pri[i] EQ 0) or (a_pri[i] EQ b_pri[i])then begin
    ;standardni porovnani podle ASCII tabulky
    if a_code[i] EQ b_code[i] then comp = 2 $
    else if a_code[i] LT b_code[i] then comp = 1 $
    else comp = 0
  endif else begin
    if a_pri[i] LT b_pri[i] then comp = 1 else comp = 0
  endelse
  i = i + 1
endwhile
comp = comp < 1; osetreni pripadu a = b
return, comp
end


function omicron_sort,f ;1D string array with paths is sorted according to the omicron style numbers 
;bubble sort
print,'Sorting the files..'
nn=n_elements(f)

last_swap=0
    
    while last_swap eq 0 do begin
    last_swap=1
    for i=1,nn-1 do begin
    
    if not(Sorted(f(i), f(i-1)) eq 0) then begin
	ff = f(i-1)
	f(i-1) = f(i)
	f(i) = ff
	last_swap=0
	endif
    endfor	
;	print,last_swap
    endwhile

return,f
end