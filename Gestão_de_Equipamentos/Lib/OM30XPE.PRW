#INCLUDE 'TOTVS.CH'
#INCLUDE 'FWMVCDEF.CH'

/*/
---------------------------------------------------------------------------
{Protheus.doc} OM30XPE.PRW
FUNCOES UTILIZADAS EM PONTOS DE ENTRADA

@author  DS2U (DN)
@since   JULHO.2025
@version 1.0
@type    function
---------------------------------------------------------------------------
/*/
User Function OM30XPE(cPonto, uParams)
    Local uRet := NIL

    If AllTrim(Upper(cPonto)) == 'M410LIOK'
        // ---------------------------------------------
        // FUNCAO PARA TRATAR PROCESSOS DO PE M410LIOK
        // ---------------------------------------------
        uRet := M410LIOK()
    
    ElseIf AllTrim(Upper(cPonto)) == 'MT100LOK'
        // ---------------------------------------------
        // FUNCAO PARA TRATAR PROCESSOS DO PE MT100LOK
        // ---------------------------------------------
        uRet := MT100LOK()

    ElseIf AllTrim(Upper(cPonto)) == 'MT103FIM'
        // ---------------------------------------------
        // FUNCAO PARA TRATAR PROCESSOS DO PE MT103FIM
        // ---------------------------------------------
        uRet := MT103FIM()

    ElseIf AllTrim(Upper(cPonto)) == 'MTA410I'
        // ---------------------------------------------
        // FUNCAO PARA TRATAR PROCESSOS DO PE MTA410I
        // ---------------------------------------------
        uRet := MTA410I()

    ElseIf AllTrim(Upper(cPonto)) == 'SF2460I'
        // ---------------------------------------------
        // FUNCAO PARA TRATAR PROCESSOS DO PE SF2460I
        // ---------------------------------------------
        uRet := SF2460I()

    EndIf

Return(uRet)


/* ----------------------------------------------------------
{Protheus.doc} M410LIOK()
P.E NA VALIDAÇÃO DAS LINHAS DO PEDIDO DE VENDA
https://tdn.totvs.com/pages/releaseview.action?pageId=6784149
@type user function
@author [DN]
@since 24/07/2025
@version version
----------------------------------------------------------- */
Static aQtdOri := {}

