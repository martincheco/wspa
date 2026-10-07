pro GoldPalette, r = r, g = g, b = b,pure=pure,iso=iso
;Nastavi "zlatocervenou" paletu
;r, g, b = vektorove promenne pro vystup nastavenych intenzit RGB (nemusi se vyuzit)
;pure je keyword, kterym se docili palety bez specialnich barev
if !D.NAME ne 'NULL' then device, decomposed = 0
;device, decomposed = 0
ll=intarr(85)*0
hl=intarr(85)+255
sl=indgen(85)*3
ssl=indgen(170)*3/2+1
r=[0,ssl,hl]
g=[0,ll,ssl]
b=[255,ll,ll,sl]
if keyword_set(pure) then b(0)=0
if keyword_set(iso) then $
begin
i=(256*indgen(25))/25+1
g(i)=0
g(i+1)=0
r(i)=0
r(i+1)=0
b(i)=255
b(i+1)=255
end
print,'Using: Goldpalette.pro'
tvlct,r,g,b
end
