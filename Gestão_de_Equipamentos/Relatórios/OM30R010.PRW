#INCLUDE 'TOTVS.CH'
#INCLUDE 'MSOLE.CH'

Static cRootPath   := allTrim(GetPvProfString(GetEnvServer(), 'RootPath', 'ERROR', GetADV97()) + If(Right(allTrim(GetPvProfString(GetEnvServer(), 'RootPath', 'ERROR', GetADV97())), 1) == '/', '', '/'))
Static cStartPath  := allTrim(GetPvProfString(GetEnvServer(), 'StartPath', 'ERROR', GetADV97()) + If(Right(allTrim(GetPvProfString(GetEnvServer(), 'StartPath', 'ERROR', GetADV97())), 1) == '/', '', '/'))

/*/
---------------------------------------------------------------------------
{Protheus.doc} OM30R010
IMPRESSAO GRAFICA DE LOCAÇÃO DE SERVIÇO

@author  DS2U (DN)
@since   AGOSTO.2025
@version 1.0
@type    function
---------------------------------------------------------------------------
/*/
User Function OM30R010()
    Local lOk        := .F.
    Local aSays      := {}
    Local aButtons   := {}
    Local cPerg      := 'OM30R010'


    // ---------------------------------------------------------------
    // PARAMETROS DO RELATORIO
    // ---------------------------------------------------------------
    // MV_PAR01 : Da Filial
    // MV_PAR02 : Ate a Filial
    // MV_PAR03 : DO DOCUMENTO
    // MV_PAR04 : ATE O DOCUMENTO
    // MV_PAR05 : DA SERIE
    // MV_PAR06 : DO CLIENTE
    // MV_PAR07 : DA LOJA
    // MV_PAR08 : ATE O CLIENTE
    // MV_PAR09 : ATE A LOJA
    // MV_PAR10 : DA EMISSAO
    // MV_PAR11 : ATE A EMISSAO
    // MV_PAR12 : DESTINO/SAIDA (1=IMPRESSORA | 2=DISCO)
    // MV_PAR13 : SALVAR COMO (1=PDF | 2=DOC)
    // ---------------------------------------------------------------
    Pergunte(cPerg, .F.)


    // ---------------------------------------------------------------
    // DIALOGO PRINCIPAL
    // ---------------------------------------------------------------
    AAdd(aSays, 'Este programa tem por objetivo realizar a impressao grafica da Fatura de Locação ')
    AAdd(aSays, 'A impressao/geracao do documento utiliza o processo de integracao com o Microsoft Word. ')
    AAdd(aSays, 'Portanto, certifique-se que voce possui o Microsoft Word instalado em sua estacao de trabalho.')
    AAdd(aButtons, {5, .T., {|| pergunte(cPerg,.T. )}})
    AAdd(aButtons, {1, .T., {|o| lOk := .T., o:oWnd:End()}})
    AAdd(aButtons, {2, .T., {|o| o:oWnd:End()}})

    FormBatch('Fatura de Locação', aSays, aButtons,,, 650)

    If lOk
        Processa({|lEnd| OM30R010Prc(@lEnd)}, 'Aguarde...', 'Realizando a impressao do documento...', .T.)
    EndIf

Return

/*/
---------------------------------------------------------------------------
{Protheus.doc} OM30R010PRC
PROCESSAMENTO DA IMPRESSAO

@author  DS2U (DN)
@since   AGOSTO.2025
@version 1.0
@type    function
---------------------------------------------------------------------------
/*/

