pro ClearCs, cs
;Dealokuje dynamicke polozky v datove strukture typu CsStruct
;Struktua CsStruct slouzi k ulozeni spekter merenych na nepravidelne mrizce.
;csdata = datova struktura typu CsStruct

if not keyword_set(cs) then return
void = where(tag_names(cs) EQ strupcase('x'), XPresent)
void = where(tag_names(cs) EQ strupcase('y'), YPresent)
void = where(tag_names(cs) EQ strupcase('data'), DataPresent)
if XPresent then ptr_free, cs.x
if YPresent then ptr_free, cs.y
if DataPresent then ptr_free, cs.data
end
