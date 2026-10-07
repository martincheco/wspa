pro IssueErr, text, NoMessage = NoMessage, Dialog = Dialog, WriteTo = WriteTo
;Procedura vypise chybove hlaseni, jeho text se zadava jako parametr procedury
;text = text chyboveho hlaseni
;/NoMessage = chybove hlaseni se nevypisuje do okna "Output Log"
;/Dialog = chybove hlaseni se objevi jako dialogove okno
;WriteTo = promenna, do ktere se pripise text chyboveho hlaseni
;(WriteText je retezcove pole, do ktereho se text hlaseni zapisuje jako dalsi prvek)

if not keyword_set(WriteTo) then WriteTo = [string(text)] $
else WriteTo = [WriteTo, string(text)]
if not keyword_set(NoMessage) then print, !ERROR_STATE.MSG_PREFIX + text
if keyword_set(Dialog) then void = dialog_message(text, /error)
end

