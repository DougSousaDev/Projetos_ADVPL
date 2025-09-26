#Include "Totvs.ch"
#Include "FWMVCDef.ch"

/* -----------------------------------------------------
{Protheus.doc} CTA100MNU()
PONTO DE ENTRADA PARA ADICIONAR OPCAO NO MENU DO BROWSE
https://tdn.totvs.com/pages/releaseview.action?pageId=6089605
@type user function
@author DN
@since 18/07/2025
@version version
------------------------------------------------------ */

User Function CTA100MNU()
    Local aArea     := GetArea()

    aAdd(aRotina, {"Equip. x Produto", "u_OM30A020()",  0, 4, 0, Nil} )    

    RestArea(aArea)
Return
