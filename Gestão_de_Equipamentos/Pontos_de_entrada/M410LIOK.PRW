#INCLUDE "PROTHEUS.CH"

/*/
------------------------------------------------------------------------
{Protheus.doc} M410LIOK()
P.E NA VALIDAÇÃO DAS LINHAS DO PEDIDO DE VENDA
https://tdn.totvs.com/pages/releaseview.action?pageId=6784149

@author  DS2U (VR)
@since   dez.2023
@version 1.0
@type    function
------------------------------------------------------------------------
/*/
User Function M410LIOK()
    Local lRet := .T.

    lRet := u_OM30XPE('M410LIOK')

Return(lRet)
 