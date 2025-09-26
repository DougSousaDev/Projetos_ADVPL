#Include "Totvs.ch"
#Include "FWMVCDef.ch"

/*/
---------------------------------------------------------------------------
{Protheus.doc} FA050DEL
P.E NA CONFIRMAÇÃO DA EXCLUSAO DE TITULOS
https://tdn.totvs.com/pages/releaseview.action?pageId=6071105
@author  DS2U (DN)
@since   AGO.2025
@version 1.0
@type    function
---------------------------------------------------------------------------
/*/

User Function FA050DEL()
    Local lRet       := .T.
    Local cNumero    := SE2->E2_NUM
    Local cPrefixo   := SE2->E2_PREFIXO
    Local cTipo      := SE2->E2_TIPO
    Local aArea      := GetArea()
    Local aAreaSZ6   := SZ6->(GetArea())

    If cTipo <> 'PR'

        cAliasQry := getNextAlias()
        BeginSQL Alias cAliasQry
          SELECT SE2.E2_NUM, SE2.E2_PREFIXO, SE2.E2_TIPO, SZ6.*
            FROM %Table:SE2% SE2

            JOIN %Table:SZ6% SZ6
              ON SZ6.Z6_FILIAL = %xFilial:SZ6%
             AND SZ6.Z6_TITEFT = %Exp:cNumero%
             AND SZ6.Z6_TIPO = 'PR'
             AND SZ6.%NotDel%

           WHERE SE2.E2_FILIAL = %xFilial:SE2%
             AND SE2.E2_TIPO = SZ6.Z6_TIPO
             AND SE2.E2_NUM = SZ6.Z6_NUMTIT
             AND SE2.E2_PREFIXO = SZ6.Z6_PREFIXO
             AND SZ6.%NotDel%
        EndSQL

        While !(cAliasQry)->(Eof())

            dbSelectArea('SZ6')
            SZ6->(dbSetOrder(2)) //--Z6_FILIAL+Z6_NUMTIT+Z6_PREFIXO+Z6_TIPO
            If SZ6->(dbSeek(xFilial('SZ6')+(cAliasQry)->E2_NUM+(cAliasQry)->E2_PREFIXO+(cAliasQry)->E2_TIPO))

                RecLock('SZ6', .F.)
                    SZ6->Z6_TITEFT  := ' '
                    SZ6->Z6_PREFEFT := ' '
                    SZ6->Z6_TPEFT   := ' '
                    SZ6->Z6_PARCEFT := ' '
                    SZ6->Z6_STATUS  := '1'                
                SZ6->(MsUnLock())

            EndIf

            (cAliasQry)->(dbSkip())

        End

        (cAliasQry)->(dbCloseArea())

    Else
        If cTipo == 'PR '

            dbSelectArea('SZ6')
            SZ6->(dbSetOrder(2)) //--//--Z6_FILIAL+Z6_NUMTIT+Z6_PREFIXO+Z6_TIPO
            If SZ6->(dbSeek(xFilial('SZ6')+cNumero+cPrefixo+cTipo))

                RecLock('SZ6', .F.)
                    dbDelete()
                SZ6->(MsUnLock())        

                FWAlertInfo('Titulo: ' + cNumero + ' excluído da rotina de lançamentos de cartão de crédito!')
            EndIf

        EndIf

    EndIf

    RestArea(aAreaSZ6)
    RestArea(aArea)

Return(lRet)