Static Function M410LIOK()
    Local aArea     := GetArea()
    Local lRet      := .T.
    Local aDados    := {}
    Local aQtd      := {}
    Local nPosPatr  := 0
    Local nLine     := 0
    Local nPosQtd   := 0
    Local nPosItem  := 0
    Local nPosPrd   := 0
    Local nPosContr := 0
    Local nPosRevis := 0
    Local nPosPlani := 0
    Local nQuant    := 0
    Local nTotal    := 0
    Local nQtdDisp  := 0
    Local nQtdOri   := 0
    Local cItem     := ''
    Local cProduto  := ''
    Local cContrat  := ''
    Local cRevis    := ''
    Local cPlani    := ''
    Local cPatrim   := ''
    Local cNumPed   := ''


    //--LOCALIZA A POSIÇÃO DA COLUNA
    nPosItem  := aScan(aHeader, {|x| AllTrim(x[2]) == "C6_ITEM"    })
    nPosPrd   := aScan(aHeader, {|x| AllTrim(x[2]) == "C6_PRODUTO" })
    nPosContr := aScan(aHeader, {|x| AllTrim(x[2]) == "C6_CONTRA"  })
    nPosRevis := aScan(aHeader, {|x| AllTrim(x[2]) == "C6_REVISA"  })
    nPosPlani := aScan(aHeader, {|x| AllTrim(x[2]) == "C6_PLANI"   })
    nPosQtd   := aScan(aHeader, {|x| AllTrim(x[2]) == "C6_QTDVEN"  })
    nPosPatr  := aScan(aHeader, {|x| AllTrim(x[2]) == "C6_PATRIM"  })


    //--CARREGA QUANTIDADE ORIGINAL SOMENTE UMA VEZ
    If Empty(aQtdOri)
        cNumPed := SC6->C6_NUM

        If !Empty(cNumPed)
            aQtdOri := LoadData(cNumPed)
        Else
            aQtdOri := {} //--NA INCLUSAO GARANTE QTD 0
        EndIf

    EndIf

    For nLine := 1 To Len(aCols)
        //--VERIFICA SE A LINHA ESTÁ DELETADA
        If !LinDelet(aCols[nLine])

            //--PEGA O VALOR ATUAL DA LINHA E COLUNA
            cPatrim  := aCols[nLine][nPosPatr]
            cItem    := aCols[nLine][nPosItem]
            cProduto := aCols[nLine][nPosPrd]
            cContrat := aCols[nLine][nPosContr]
            cRevis   := aCols[nLine][nPosRevis]
            cPlani   := aCols[nLine][nPosPlani]
            nQuant   := aCols[nLine][nPosQtd]

            //-- PEGA O PRODUTO CONFORME AS LINHAS DA GRID
            cAliasQry := GetNextAlias()
            BeginSQL Alias cAliasQry
            SELECT SZ3.*, CN9.CN9_SITUAC
              FROM %Table:SZ3% SZ3

              JOIN %Table:CN9% CN9
                ON CN9.CN9_FILIAL = %xFilial:CN9%
               AND CN9.CN9_NUMERO = %Exp:cContrat%
               AND CN9.CN9_REVISA = %Exp:cRevis%
               AND CN9.%NotDel%

             WHERE SZ3.Z3_FILIAL = %xFilial:SZ3%
               AND SZ3.Z3_PRODUTO = %Exp:cProduto%
               AND SZ3.Z3_CONTRAT = %Exp:cContrat%
               AND SZ3.Z3_REVISA = %Exp:cRevis%
               AND SZ3.Z3_PLANI = %Exp:cPlani%
               AND SZ3.%NotDel%
            EndSql

            If !Empty(cPatrim)

                //--VERIFICA SE O VALOR JA EXISTE NO ARRAY 'aDados'
                If aScan(aDados, {|x| x == cPatrim}) > 0
                    Alert("O Código de patrimônio da linha " + cValToChar(nLine) + " já está sendo utilizado em outra linha.")
                    lRet := .F.
                    Exit
                EndIf

                //-- SE NÃO FOI ENCONTRADO ADICIONA AO ARRAY DE CONTROLE
                aAdd(aDados, cPatrim)
            EndIf

            If !Empty(cContrat) .and. !Empty(cPlani) .and. !Empty(nQuant)

                //-- OBTÉM QUANTIDADE ORIGINAL
                nQtdOri := GetQtdOri(aQtdOri, cItem, cProduto, cContrat, cPlani)
                
                If Empty(aQtdOri)
                    nQtdUpd := nQuant
                Else
                    nQtdUpd := nQuant - nQtdOri
                EndIf

                If nQtdUpd <> 0
                    //-- ATUALIZA OU INSERE O VALOR NO ARRAY DE CONTROLE
                    UpdateQtd(@aQtd, cProduto, cContrat, cPlani, nQtdUpd)

                EndIf

                //-- RECUPERA TOTAL ACUMULADO DO PRODUTO POSICIONADO
                nTotal := GetQtdTot(aQtd, cProduto, cContrat, cPlani)

                If !(cAliasQry)->(Eof())
                    nQtdDisp := ((cAliasQry)->Z3_QUANT - (cAliasQry)->Z3_QTDALC)

                    dbSelectArea('SZ3')
                    SZ3->(dbSetOrder(2))
                    If SZ3->(dbSeek(xFilial('SZ3')+cContrat+cRevis+cPlani+cProduto))

                        If nTotal > nQtdDisp
                            MsgInfo('O saldo do equipamento no contrato é insuficiente!', 'Atenção!')
                            lRet := .F.
                            Exit
                        EndIf

                    EndIf

                    dbSelectArea('CN9')
                    CN9->(dbSetOrder(1))
                    If CN9->(dbSeek(xFilial('CN9')+cContrat+cRevis))

                        If AllTrim((cAliasQry)->CN9_SITUAC) <> '05'
                            MsgInfo('Contrato não disponível, verifique a situação atual!', 'Atenção')
                            lRet := .F.
                            Exit
                        EndIf

                    EndIf

                EndIf

            EndIf

        EndIf

    Next nLine

    RestArea(aArea)
Return(lRet)

