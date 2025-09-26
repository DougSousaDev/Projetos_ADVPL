#Include "Totvs.ch"
/* ---------------------------------------------------
Nome: MT103FIM()
P.E APÓS A GRAVAÇÃO DO DOC. DE ENTRADA
https://tdn.totvs.com/pages/releaseview.action?pageId=6085406&showLanguage=all
@type user function
@author Douglas Sousa
@since 07/07/2025
@version version
---------------------------------------------------- */

User Function MT103FIM()
    Local lRet := .T.

    lRet := u_OM30XPE('MT103FIM')

Return(lRet)
