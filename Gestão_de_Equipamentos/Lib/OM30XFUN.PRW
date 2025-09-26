#INCLUDE 'TOTVS.CH'
#INCLUDE 'FWMVCDEF.CH'

/*/
---------------------------------------------------------------------------
{Protheus.doc} OM30XFUN()
BIBLIOTECA DE FUNCOES GENERICAS

@author  DS2U (DN)
@since   jun.2025
@version 1.0
@type    function
---------------------------------------------------------------------------
/*/
User Function OM30XFUN(cFunction, uParams)
    Local uRet := NIL

    If AllTrim(Upper(cFunction)) == 'CHECKPATRIM'
        // ---------------------------------------------
        // VALIDA CODIGO DO PATRIMONIO
        // ---------------------------------------------
        uRet := CHKPATR(uParams)

    ElseIf AllTrim(Upper(cFunction)) == 'VLDQTDPATR'
        // ---------------------------------------------
        // VALIDA QUANTIDADE DO PATRIMONIO
        // ---------------------------------------------
        uRet := VLDQTDPATR(uParams)

    ElseIf AllTrim(Upper(cFunction)) == 'VLDCONTR'
        // ---------------------------------------------
        // VALIDA CONTRATO X EQUIPAMENTO
        // ---------------------------------------------
        uRet := VLDCONTR(uParams)

    ElseIf AllTrim(Upper(cFunction)) == 'VLDPLANI'
        // ---------------------------------------------
        // VALIDA PLANILHA X CONTRATO
        // ---------------------------------------------
        uRet := VLDPLANI(uParams)

    ElseIf AllTrim(Upper(cFunction)) == 'FILTCONS'
        // ---------------------------------------------
        // FILTRO PARA CONSULTA PADRÃO
        // ---------------------------------------------
        uRet := FILTCONS()

    EndIf

Return(uRet)

/* ---------------------------------------------------
Nome: CHKPATR.PRW
FUNCAO PARA CHECAR PATRIMONIO
@type user function
@author Douglas Sousa
@since 07/07/2025
@version version
---------------------------------------------------- */

Static Function CHKPATR(aParams)
    Local aArea     := GetArea()
    Local lRet      := .T.
    Local cAliasQry := ''
    Local cCondicao := ""
    Local cPatrim   := ""
    Local cContra   := ""
    Local nQtd      := 0

    Default aParams := {}
    Default cTipo   := ''

    cPatrim     := aParams[1]
    cContra     := aParams[2]
    nQtd        := aParams[3]
    cProduto    := aParams[4]


    If !Empty(cPatrim)

        //--DOCUMENTO DE ENTRADA
        If FwIsInCallStack('MATA103')
            If cTipo == 'N' //-- NORMAL
                cCondicao := "%SZ0.Z0_CODPATR = '" +cPatrim+"'%"

            ElseIf cTipo == 'D' //--DEVOLUÇAO
                cCondicao := "%SZ0.Z0_CODPATR = '" +cPatrim+"'"
                cCondicao += " AND SZ0.Z0_CONTR = '"+cContra+"'"
                cCondicao += " AND SZ0.Z0_CODPRO = '"+cProduto+"'"
                cCondicao += " AND SZ0.Z0_STATUS = '2'%"
                
            Endif
        EndIf

        //--PEDIDO DE VENDA
        If FwIsInCallStack('MATA410')
            cCondicao := "%SZ0.Z0_CODPATR = '" +cPatrim+"'"
            cCondicao += " AND SZ0.Z0_CODPRO = '"+cProduto+"'"
            cCondicao += " AND SZ0.Z0_CONTR = ' '"
            cCondicao += " AND SZ0.Z0_STATUS = '1'%"
        EndIf

        //-- OBTEM OS PATRIMONIOS CADASTRADOS NA SZ0
        cAliasQry := GetNextAlias()
        BeginSQL Alias cAliasQry
          SELECT SZ0.Z0_CODPATR
            FROM %Table:SZ0% SZ0
           WHERE SZ0.Z0_FILIAL = %xFilial:SZ0%
             AND %Exp:cCondicao%
             AND SZ0.%NotDEL%
        EndSQL

        //--SE NAO ENCONTRAR DADOS E FOR PEDIDO DE VENDA
        If (cAliasQry)->(Eof()) .and. FwIsInCallStack('MATA410')
            MsgInfo('Patrimônio informado não está disponivel, verifique os dados e tente novamente!', 'Atenção!')
            lRet := .F.

        //--SE FOR DOC DE SAIDA A VARIAVEL 'CTIPO' NAO SERÁ NIL
        ElseIf !(cAliasQry)->(Eof()) .and. cTipo == 'N'
            MsgInfo('Não é possivel incluir um código de patrimônio que já exista na base! Para NF de compra informe um novo código.', 'Atenção!')
            lRet := .F.

        ElseIf (cAliasQry)->(EoF()) .and. cTipo == 'D'
            MsgInfo('Patrimônio indisponível, verifique os dados e tente novamente!' + CRLF + 'Para Incluir um novo, por favor altere o tipo da nota para "Normal".')
            lRet := .F.

        ElseIf Empty(cContra) .and. cTipo == 'D'
            MsgInfo('Informe o numero de contrato para o patrimonio!' + CRLF + 'Para Incluir um novo, por favor altere o tipo da nota para "Normal".')
            lRet := .F.

        EndIf

        (cAliasQry)->(dbCloseArea())

        //--VALIDA QUANTIDADE SE O CAMPO PATRIMONIO NAO FOR VAZIO
        If nQtd > 1
            MsgInfo('Quantidade do Patrimonio deve ser igual a "1", Informe uma quantidade por código de patrimonio!', 'Atenção')
            lRet := .F.
        EndIf

    EndIf

    RestArea(aArea)