/* ---------------------------------------------------
{Protheus.doc} LoadData()
FUNÇAO PARA CARREGAR OS DADOS ORIGINAIS DO PEDIDO

@type user function
@author [DN]
@since 28/07/2025
@version version
---------------------------------------------------- */

Static Function LoadData(cNumPed)
    Local aRet := {}

    dbSelectArea('SC6')
    SC6->(dbSetOrder(1)) // C6_FILIAL+C6_NUM+C6_ITEM
    SC6->(dbSeek(xFilial("SC6") + cNumPed))

    While !SC6->(Eof()) .And. SC6->C6_NUM == cNumPed
        aAdd(aRet,;
            { SC6->C6_ITEM,;
              SC6->C6_PRODUTO,;
              SC6->C6_CONTRA,;
              SC6->C6_PLANI,;     
              SC6->C6_QTDVEN })
        SC6->(dbSkip())
    EndDo

Return(aRet)

/* ---------------------------------------------------
{Protheus.doc} GetQtdOri()
RETORNA QUANTIDADE ORIGINAL DE UMA LINHA GRAVADA

@type user function
@author [DN]
@since 28/07/2025
@version version
---------------------------------------------------- */
Static Function GetQtdOri(aQtdOri, cItem, cProduto, cContrat, cPlani)
    Local nQtdOri  := 0
    Local nPosLine := 0
    
    nPosLine := aScan(aQtdOri, {|x| x[1] == cItem .and. x[2] == cProduto .and. x[3] == cContrat .and. x[4] == cPlani })

    If nPosLine > 0
        nQtdOri := aQtdOri[nPosLine][5]
    EndIf

Return(nQtdOri)

/* ---------------------------------------------------
{Protheus.doc} UpDateQtd()
FUNÇAO DE ATUALIZAÇÃO DE QUANTIDADE NO ARRAY AQTD

@type user function
@author [DN]
@since 25/07/2025
@version version
---------------------------------------------------- */

Static Function UpdateQtd(aQtd, cProduto, cContrat, cPlani, nQuant)
    Local nPosLine := 0

    nPosLine := aScan(aQtd, {|x| x[1] == cProduto .and. x[2] == cContrat .and. x[3] == cPlani})

    If nPosLine > 0
        aQtd[nPosLine][4] += nQuant
    Else
        aAdd(aQtd, {cProduto, cContrat, cPlani, nQuant})
    EndIf

Return(aQtd)

/* ---------------------------------------------------
{Protheus.doc} GetQtdTot()
FUNÇAO AUXILIAR PARA OBTER QUANTIDADE TOTAL

@type user function
@author [DN]
@since 25/07/2025
@version version
---------------------------------------------------- */
Static Function GetQtdTot(aQtd, cProduto, cContrat, cPlani)
    Local nPosLine := 0
    Local nTotal   := 0

    nPosLine := aScan(aQtd, {|x| x[1] == cProduto .and. x[2] == cContrat .and. x[3] == cPlani})

    If nPosLine > 0
        nTotal := aQtd[nPosLine][4]
    Else
        nTotal := 0
    EndIf

Return(nTotal)

/* -----------------------------------------------------------
{Protheus.doc} MT100LOK()
P.E NA ALTERAÇÃO DE ITENS DA NF DE ENTRADA
https://tdn.totvs.com/pages/releaseview.action?pageId=6085397
@type user function
@author [DN]
@since 24/07/2025
@version version
----------------------------------------------------------- */

