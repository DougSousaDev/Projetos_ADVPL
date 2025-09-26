#Include "Totvs.ch"
#Include "FWMVCDef.ch"

/*/
---------------------------------------------------------------------------
{Protheus.doc} FA750BRW
ADIÇÃO DE ITENS NO MENU DA ROTINA CONTAS A PAGAR
https://tdn.totvs.com.br/pages/releaseview.action?pageId=901940855
@author  DS2U (DN)
@since   AGO.2025
@version 1.0
@type    function
---------------------------------------------------------------------------
/*/
User Function FA750BRW()
    Local aButtons  := {}
    Local aButFat   := {}

    aButtons := { {'Gerar Fatura', {|| grvFatur()}, 0 , 3},;
                  {'Consultar Titulos', {|| consTit()}, 0 , 3} }   

    AADD(aButFat,{ "Cartao de Credito", aButtons, 0 , 9})

Return(aButFat)
 
/*/
---------------------------------------------------------------------------
{Protheus.doc} grvFatur
ADICIONA BOTÃO PARA GRAVAÇÃO DA FATURA REF AOS TITULOS SELECIONADOS
@author  DS2U (DN)
@since   AGO.2025
@version 1.0
@type    function
---------------------------------------------------------------------------
/*/
Static Function grvFatur()
    aButtons := { {.F., NIL}, {.F., NIL}, {.F., NIL}, {.F., NIL}, {.F., NIL}, {.F., NIL},;
                            {.T., 'Salvar'}, {.T., 'Cancelar'}, {.F., NIL}, {.F., NIL},; 
                            {.F., NIL}, {.F., NIL}, {.F., NIL}, {.F., NIL}}

    FWExecView('Titulos em Aberto', 'VIEWDEF.OM30A030', MODEL_OPERATION_UPDATE,,,, 60, aButtons)

Return

/*/
---------------------------------------------------------------------------
{Protheus.doc} consTit
CONSULTA OS TITULOS BAIXADOS REF. A FATURA POSICIONADA
@author  DS2U (DN)
@since   AGO.2025
@version 1.0
@type    function
---------------------------------------------------------------------------
/*/
Static Function consTit()
    aButtons := { {.F., NIL}, {.F., NIL}, {.F., NIL}, {.F., NIL}, {.F., NIL}, {.F., NIL},;
                            {.F., NIL}, {.T., 'Sair'}, {.F., NIL}, {.F., NIL},; 
                            {.F., NIL}, {.F., NIL}, {.F., NIL}, {.F., NIL}}

    FWExecView('Titulos x Fatura', 'VIEWDEF.OM30A031', MODEL_OPERATION_UPDATE,,,, 60, aButtons)

Return