Static Function OM30R010Prc(lEnd)
    Local lContinua   := .T.
    Local cArqModel   := cStartPath + 'modelos/om30r010.dotm'
    Local cExtension  := ''
    Local cPathDest   := ''
    Local cAliasQry   := ''
    Local cArqTemp    := ''
    Local cPorcImp    := ''
    Local cValImp     := ''
    Local cDescImp    := ''
    Local aDadosEmp   := FWSM0Util():getSM0Data()
    Local nVlrMinIRRF := superGetMV("MV_VLRETIR",.T.,10)
    Local nVlrBruto   := 0	
	Local nVlrLiq     := 0
	Local nBaseISS    := 0
	Local nAliqISS    := 0
	Local nVlrISS     := 0
	Local nBaseIRRF   := 0
	Local nAliqIRRF   := 0
	Local nVlrIRRF    := 0
    Local nBasePIS    := 0
	Local nAliqPIS    := 0
	Local nVlrPIS     := 0

	Local nBaseCOFINS := 0
	Local nAliqCOFINS := 0
	Local nVlrCOFINS  := 0

	Local nBaseCSLL   := 0
	Local nAliqCSLL   := 0
	Local nVlrCSLL    := 0


    Local nItems      := 0
    Local cDestino    := MV_PAR12
    Local cSaveAs     := MV_PAR13
    Local cOrigFile
    Local cNewFile
    Local aFiles      := {}
    Local nlx

    // ---------------------------------------
    // VERIFICA SE O ARQUIVO "MODELO" EXISTE
    // ---------------------------------------
    If !File(cArqModel)
        lContinua := .F.
        Help('', 1, 'OM30R010',, 'O arquivo ' + cArqModel + ' nao existe! Entre em contato com o Administrador do sistema.', 4)
    EndIf

    // ---------------------------------------
    // TRATA GRAVACAO EM DISCO
    // ---------------------------------------
    If lContinua
        If cDestino == 2
            cExtension := If(cSaveAs == 1, '*.PDF', '*.DOCX')
            cPathDest  := tFileDialog('Word Document (*.DOCX) | All Word Document files (*.DOCX)', 'Selecione a pasta destino',,, .F., GETF_RETDIRECTORY)
            If Empty(cPathDest)
                Help('', 1, 'OM30R010',, 'Processo cancelado pelo usuario!', 4)
                lContinua := .F.
            Else
                lContinua := ChkPerGrv(cPathDest)
                If !lContinua
                    Help('', 1, 'OM30R010', 'Voce nao possui permissao de gravacao p/ a pasta selecionada. Tente selecionar outra pasta.', 4)
                EndIf
            EndIf
        Endif
    EndIf

    // ------------------------------------------------
    // TRANSFERE MODELO WORD DO SERVIDOR P/ ESTACAO
    // ------------------------------------------------
    If lContinua
        If !CpyS2T(cArqModel, allTrim(GetTempPath()))
            lContinua := .F.
            Help('', 1, 'OM30R010', 'Nao foi possivel transferir o modelo Word do Servidor para sua estacao de trabalho! Tente reiniciar o computador. Caso o problema persista, entre em contato com o Administrador do sistema', 4)
        EndIf
    EndIf

    // ------------------------------------------
    // IMPRESSAO DO DOCUMENTO
    // ------------------------------------------
    If lContinua
        //--SELECIONA OS ORCAMENTOS
        cAliasQry := GetNextAlias()
        beginSQL Alias cAliasQry
          SELECT SF2.R_E_C_N_O_ SF2Recno
            FROM %Table:SF2% SF2
           WHERE SF2.F2_FILIAL BETWEEN %Exp:MV_PAR01% AND %Exp:MV_PAR02%
             AND SF2.F2_DOC BETWEEN %Exp:MV_PAR03% AND %Exp:MV_PAR04%
             AND SF2.F2_SERIE = %Exp:MV_PAR05%
             AND SF2.F2_CLIENTE BETWEEN %Exp:MV_PAR06% AND %Exp:MV_PAR08%
             AND SF2.F2_LOJA BETWEEN %Exp:MV_PAR07% AND %Exp:MV_PAR09%
             AND SF2.F2_EMISSAO BETWEEN %Exp:MV_PAR10% AND %Exp:MV_PAR11%
             AND SF2.%NotDel%
        endSQL

        If !(cAliasQry)->(Eof())        
            While !(cAliasQry)->(Eof())

                // --------------------------------------------------------
                // SE CONSEGUIU TRANSFERIR O ARQUIVO, RENOMEIA O MESMO
                // PARA PREVENIR, EM CASO DE ERRO, O TRAVAMENTO DO ARQUIVO
                // DE MODELO
                // --------------------------------------------------------
                cArqTemp  := GetNextAlias()  + '_' + StrTran(Time(), ':', '') + '.dotm'          
                cOrigFile := allTrim(GetTempPath()) + If(Right(allTrim(GetTempPath()), 1) == '\', '', '\') + 'om30r010.dotm'
                cNewFile  := allTrim(GetTempPath()) + If(Right(allTrim(GetTempPath()), 1) == '\', '', '\') + cArqTemp
                __CopyFile(cOrigFile, cNewFile)
                cArqTemp := cNewFile
                
                //--POSICIONA NO CABECALHO DO ORCAMENTO
                dbSelectArea("SF2")
                SF2->(dbGoTo((cAliasQry)->SF2Recno))
                If ( SF2->(Recno()) == (cAliasQry)->SF2Recno )
                
                    //--POSICIONA NO CLIENTE
                    dbSelectArea("SA1")
                    SA1->(dbSetOrder(1)) //--A1_FILIAL+A1_COD+A1_LOJA
                    If (SA1->(dbSeek(xFilial('SA1')+SF2->(F2_CLIENTE+F2_LOJA))))

                        //--RETENÇÕES DE IMPOSTOS
                        nVlrBruto   := SF2->F2_VALBRUT

                        nBaseISS    := SF2->F2_BASEISS
                        nAliqISS    := round( (SF2->F2_VALISS / SF2->F2_VALBRUT) * 100, 2)
                        nVlrISS     := If(SA1->A1_RECISS == '1', SF2->F2_VALISS, 0)

                        nBaseIRRF   := SF2->F2_BASEIRR
                        nAliqIRRF   := round( (SF2->F2_VALIRRF / SF2->F2_VALBRUT) * 100, 2)
                        nVlrIRRF    := If(SA1->A1_RECIRRF == '1' .And. SF2->F2_VALIRRF > nVlrMinIRRF, SF2->F2_VALIRRF, 0)

                        nBasePIS    := SF2->F2_BASPIS
                        nAliqPIS    := round( (SF2->F2_VALPIS / SF2->F2_VALBRUT) * 100, 2)
                        nVlrPIS     := If(SA1->A1_RECPIS == 'S' .And. SF2->F2_VALPIS > 0, SF2->F2_VALPIS, 0)
                        
                        nBaseCOFINS := SF2->F2_BASCOFI
                        nAliqCOFINS := round( (SF2->F2_VALCOFI / SF2->F2_VALBRUT) * 100, 2)
                        nVlrCOFINS  := If(SA1->A1_RECCOFI == 'S' .And. SF2->F2_VALCOFI > 0, SF2->F2_VALCOFI, 0)
                        
                        nBaseCSLL   := SF2->F2_BASCSLL
                        nAliqCSLL   := round( (SF2->F2_VALCSLL / SF2->F2_VALBRUT) * 100, 2)
                        nVlrCSLL    := If(SA1->A1_RECCSLL == 'S' .And. SF2->F2_VALCSLL > 0, SF2->F2_VALCSLL, 0)

                        nVlrLiq     := nVlrBruto - ( If(SA1->A1_RECISS == '1', nVlrISS, 0) + If(SA1->A1_RECIRRF == '1', nVlrIRRF, 0) + If(SA1->A1_RECPIS == 'S', nVlrPIS, 0) + If(SA1->A1_RECCOFI == 'S', nVlrCOFINS, 0)  + If(SA1->A1_RECCSLL == 'S', nVlrCSLL, 0) )


                        //--IMPOSTOS
                        If nVlrISS > 0
                            cPorcImp := Transform(nAliqISS, "@E 99.99%")
                            cDescImp := "Desconto ISS "
                            cValImp  := "R$ " + Transform(nVlrISS, "@E 999,999,999.99")
                        EndIf

                        If nVlrIRRF > 0
                            cPorcImp  := Transform(nAliqIRRF, "@E 99.99%")
                            cDescImp  := "Desconto IRRF"
                            cValImp   := "R$ " + Transform(nVlrIRRF, "@E 999,999,999.99")
                        EndIf

                        If nVlrPIS > 0
                            cPorcImp := Transform(nAliqPIS, "@E 99.99%")
                            cDescImp := "Desconto PIS"
                            cValImp  := "R$ " + Transform(nVlrPIS, "@E 999,999,999.99")
                        EndIf

                        If nVlrCOFINS > 0
                            cPorcImp := Transform(nAliqCOFINS, "@E 99.99%")
                            cDescImp := "Desconto COFINS"
                            cValImp  := "R$ " + Transform(nVlrCOFINS, "@E 999,999,999.99")
                        EndIf

                        If nVlrCSLL > 0
                            cPorcImp := Transform(nAliqCSLL, "@E 99.99%")
                            cDescImp := "Desconto CSLL"
                            cValImp  := "R$ " + Transform(nVlrCSLL, "@E 999,999,999.99")
                        EndIf

                        //--VALOR LIQUIDO
                        cValLiq := " R$"  + Transform(nVlrLiq, "@E 999,999,999.99")


                        //--POSICIONA NA CONDIÇÃO DE PAGAMENTO (SE4)
                        dbSelectArea("SE4")
                        SE4->(dbSetOrder(1)) //--E4_FILIAL+E4_CODIGO
                        If (SE4->(dbSeek(xFilial('SE4')+SF2->F2_COND)))

                            // ------------------------------------------------------------------------
                            //
                            // ESTABELECE COMUNICACAO COM O MS WORD
                            //
                            // ------------------------------------------------------------------------

                            //-- Arquivo que sera gerado:
                            cNewFile := cPathDest + If(Right(cPathDest, 1) == '\', '', '\') + allTrim(SF2->F2_DOC) + '_' + StrTran(Time(), ':', '') + '_OM30R010' + StrTran(cExtension, '*', '')

                            oWord := OLE_CreateLink()
                            OLE_SetProperty(oWord, oleWdVisible, .F.)
                            If oWord == "-1"
                                Help('', 1, 'OM30R010', 'Nao foi possivel estabelecer a conexao com o MS-Word!', 4)

                            Else
                                // ------------------------------------------------------------------------
                                // CARREGA MODELO
                                // ------------------------------------------------------------------------
                                OLE_NewFile(oWord, allTrim(cArqTemp))

                                // ------------------------------------------------------------------------
                                // REALIZA O PROCESSO DE MACRO SUBSTITUICAO DOS CAMPOS DO MODELO WORD
                                // ------------------------------------------------------------------------

                                //--CABECALHO DO DOCUMENTO
                                OLE_SetDocumentVar(oWord, 'cNumDoc'	    , SF2->F2_DOC)
                                OLE_SetDocumentVar(oWord, 'cSerieDoc'   , SF2->F2_SERIE)

                                //--DADOS DA EMPRESA
                                OLE_SetDocumentVar(oWord, 'cEmpresa'    , allTrim(aDadosEmp[aScan(aDadosEmp, {|x| allTrim(x[1]) == 'M0_FULNAME'})][2]))
                                OLE_SetDocumentVar(oWord, 'cEndEmp'     , allTrim(aDadosEmp[aScan(aDadosEmp, {|x| allTrim(x[1]) == 'M0_ENDENT'})][2]))
                                OLE_SetDocumentVar(oWord, 'cCGCEmp'     , transform(allTrim(aDadosEmp[aScan(aDadosEmp, {|x| allTrim(x[1]) == 'M0_CGC'})][2]), PesqPict('SA1', 'A1_CGC')))
                                OLE_SetDocumentVar(oWord, 'cInscrMuni'  , allTrim(aDadosEmp[aScan(aDadosEmp, {|x| allTrim(x[1]) == 'M0_INSCM'})][2]))
                                OLE_SetDocumentVar(oWord, 'cMunEmp'     , allTrim(aDadosEmp[aScan(aDadosEmp, {|x| allTrim(x[1]) == 'M0_CIDENT'})][2]))
                                OLE_SetDocumentVar(oWord, 'cUFEmp'      , FWGetSX5('12', allTrim(aDadosEmp[aScan(aDadosEmp, {|x| allTrim(x[1]) == 'M0_ESTENT'})][2]))[1][3])
                                OLE_SetDocumentVar(oWord, 'cCEPEmp'     , transform(allTrim(aDadosEmp[aScan(aDadosEmp, {|x| allTrim(x[1]) == 'M0_CEPENT'})][2]), PesqPict('SA1', 'A1_CEP')))

                                //--DADOS DO CLIENTE
                                OLE_SetDocumentVar(oWord, 'cNomeCli'	, allTrim(SA1->A1_NOME))
                                OLE_SetDocumentVar(oWord, 'cFantasia'   , allTrim(SA1->A1_NREDUZ))
                                OLE_SetDocumentVar(oWord, 'cCNPJCli'    , transform(SA1->A1_CGC, PesqPict('SA1', 'A1_CGC')))
                                OLE_SetDocumentVar(oWord, 'cEndCli'     , allTrim(SA1->A1_END) + If(!empty(SA1->A1_COMPLEM), ' - ' +  allTrim(SA1->A1_COMPLEM), ''))
                                OLE_SetDocumentVar(oWord, 'cBairroCli'  , allTrim(SA1->A1_BAIRRO))
                                OLE_SetDocumentVar(oWord, 'cMunCli'	    , allTrim(SA1->A1_MUN))
                                OLE_SetDocumentVar(oWord, 'cCEPCli'     , transform(SA1->A1_CEP, PesqPict('SA1', 'A1_CEP')))
                                OLE_SetDocumentVar(oWord, 'cUFCli'      , allTrim(SA1->A1_EST))
                                OLE_SetDocumentVar(oWord, 'cInscrEstCli', transform(SA1->A1_INSCR, PesqPict('SA1', 'A1_INSCR')))
                                OLE_SetDocumentVar(oWord, 'cTelCli'     , '(' + allTrim(SA1->A1_DDD) + ') ' + Transform(SA1->A1_TEL, PesqPict('SA1', 'A1_TEL')))
                                OLE_SetDocumentVar(oWord, 'cEmailCli'   , allTrim(SA1->A1_EMAIL))
                                OLE_SetDocumentVar(oWord, 'cCondPagCli' , allTrim(SE4->E4_DESCRI))

                                //--VALOR TOTAL/DESCONTOS
                                OLE_SetDocumentVar(oWord, 'cValFat'     , AllTrim(cValLiq))
                                OLE_SetDocumentVar(oWord, 'nValBruto'   , 'R$ ' + AllTrim(transform(SF2->F2_VALBRUT , PesqPict('SF2', 'F2_VALBRUT'))))
                                OLE_SetDocumentVar(oWord, 'cPercDescon' , AllTrim(cPorcImp))
                                OLE_SetDocumentVar(oWord, 'cDescImp'    , AllTrim(cDescImp))
                                OLE_SetDocumentVar(oWord, 'cValDescont' , AllTrim(cValImp))

                                //--RODAPE DO DOCUMENTO
                                OLE_SetDocumentVar(oWord, 'dDataReceb'	, DtoC(SF2->F2_EMISSAO))

                                dbSelectArea("SD2")                    
                                SD2->(dbSetOrder(3)) //--D2_FILIAL+D2_DOC+D2_SERIE+D2_CLIENTE+D2_LOJA+D2_COD+D2_ITEM
                                If ( SD2->(dbSeek(xFilial('SD2')+SF2->(F2_DOC+F2_SERIE+F2_CLIENTE+F2_LOJA))) )

                                    dbSelectArea("CN9")
                                    CN9->(dbSetOrder(1)) //--CN9_FILIAL+CN9_NUMERO+CN9_REVISA
                                    If ( CN9->(dbSeek(xFilial('CN9')+SD2->D2_CONTRA)))

                                        //--DADOS DO CONTRATO
                                        OLE_SetDocumentVar(oWord, 'cContratoCli', AllTrim(SD2->D2_CONTRA))
                                        OLE_SetDocumentVar(oWord, 'cPlaniCli'	, AllTrim(SD2->D2_PLANI))
                                        OLE_SetDocumentVar(oWord, 'cNumPreg'	, AllTrim(CN9->CN9_NRPREG))
                                        OLE_SetDocumentVar(oWord, 'cNumProc'	, AllTrim(CN9->CN9_NRPROC))

                                        dbSelectArea("CND")
                                        CND->(dbSetOrder(1)) //--CND_FILIAL+CND_CONTRA+CND_REVISA+CND_NUMERO+CND_NUMMED
                                        If ( CND->(dbSeek(xFilial('CND')+SD2->D2_CONTRA)))

                                            dbSelectArea("SA6")
                                            SA6->(dbSetOrder(1)) //-- A6_FILIAL+A6_COD+A6_AGENCIA+A6_NUMCON
                                            If ( SA6->(dbSeek(xFilial('SA6')+CND->CND_BANCO)))

                                                //--DADOS BANCÁRIOS
                                                OLE_SetDocumentVar(oWord, 'cNomBanc'	, AllTrim(SA6->A6_NREDUZ))
                                                OLE_SetDocumentVar(oWord, 'cCodBanc'	, AllTrim(CND->CND_BANCO))
                                                OLE_SetDocumentVar(oWord, 'cNumAge'	    , AllTrim(CND->CND_AGENCI))
                                                OLE_SetDocumentVar(oWord, 'cCtaCorren'  , AllTrim(CND->CND_NUMCON))
                                                OLE_SetDocumentVar(oWord, 'cDvCta'	    , AllTrim(CND->CND_DVCTA))
                                                OLE_SetDocumentVar(oWord, 'cMsgNF'	    , AllTrim(CND->CND_MSGPNF))

                                                //--ITENS DO RECIBO
                                                nItems    := 0

                                                While !SD2->(Eof()) .And. SD2->(D2_FILIAL+D2_DOC) == SF2->(F2_FILIAL+F2_DOC)
                                                    nItems++

                                                    SB1->(dbSetOrder(1)) //--B1_FILIAL+B1_COD
                                                    SB1->(dbSeek(xFilial('SB1')+SD2->D2_COD))                                    

                                                    OLE_SetDocumentVar(oWord, 'cItem_' + allTrim(Str(nItems))    , strZero(nItems, 3))
                                                    OLE_SetDocumentVar(oWord, 'cProd_' + allTrim(Str(nItems))    , allTrim(SD2->D2_COD) + ' - '  + alltrim(SB1->B1_DESC))
                                                    OLE_SetDocumentVar(oWord, 'cProdUM_' + allTrim(Str(nItems))  , alltrim(SB1->B1_UM))
                                                    OLE_SetDocumentVar(oWord, 'nQtde_' + allTrim(Str(nItems))    , allTrim(transform(SD2->D2_QUANT, pesqPict('SD2', 'D2_QUANT'))))
                                                    OLE_SetDocumentVar(oWord, 'nVlrUnit_' + allTrim(Str(nItems)) , 'R$ ' + allTrim(transform(SD2->D2_PRCVEN  , pesqPict('SD2', 'D2_PRCVEN'))))
                                                    OLE_SetDocumentVar(oWord, 'nVlrTotal_' + allTrim(Str(nItems)) , 'R$ ' + allTrim(transform(SD2->D2_TOTAL , pesqPict('SD2', 'D2_TOTAL'))))

                                                    SD2->(dbSkip())

                                                EndDo

                                            EndIf

                                        EndIf

                                    EndIf

                                EndIf

                            EndIf

                            //--QUANTIDADE DE ITENS
                            OLE_SetDocumentVar(oWord, 'nItems', allTrim(str(nItems)))

                        EndIf

                        // -------------------------------------------
                        // TRATAMENTO DAS MACROS DO DOCUMENTO
                        // -------------------------------------------
                        OLE_ExecuteMacro(oWord, 'mcrItens')

                        //-- Atualiza os campos
                        OLE_UpDateFields(oWord)

                        //-- Determina a saida do relatorio:
                        If cDestino == 1
                            OLE_PrintFile(oWord, cNewFile,,, 1)
                            Sleep(1000)
                        Else
                            OLE_SaveAsFile(oWord, cNewFile,,,, If(cSaveAs == 1, '17', NIL)) //--Parametro '17' salva em pdf
                        Endif

                        //--Fecha link com MS-Word
                        OLE_CloseFile(oWord)
                        OLE_CloseLink(oWord)

                        AADD(aFiles, cNewFile)

                        (cAliasQry)->(dbSkip())

                    Else
                        Help('', 1, 'OM30R010', 'Cliente do documento ' + allTrim(SF2->F2_CLIENTE) + ' nao encontrado!', 4)
                    EndIf

                Else
                    Help('', 1, 'OM30R010', 'Nao foi possivel localizar o documento ' + allTrim(SF2->F2_DOC) + '!', 4)
                EndIf

            EndDo

            (cAliasQry)->(dbCloseArea())

            MsgInfo('Impressao/Geracao realizada com sucesso!', 'Fatura de Locação')

            If cDestino == 2 .And. cSaveAs == 1
                For nlx := 1 to len(aFiles)
                    shellExecute('Open', aFiles[nlx], ' /k dir', 'C:\', 1)
                Next nlx
            EndIf

        Else
            MsgAlert('Nao ha dados para impressao. Verifique os parametros informados!', 'Fatura de Locação')

        EndIf

        //-- Exclui arquivo modelo na estacao:
        FErase(cArqTemp)

    EndIf

Return


/*/
---------------------------------------------------------------------------
{Protheus.doc} ChkPerGrv
VERIFICAR PERMISSAO DE GRAVACAO NA PASTA INDICADA

@author  DS2U (VR)
@since   Ago.2020
@version 1.0
@type    function
---------------------------------------------------------------------------
/*/
Static Function ChkPerGrv(cPath)
    Local cFileTmp := CriaTrab(NIL, .F.)
    Local nHdlTmp  := 0
    Local lRet     := .F.

    cPath   := allTrim(cPath)
    nHdlTmp := MSFCreate(cPath + If(Right(cPath, 1) <> '\', '\', '') + cFileTmp + '.TMP', 0)
    If nHdlTmp <= 0
        lRet := .F.
    Else
        lRet := .T.
        FClose(nHdlTmp)
        FErase(cPath + If(Right(cPath, 1) <> '\', '\', '') + cFileTmp + '.TMP')
    EndIf

Return(lRet)

/*-----------------------------------------------------------------------

MACRO MS-WORD P/ IMPRESSAO DOS ITENS

-----------------------------------------------------------------------
MACROS AQQR010

Sub mcrItens()
'
' mcrItens Macro
'
'
'
    Dim nCountA As Integer
    Dim nItens As Integer
    Dim lColor As Boolean
    
    'Posiciona no marcador/indicador para insercao dos itens
    Selection.GoTo What:=wdGoToBookmark, Name:="tblItens"
    
    lColor = True
    nItems = Val(ActiveDocument.Variables.Item("nItems").Value)
    For nCountA = 1 To nItems
        'Item
        Selection.MoveRight Unit:=wdCell
        Selection.Shading.BackgroundPatternColor = IIf(lColor, RGB(225, 225, 225), wdColorWhite)
        cCampo = "DOCVARIABLE cItem_" & Trim(Str(nCountA))
        Selection.Fields.Add Range:=Selection.Range, Type:=wdFieldEmpty, Text:=cCampo, PreserveFormatting:=True
        
        'Cod. Produto
        Selection.MoveRight Unit:=wdCell
        Selection.Shading.BackgroundPatternColor = IIf(lColor, RGB(225, 225, 225), wdColorWhite)
        cCampo = "DOCVARIABLE cProd_" & Trim(Str(nCountA))
        Selection.Fields.Add Range:=Selection.Range, Type:=wdFieldEmpty, Text:=cCampo, PreserveFormatting:=True

        'Unidade Medida
        Selection.MoveRight Unit:=wdCell
        Selection.Shading.BackgroundPatternColor = IIf(lColor, RGB(225, 225, 225), wdColorWhite)
        cCampo = "DOCVARIABLE cProdUM_" & Trim(Str(nCountA))
        Selection.Fields.Add Range:=Selection.Range, Type:=wdFieldEmpty, Text:=cCampo, PreserveFormatting:=True
        
        'Quantidade
        Selection.MoveRight Unit:=wdCell
        Selection.Shading.BackgroundPatternColor = IIf(lColor, RGB(225, 225, 225), wdColorWhite)
        cCampo = "DOCVARIABLE nQtde_" & Trim(Str(nCountA))
        Selection.Fields.Add Range:=Selection.Range, Type:=wdFieldEmpty, Text:=cCampo, PreserveFormatting:=True
        
        'Valor Unitario
        Selection.MoveRight Unit:=wdCell
        Selection.Shading.BackgroundPatternColor = IIf(lColor, RGB(225, 225, 225), wdColorWhite)
        cCampo = "DOCVARIABLE nVlrUnit_" & Trim(Str(nCountA))
        Selection.Fields.Add Range:=Selection.Range, Type:=wdFieldEmpty, Text:=cCampo, PreserveFormatting:=True
        
        'Subtotal
        Selection.MoveRight Unit:=wdCell
        Selection.Shading.BackgroundPatternColor = IIf(lColor, RGB(225, 225, 225), wdColorWhite)
        cCampo = "DOCVARIABLE nVlrTot_" & Trim(Str(nCountA))
        Selection.Fields.Add Range:=Selection.Range, Type:=wdFieldEmpty, Text:=cCampo, PreserveFormatting:=True
    
        lColor = IIf(lColor = True, False, True)
    Next

End Sub
*/