Static Function MT100LOK()
    Local aArea     := GetArea()
    Local lRet      := .T.
    Local aDados    := {}
    Local nPosItem  := 0
    Local nPosPrd   := 0
    Local nPosContr := 0
    Local nPosPatr  := 0
    Local nPosQtd   := 0
    Local nPosFor   := 0
    Local nPosLoja  := 0
    Local nLine     := 0
    Local nQuant    := 0
    Local cItem     := ''
    Local cProduto  := ''
    Local cContrat  := ''
    Local cPatrim   := ''
    Local cCliente  := ''
    Local cLoja     := ''


    Default cTipo := '' //--VARIAVEL PADRAO DA NF DE ENTRADA


    //--LOCALIZA A POSIÇÃO DA COLUNA
    nPosItem  := aScan(aHeader, {|x| AllTrim(x[2]) == "D1_ITEM"   })
    nPosPrd   := aScan(aHeader, {|x| AllTrim(x[2]) == "D1_COD"    })
    nPosContr := aScan(aHeader, {|x| AllTrim(x[2]) == "D1_CONTR"  })
    nPosQtd   := aScan(aHeader, {|x| AllTrim(x[2]) == "D1_QUANT"  })
    nPosPatr  := aScan(aHeader, {|x| AllTrim(x[2]) == "D1_PATRIM" })
    nPosFor   := aScan(aHeader, {|x| AllTrim(x[2]) == "D1_FORNECE"})
    nPosLoja  := aScan(aHeader, {|x| AllTrim(x[2]) == "D1_LOJA"   })


    For nLine := 1 To Len(aCols)
        //--VERIFICA SE A LINHA ESTÁ DELETADA
        If !LinDelet(aCols[nLine])

            //--PEGA O VALOR ATUAL DA LINHA E COLUNA
            cItem    := aCols[nLine][nPosItem]
            cProduto := aCols[nLine][nPosPrd]
            cContrat := aCols[nLine][nPosContr]
            nQuant   := aCols[nLine][nPosQtd]
            cPatrim  := aCols[nLine][nPosPatr]
            cCliente := aCols[nLine][nPosFor]
            cLoja    := aCols[nLine][nPosLoja]

            If !Empty(cPatrim)

                //--VERIFICA SE O VALOR JA EXISTE NO ARRAY 'aDados'
                If aScan(aDados, {|x| x == cPatrim}) > 0
                    Alert("O Código de patrimônio da linha " + cValToChar(nLine) + " já está sendo utilizado em outra linha.")
                    lRet := .F.
                    Exit
                EndIf

                //-- SE NÃO FOI ENCONTRADO ADICIONA AO ARRAY DE CONTROLE
                aAdd(aDados, cPatrim)
            EndIf

            If cTipo == 'D'
            
                If Empty(GDFieldGet('D1_PATRIM')) .or. Empty(GDFieldGet('D1_CONTR'))

                    Alert('Para uma nota de "Devolução", é obrigatório informar o contrato e o patrimônio!')
                    lRet := .F.

                EndIf

            EndIf

        EndIf

    Next nLine

    RestArea(aArea)

Return(lRet)

/* ---------------------------------------------------
Nome: MT103FIM()
P.E APÓS A GRAVAÇÃO DO DOC. DE ENTRADA
https://tdn.totvs.com/pages/releaseview.action?pageId=6085406&showLanguage=all
@type user function
@author Douglas Sousa
@since 07/07/2025
@version version
---------------------------------------------------- */