/*User Function FA050DEL()
    Local lRet       := .T.
    Local lExibeLanc := .T.
    Local lOnline    := .T.
    Local cNumero    := SE2->E2_NUM
    Local cTipo      := AllTrim(SE2->E2_TIPO)
    Local nOpc       := 5
    Local nSeqBx     := 1
    Local cAliasQry  := ''
    Local aCanBX     := {}

    Private lMSErroAuto := .F.

    If FwIsInCallStack('FINA750')

        If cTipo == "PR"

            cAliasQry := getNextAlias()
            BeginSQL Alias cAliasQry
              SELECT SZ4.*, SE2.E2_NUM
                FROM %Table:SZ4% SZ4

                JOIN %Table:SE2% SE2
                  ON SE2.E2_FILIAL = %xFilial:SE2%
                 AND SE2.E2_NUM = %Exp:cNumero%
                 AND SE2.E2_TIPO = 'PR'
                 AND SE2.%NotDel%

               WHERE SZ4.Z4_FILIAL = %xFilial:SZ4%
                 AND SZ4.Z4_NUMSEQ = SE2.E2_NUM
                 AND SZ4.%NotDel%   
            EndSQL

            If !(cAliasQry)->(Eof())
                While !(cAliasQry)->(Eof())

                    dbSelectArea('SE2')
                    SE2->(dbSetOrder(1)) //--E2_FILIAL+E2_PREFIXO+E2_NUM+E2_PARCELA+E2_TIPO+E2_FORNECE+E2_LOJA
                    If SE2->(dbSeek(xFilial('SE2')+(cAliasQry)->Z4_PREFIXO+(cAliasQry)->Z4_NUM+(cAliasQry)->Z4_PARCELA+(cAliasQry)->Z4_TIPO))

                        //--VALOR DE BAIXA
					    nVlrPag := SE2->E2_SALDO

                        If nVlrPag == 0
                            aCanBX := {}
                            Aadd(aCanBX, {"E2_FILIAL" , SE2->E2_FILIAL      , nil})
                            Aadd(aCanBX, {"E2_PREFIXO", SE2->E2_PREFIXO     , nil})
                            Aadd(aCanBX, {"E2_NUM"    , SE2->E2_NUM         , nil})
                            Aadd(aCanBX, {"E2_PARCELA", SE2->E2_PARCELA     , nil})
                            Aadd(aCanBX, {"E2_TIPO"   , SE2->E2_TIPO        , nil})
                            Aadd(aCanBX, {"E2_FORNECE", SE2->E2_FORNECE     , nil})
                            Aadd(aCanBX, {"E2_LOJA"   , SE2->E2_LOJA        , nil})
                            Aadd(aCanBX, {"AUTMOTBX"  , " "                 , nil})
                            Aadd(aCanBX, {"AUTBANCO"  , " "                 , nil})
                            Aadd(aCanBX, {"AUTAGENCIA", " "                 , nil})
                            Aadd(aCanBX, {"AUTCONTA"  , " "                 , nil})
                            Aadd(aCanBX, {"AUTDTBAIXA", NIL                 , nil})
                            Aadd(aCanBX, {"AUTDTDEB"  , NIL                 , nil})
                            Aadd(aCanBX, {"AUTHIST"   , " "                 , nil})
                            Aadd(aCanBX, {"AUTVLRPG"  , nVlrPag             , nil})

                            //--PERGUNTAS DA ROTINA
                            AcessaPerg("FINA080", .F.)

                            MsExecauto({|a,b,c,d,e,f,| FINA080(a,b,c,d,e,f)}, aCanBX, nOpc, .F., nSeqBx, lExibeLanc, lOnline)

                            If lMsErroAuto
                                lGrava := .F.
                                FWAlertError('Ocorreu um erro ao tentar realizar a baixa dos titulos, a seguir será apresentado detalhes do erro ...', 'Erro nas Baixas!')
                                MostraErro()
                                DisarmTransaction()
                            EndIf

						    F080ClearM()
                        Else
                            FWAlertInfo("Título " + SE2->E2_NUM + " possui saldo em aberto")
                        EndIf
				    Else
					    FWAlertInfo("Título não encontrado: " + SE2->E2_NUM)

                    EndIf

                    //--POSICIONA NOS TITULOS VINCULADOS A FATURA
                    dbSelectArea('SZ4')                    
                    SZ4->(dbSetOrder(1))
                    If SZ4->(dbSeek(xFilial('SZ4')+(cAliasQry)->E2_NUM))

                        RecLock('SZ4', .F.)
                            dbDelete()
                        SZ4->(MsUnLock())

                    EndIf

                    (cAliasQry)->(dbSkip())

                End
                
            EndIf

        EndIf

    EndIf

Return(lRet)
*/
