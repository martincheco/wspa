pro ClearSTM, data
;Procedura slouzi k uvolneni dynamicky alokovane pameti, vyuzivane pro data z mereni STM
;data = promenna typu STMDataStruct (nebo pole techto promennych)

;Tato procedura by mela byt volana vzdy predtim, 
;nez je promenna "data" zrusena nebo prepsana!

if not keyword_set(data) then return
void = where(tag_names(data) EQ strupcase('Images'), ImagesPresent)
void = where(tag_names(data) EQ strupcase('Spectra'), SpectraPresent)
void = where(tag_names(data) EQ strupcase('IrregularGrid'), IrrGridPresent)
if ImagesPresent then ptr_free, data.Images
if SpectraPresent then ptr_free, data.Spectra
if IrrGridPresent then begin
 ptr_free, data.IrregularGrid.x
 ptr_free, data.IrregularGrid.y
endif
end