Static Function MT103FIM() 
    Local nOpcao    := PARAMIXB[1]   // Opção Escolhida pelo usuario no aRotina 
    Local nConfirma := PARAMIXB[2]   // Se o usuario confirmou a operação de gravação da NFECODIGO DE APLICAÇÃO DO USUARIO
    Local oModelSZ0 := NIL
    Local cAliasQry := ''
    Local aMessages := {}
    Local aError    := {}
    Local lAtuRet   := .F.

    Default cTipo    := ''

    If nOpcao == 3 .and. nConfirma == 1

        If cTipo == 'N'

            cAliasQry := GetNextAlias()
            BeginSQL Alias cAliasQry
              SELECT SD1.*
                FROM %Table:SF1% SF1

                JOIN %Table:SD1% SD1
                  ON SD1.D1_FILIAL = SF1.F1_FILIAL
                 AND SD1.D1_DOC = SF1.F1_DOC
                 AND SD1.D1_SERIE = SF1.F1_SERIE
                 AND SD1.D1_FORNECE = SF1.F1_FORNECE
                 AND SD1.D1_LOJA = SF1.F1_LOJA
                 AND SD1.D1_PATRIM <> ' '
                 AND SD1.%notDEL%

               WHERE SF1.F1_FILIAL = %Exp:SF1->F1_FILIAL%
                 AND SF1.F1_DOC = %Exp:SF1->F1_DOC%
                 AND SF1.F1_SERIE = %Exp:SF1->F1_SERIE%
                 AND SF1.F1_FORNECE = %Exp:SF1->F1_FORNECE%
                 AND SF1.F1_LOJA = %Exp:SF1->F1_LOJA%
                 AND SF1.%notDEL%
            EndSQL

            While !(cAliasQry)->(EoF())

                oModelSZ0 := FWLoadModel('OM30A010')
                oModelSZ0:SetOperation(3)
                oModelSZ0:Activate()
                oModelSZ0:SetValue('SZ0MASTER', 'Z0_CODPRO'    , (cAliasQry)->D1_COD)
                oModelSZ0:SetValue('SZ0MASTER', 'Z0_CODPATR'   , (cAliasQry)->D1_PATRIM)
                oModelSZ0:SetValue('SZ0MASTER', 'Z0_STATUS'    , '1')

                If oModelSZ0:VldData() .And. oModelSZ0:CommitData()
                    aAdd(aMessages, 'Patrimonio associado ao item ' + allTrim((cAliasQry)->D1_COD) + ' cadastrado com sucesso!')
                Else
                    If oModelSZ0:hasErrorMessage()

                        aError := oModelSZ0:getErrorMessage()

                        aAdd(aMessages, 'Erro ao cadastrar o Patrimonio vinculado ao item ' + alltrim((cAliasQry)->D1_COD) + ' : ' + AllTrim(aError[6]))
                    Else
                        aAdd(aMessages, 'Ocorreu um erro indeterminado na realizacao do cadastro do Patrimonio vinculado ao item: ' + allTrim((cAliasQry)->D1_COD))
                    EndIf
                EndIf

                oModelSZ0:deActivate()
                oModelSZ0:Destroy()


                (cAliasQry)->(DBSkip())

            End

            (cAliasQry)->(dbCloseArea())

            If len(aMessages) > 0
                showLog(aMessages)
            EndIf

        Else
            If cTipo == 'D'
                lAtuRet := UpdEquip()
            EndIf

        EndIf

    EndIf

Return

/*/
---------------------------------------------------------------------------
{Protheus.doc} UpdQuant()
ATUALIZA QUANTIDADE NA AMARRAÇÃO DO EQUIPAMENTO X CONTRATO
 
@author  DS2U (DN)
@since   jul.2025
@version 1.0
@type    function
---------------------------------------------------------------------------
/*/

Static Function UpdEquip()
    Local cAliasQry := ''
    Local nQtdAloc  := 0
    Local nQtdDevol := 0
    Local lRet      := .T.

    cAliasQry := GetNextAlias()
    BeginSQL Alias cAliasQry
      SELECT SD1.D1_QUANT, SD1.D1_CONTR, SD1.D1_COD, SD1.D1_DOC, SD1.D1_FORNECE, SD1.D1_LOJA, SZ0.Z0_PLANI
        FROM %Table:SD1% SD1

        JOIN %Table:SZ0% SZ0
          ON SZ0.Z0_FILIAL = %xFilial:SZ0%
         AND SZ0.Z0_CODPRO = SD1.D1_COD
         AND SZ0.Z0_CODPATR = SD1.D1_PATRIM
         AND SZ0.Z0_CONTR = SD1.D1_CONTR
         AND SZ0.Z0_CLIENTE = SD1.D1_FORNECE
         AND SZ0.Z0_LOJA = SD1.D1_LOJA
         AND SZ0.%NotDel% 
         
         AND SD1.D1_CONTR <> ' '
       WHERE SD1.%NotDel%
    EndSQL

    If !(cAliasQry)->(Eof())
        While !(cAliasQry)->(Eof())
            nQtdDevol := (cAliasQry)->D1_QUANT

            dbSelectArea('SZ3')
            SZ3->(dbSetOrder(3))
            If SZ3->(dbSeek(xFilial('SZ3')+(cAliasQry)->D1_CONTR+(cAliasQry)->D1_COD+(cAliasQry)->D1_FORNECE+(cAliasQry)->D1_LOJA+(cAliasQry)->Z0_PLANI))
                nQtdAloc := SZ3->Z3_QTDALC
                //--TRAVA TABELA PARA INCREMENTAR QUANTIDADE ALOCADA
                RecLock('SZ3', .F.)
                    SZ3->Z3_QTDALC := nQtdAloc - nQtdDevol
                SZ3->(MsUnLock())

            EndIf

            dbSelectArea('SZ0')
            SZ0->(dbSetOrder(3))
            If SZ0->(dbSeek(xFilial('SZ0')+(cAliasQry)->D1_CONTR+(cAliasQry)->D1_COD+(cAliasQry)->D1_FORNECE+(cAliasQry)->D1_LOJA+(cAliasQry)->Z0_PLANI))
                RecLock('SZ0', .F.)
                    SZ0->Z0_CONTR   := ' '
                    SZ0->Z0_REVISA  := ' '
                    SZ0->Z0_PLANI   := ' '
                    SZ0->Z0_CLIENTE := ' '
                    SZ0->Z0_LOJA    := ' '
                    SZ0->Z0_STATUS  := '1'
                SZ0->(MsUnLock())

            EndIf
            (cAliasQry)->(dbSkip())

        End
        (cAliasQry)->(dbCloseArea())

    EndIf

