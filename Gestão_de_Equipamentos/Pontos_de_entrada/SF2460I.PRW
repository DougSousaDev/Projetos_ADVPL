#INCLUDE "PROTHEUS.CH"

/* -----------------------------------------------------------------------------------------------------------------------------------------------------
{Protheus.doc} SF2460I()
ponto de entrada dentro da transação na gravação das tabelas do documento.
https://centraldeatendimento.totvs.com/hc/pt-br/articles/11814672801943-Cross-Segmento-TOTVS-Backoffice-Linha-Protheus-SIGAFAT-Ponto-de-Entrada-SF2460I
@type user function
@author [DN]
@since 24/07/2025
@version version
------------------------------------------------------------------------------------------------------------------------------------------------------- */

User Function SF2460I()
    Local lRet := .T.

    lRet := u_OM30XPE('SF2460I')

Return(lRet)
 