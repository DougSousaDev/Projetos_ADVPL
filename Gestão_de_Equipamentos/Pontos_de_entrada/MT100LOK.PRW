#Include "Totvs.ch"
/* -----------------------------------------------------------
{Protheus.doc} MT100LOK()
P.E NA ALTERAÇÃO DE ITENS DA NF DE ENTRADA
https://tdn.totvs.com/pages/releaseview.action?pageId=6085397
@type user function
@author [DN]
@since 24/07/2025
@version version
----------------------------------------------------------- */

User Function MT100LOK()
    Local lRet := .T.

    lRet := u_OM30XPE('MT100LOK')

Return(lRet)
 