Return(lRet)

/*/
---------------------------------------------------------------------------
{Protheus.doc} ShowLog
EXIBE LOG DE PROCESSAMENTO
 
@author  DS2U (VR)
@since   jun.2021
@version 1.0
@type    function
---------------------------------------------------------------------------
/*/
Static Function ShowLog(aLog)
    Local oDlg     := NIL
    Local oFont    := NIL
    Local cMemo    := ''
    Local oMemo    := NIL
    Local nCountA  := 0

    Default aLog := {}

    cMemo := ' ======================= [LOG DE PROCESSAMENTO] =======================  ' + Chr(13) + Chr(10)
    cMemo += Chr(13) + Chr(10)
    For nCountA := 1 to Len(aLog)
        cMemo += aLog[nCountA] + Chr(13) + Chr(10)
    Next nCountA
    
    DEFINE MSDIALOG oDlg TITLE 'LOG' From 3,0 to 340,623 PIXEL
        @ 5,5 GET oMemo  VAR cMemo MEMO SIZE 300,145 OF oDlg PIXEL
        oMemo:bRClicked := {|| AllwaysTrue()}
        DEFINE FONT oFont NAME "Courier New" SIZE 5,0
        oMemo:oFont := oFont
        DEFINE SBUTTON  FROM 153,280 TYPE 1 ACTION oDlg:End() ENABLE OF oDlg PIXEL
    ACTIVATE MSDIALOG oDlg CENTER
 
Return

/* ---------------------------------------------------------------
{Protheus.doc} MTA410IC()
P.E EXECUTADO APÓS A GRAVAÇÃO DAS INFORMAÇOES DO PEDIDO DE VENDA
https://tdn.totvs.com/display/public/PROT/MT410INC
@type user function
@author [DN]
@since 24/07/2025
@version version
---------------------------------------------------------------- */

Static Function MTA410I()
    Local cAliasQry := ''
    Local nQtdAtual := 0
    Local lRet      := .T.

    //--CONSULTA QUANTIDADE TOTAL ATUALIZADA
    cAliasQry := GetNextAlias()
    BeginSQL Alias cAliasQry
      SELECT SUM(SC6.C6_QTDVEN) AS QUANT, SC6.C6_CONTRA, SC6.C6_REVISA, SC6.C6_PLANI, SC6.C6_PRODUTO, SC6.C6_CLI, SC6.C6_LOJA
        FROM %Table:SC6% SC6

        JOIN %Table:SC5% SC5
          ON SC5.C5_FILIAL = SC6.C6_FILIAL
         AND SC5.C5_NUM = SC6.C6_NUM
         AND SC5.C5_CLIENTE = SC6.C6_CLI
         AND SC5.C5_LOJACLI = SC6.C6_LOJA 
         AND SC5.%NotDel%
         
       WHERE SC6.C6_FILIAL = SC5.C5_FILIAL 
         AND SC6.C6_CONTRA <> ' '
         AND SC6.C6_PLANI  <> ' '
         AND SC6.%NotDel%

         GROUP BY SC6.C6_CONTRA, SC6.C6_REVISA, SC6.C6_PLANI, SC6.C6_PRODUTO, SC6.C6_CLI, SC6.C6_LOJA
    EndSQL


    If !(cAliasQry)->(Eof())
        While !(cAliasQry)->(Eof())
            nQtdAtual := (cAliasQry)->QUANT

            dbSelectArea('SZ3')
            SZ3->(dbSetOrder(2))
            If SZ3->(dbSeek(xFilial('SZ3')+(cAliasQry)->C6_CONTRA+(cAliasQry)->C6_REVISA+(cAliasQry)->C6_PLANI+(cAliasQry)->C6_PRODUTO+(cAliasQry)->C6_CLI+(cAliasQry)->C6_LOJA))
                //--TRAVA TABELA PARA ATUALIZAR QUANTIDADE
                RecLock('SZ3', .F.)
                    SZ3->Z3_QTDALC := nQtdAtual
                SZ3->(MsUnLock())
            EndIf
            (cAliasQry)->(dbSkip())
        End
        (cAliasQry)->(dbCloseArea())
    EndIf

