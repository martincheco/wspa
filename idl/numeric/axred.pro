function axred,ax,ounit,funit=funit
;if axis has some significant exponent, it is transformed into reasonable range, changing the unit
;careful!
;funit forces the final prefix

if not(keyword_set(ounit)) then return,ax
unit=ounit

mn=max(abs(ax))
;print,"Max:",mn
f=round(alog10(mn))

len=strlen(unit)
;prefix check, bracket removal
    brackets=0
    p=strpos(unit,"[")
    p1=strpos(unit,"]")
    if p ne -1 and p1 ne -1 then begin 
	unit=strmid(unit,p+1,p1-p-1)
	brackets=1
    end
    ;print,"Unit: ",unit
if unit ne "m" and unit ne "mol" and strlen(unit) ne 1 and unit ne "Hz" then begin
    prefix=strmid(unit,0,1)
    unit=strmid(unit,1)
end else prefix=""
;print,"Prefix: ",prefix
;print,"Suffix: ",unit

case prefix of

"m":e=-3
"u":e=-6
"n":e=-9
"p":e=-12
"f":e=-15
"a":e=-18
"":e=0
"k":e=3
"M":e=9
"G":e=12
"T":e=15
"P":e=18
"E":e=18

else : return,ax

endcase
print,"Exponent of number",f
print,"Exponent of unit",e

te=round(e+f)
print,"Total exponent: ",te

pe=0
if te gt 0 then pe=(ceil(te/3))*3 
if te lt 0 then pe=-(ceil(abs(te)+1)/3)*3
;print,"Rounded exp: ",pe

;if e ge 0 then pe=e

if keyword_set(funit) then begin

    len=strlen(funit)
    ;prefix check, bracket removal
    brackets=0
    p=strpos(funit,"[")
    p1=strpos(funit,"]")
    if p ne -1 and p1 ne -1 then begin 
	funit=strmid(funit,p+1,p1-p-1)
	brackets=1
    end
    ;print,"Final Unit Forced: ",funit
    if funit ne "m" and funit ne "mol" and strlen(funit) ne 1 and funit ne "Hz" then begin
    fprefix=strmid(funit,0,1)
    funit=strmid(funit,1)

end else fprefix=""

    case fprefix of
	"m":pe=-3
	"u":pe=-6
	"n":pe=-9
	"p":pe=-12
	"f":pe=-15
	"a":pe=-18
	"":pe=0
	"k":pe=3
	"M":pe=9
	"G":pe=12
	"T":pe=15
	"P":pe=18
	"E":pe=18
	else: pe=0
    endcase
end

case pe of 
0: prefix=""

3: prefix="k"
6: prefix="M"
9: prefix="G"
12: prefix="T"
15: prefix="P"
18: prefix="e"

-3: prefix="m"
-6: prefix="u"
-9: prefix="n"
-12: prefix="p"
-15: prefix="f"
-18: prefix="a"

else : return,ax

endcase
;print,"New prefix: ",prefix

;print,e,pe,prefix,unit
ounit=prefix+unit

if brackets eq 1 then ounit="["+ounit+"]"

;print,"Final unit: ",ounit
axn=double(ax)*(10D^(e-pe))


return,axn
end
