#Include "Totvs.ch"
/* ---------------------------------------------------------------
{Protheus.doc} MTA410IC()
P.E EXECUTADO APÓS A GRAVAÇÃO DAS INFORMAÇOES DO PEDIDO DE VENDA
https://tdn.totvs.com/display/public/PROT/MT410INC
@type user function
@author [DN]
@since 24/07/2025
@version version
---------------------------------------------------------------- */

User Function MTA410I()
    Local lRet := .T.

    lRet := u_OM30XPE('MTA410I')

Return(lRet)
 