Return(lRet)

/* -----------------------------------------------------------------------------------------------------------------------------------------------------
{Protheus.doc} SF2460I()
ponto de entrada dentro da transação na gravação das tabelas do documento.
https://centraldeatendimento.totvs.com/hc/pt-br/articles/11814672801943-Cross-Segmento-TOTVS-Backoffice-Linha-Protheus-SIGAFAT-Ponto-de-Entrada-SF2460I
@type user function
@author [DN]
@since 24/07/2025
@version version
------------------------------------------------------------------------------------------------------------------------------------------------------- */

Static Function SF2460I()
    Local aArea     := GetArea()
    Local lRet      := .T.
    Local cAliasQry := ''

    cNumPed  := SC5->C5_NUM
    cCliente := SC5->C5_CLIENTE
    cLojaCli := SC5->C5_LOJACLI
    

    cAliasQry := GetNextAlias()
    BeginSQL Alias cAliasQry
      SELECT SC5.C5_NUM, SC5.C5_CLIENTE, SC5.C5_LOJACLI, SC6.C6_NUM, SC6.C6_ITEM, SC6.C6_CONTRA, 
             SC6.C6_REVISA, SC6.C6_PLANI, SC6.C6_PATRIM, SC6.C6_PRODUTO
        FROM %Table:SC5% SC5

        JOIN %Table:SC6% SC6
          ON SC6.C6_FILIAL = SC5.C5_FILIAL
         AND SC6.C6_NUM = SC5.C5_NUM
         AND SC6.%NotDel%

       WHERE SC5.C5_FILIAL = %xFilial:SC5%
         AND SC5.C5_NUM = %Exp:cNumPed%
         AND SC5.C5_CLIENTE = %Exp:cCliente%
         AND SC5.C5_LOJACLI = %Exp:cLojaCli%
         AND SC5.%NotDel%
    EndSQL


    If !(cAliasQry)->(Eof())

        While !(cAliasQry)->(Eof())

            dbSelectArea('SD2')
            SD2->(dbSetOrder(8))
            SD2->(dbSeek(xFilial('SD2')+(cAliasQry)->C6_NUM+(cAliasQry)->C6_ITEM))

            RecLock("SD2",.F.)
                SD2->D2_CONTRA := (cAliasQry)->C6_CONTRA
                SD2->D2_REVISA := (cAliasQry)->C6_REVISA
                SD2->D2_PLANI  := (cAliasQry)->C6_PLANI
                SD2->D2_PATRIM := (cAliasQry)->C6_PATRIM
            SD2->(MsUnLock())


            dbSelectArea('SZ0')
            SZ0->(dbSetOrder(2))
            If SZ0->(dbSeek(xFilial('SZ0')+(cAliasQry)->C6_PATRIM+(cAliasQry)->C6_PRODUTO))

                RecLock("SZ0", .F.)
                    SZ0->Z0_CONTR   := (cAliasQry)->C6_CONTRA
                    SZ0->Z0_REVISA  := (cAliasQry)->C6_REVISA
                    SZ0->Z0_PLANI   := (cAliasQry)->C6_PLANI
                    SZ0->Z0_CLIENTE := (cAliasQry)->C5_CLIENTE
                    SZ0->Z0_LOJA    := (cAliasQry)->C5_LOJACLI
                    SZ0->Z0_STATUS  := '2'
                SZ0->(MsUnLock())

            EndIf
            (cAliasQry)->(DbSkip())

        End

    EndIf
    (cAliasQry)->(dbCloseArea())

    RestArea(aArea)
Return(lRet)