Return(lRet)

/* ---------------------------------------------------
Nome: VLDQTDPATR.PRW
FUNCAO PARA VALIDAR QUANTIDADE DO PATRIMONIO
@type user function
@author Douglas Sousa
@since 08/07/2025
@version version
---------------------------------------------------- */

Static Function VLDQTDPATR(aParams)
    Local aArea     := GetArea()
    Local lRet      := .T.
    Local cPatrim   := ''
    Local nQuant    := 0

    Default aParams := {}

    cPatrim := aParams[1]
    nQuant  := aParams[2]

    If !Empty(cPatrim) .And. nQuant <> 1

        MsgInfo('Quantidade do Patrimonio deve ser igual a "1", Informe uma quantidade por código de patrimonio!', 'Atenção')
        lRet := .F.

    EndIf

    RestArea(aArea)
Return(lRet)

/* ---------------------------------------------------
Nome: VLDCONTR
FUNCAO PARA VALIDAR CONTRATO X EQIPAMENTO
@type user function
@author Douglas Sousa
@since 23/07/2025
@version version
---------------------------------------------------- */

Static Function VLDCONTR(aParams)
    Local aArea      := GetArea()
    Local lRet       := .T.
    Local cAliasQry  := ''
    Local cField     := ''
    Local cProduto   := ''
    Local cContrat   := ''

    Default aParams := {}

    If !Empty(aParams)
        cField   := aParams[1]
        cContrat := aParams[2]
        cProduto := aParams[3]

        cAliasQry := GetNextAlias()
        BeginSQL Alias cAliasQry
        SELECT SZ3.*
          FROM %Table:SZ3% SZ3
         WHERE SZ3.Z3_FILIAL = %xFilial:SZ3%
           AND SZ3.Z3_PRODUTO = %Exp:cProduto% 
           AND SZ3.Z3_CONTRAT = %Exp:cContrat%
           AND SZ3.%NotDel%
        EndSQL

        If (cAliasQry)->(Eof())

            If cField == 'C6_CONTRA'
                MsgInfo('Não existe contrato para o Produto informado código: ' + cProduto ,  'Atenção')
                lRet := .F.

            EndIf

        EndIf

    EndIf

    RestArea(aArea)

Return(lRet)

/* ---------------------------------------------------
Nome: VLDPLANI()
FUNÇAO PARA VALIDAR NUMERO DA PLANILHA
@type user function
@author Douglas Sousa
@since 30/07/2025
@version version
---------------------------------------------------- */

Static Function VLDPLANI(aParams)
    Local aArea     := GetArea()
    Local lRet      := .T.
    Local cAliasQry := ''
    Local cField    := ''
    Local cContr    := ''
    Local cPlani    := ''

    Default aParams := {}

    If !Empty(aParams)

        cField := aParams[1]
        cContr := aParams[2]
        cPlani := aParams[3]

        cAliasQry := GetNextAlias()
        BeginSQL Alias cAliasQry
        SELECT SZ3.*
          FROM %Table:SZ3% SZ3
         WHERE SZ3.Z3_FILIAL = %xFilial:SZ3%
           AND SZ3.Z3_CONTRAT = %Exp:cContr%
           AND SZ3.Z3_PLANI = %Exp:cPlani%
           AND SZ3.%NotDel%
        EndSQL

        If (cAliasQry)->(Eof()) 

            If cField == 'C6_PLANI'
                MsgInfo('Não existe planilha para o contrato informado, código: ' + cContr ,  'Atenção')
                lRet := .F.
            EndIf

        EndIf

    EndIf

    RestArea(aArea)
Return(lRet)

/* ---------------------------------------------------
Nome: FILTCONS()
FUNÇAO SQL PARA FILTRO DE CONSULTA PADRAO
@type user function
@author Douglas Sousa
@since 30/07/2025
@version version
---------------------------------------------------- */

Static Function FILTCONS()
    Local aArea     := GetArea()
    Local aAreaSC5  := SC5->(GetArea())
    Local aAreaSC6  := SC6->(GetArea())
    Local cSQL      := ''
    Local cProduto  := ''
    Local cCliente  := ''
    Local cLojaCli  := ''

    cProduto := GdFieldGet('C6_PRODUTO')
    cCliente := M->C5_CLIENTE
    cLojaCli := M->C5_LOJACLI

    cSQL := "@Z3_PRODUTO = '"+cProduto+"'"
    cSQL += " AND Z3_CLIENTE = '"+cCliente+"'"
    cSQL += " AND Z3_LOJA = '"+cLojaCli+"'""


    RestArea(aAreaSC6)
    RestArea(aAreaSC5)
    RestArea(aArea)

Return(cSQL)
