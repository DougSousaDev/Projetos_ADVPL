#Include "Totvs.ch"
#Include "FWMVCDef.ch"

#DEFINE DEF_TITULO_DO_CAMPO		01	//-- Titulo do campo
#DEFINE DEF_TOOLTIP_DO_CAMPO	02	//-- ToolTip do campo
#DEFINE DEF_IDENTIFICADOR		03	//-- identificador (ID) do Field
#DEFINE DEF_TIPO_DO_CAMPO		04	//-- Tipo do campo
#DEFINE DEF_TAMANHO_DO_CAMPO	05	//-- Tamanho do campo
#DEFINE DEF_DECIMAL_DO_CAMPO	06	//-- Decimal do campo
#DEFINE DEF_CODEBLOCK_VALID		07	//-- Code-block de validação do campo
#DEFINE DEF_CODEBLOCK_WHEN		08	//-- Code-block de validação When do campo
#DEFINE DEF_LISTA_VAL			09	//-- Lista de valores permitido do campo
#DEFINE DEF_OBRIGAT				10	//-- Indica se o campo tem preenchimento obrigatório
#DEFINE DEF_CODEBLOCK_INIT		11	//-- Code-block de inicializacao do campo
#DEFINE DEF_CAMPO_CHAVE			12	//-- Indica se trata de um campo chave
#DEFINE DEF_RECEBE_VAL			13	//-- Indica se o campo pode receber valor em uma operação de update.
#DEFINE DEF_VIRTUAL				14	//-- Indica se o campo é virtual
#DEFINE DEF_VALID_USER			15	//-- Valid do usuario
#DEFINE DEF_ORDEM				16	//-- Ordem do campo
#DEFINE DEF_HELP				17	//-- Array com o Help dos campos
#DEFINE DEF_PICTURE				18	//-- Picture do campo
#DEFINE DEF_PICT_VAR			19	//-- Bloco de picture Var
#DEFINE DEF_LOOKUP				20	//-- Chave para ser usado no LooKUp
#DEFINE DEF_CAN_CHANGE			21	//-- Logico dizendo se o campo pode ser alterado
#DEFINE DEF_ID_FOLDER			22	//-- Id da Folder onde o field esta
#DEFINE DEF_ID_GROUP			23	//-- Id do Group onde o field esta
#DEFINE DEF_COMBO_VAL			24	//-- Array com os Valores do combo
#DEFINE DEF_TAM_MAX_COMBO		25	//-- Tamanho maximo da maior opção do combo
#DEFINE DEF_INIC_BROWSE			26	//-- Inicializador do Browse
#DEFINE DEF_PICTURE_VARIAVEL	27	//-- Picture variavel
#DEFINE DEF_INSERT_LINE			28	//-- Se verdadeiro, indica pulo de linha após o campo
#DEFINE DEF_WIDTH				29	//-- Largura fixa da apresentação do campo
#DEFINE DEF_TIPO_CAMPO_VIEW		30	//-- Tipo do campo
#DEFINE QUANTIDADE_DEFS         30  //-- Quantidade de DEFs

/*/
--------------------------------------------------------------------------
{Protheus.doc} OM30A020()
TABELA MVC PARA AMARRAÇÃO DE EQUIPAMENTO X PRODUTO

@type user function
@author Douglas Sousa
@since 17/07/2025
@version version
--------------------------------------------------------------------------
/*/

User Function OM30A020()
    Local aButtons := { {.F., NIL}, {.F., NIL}, {.F., NIL}, {.F., NIL}, {.F., NIL}, {.F., NIL},;
                            {.T., 'Salvar'}, {.T., 'Cancelar'}, {.F., NIL}, {.F., NIL},; 
                            {.F., NIL}, {.F., NIL}, {.F., NIL}, {.F., NIL}}

    FWExecView('Equipamentos x Produtos(SV)', 'VIEWDEF.OM30A020', MODEL_OPERATION_UPDATE,,,, 60, aButtons)

Return

/*/
---------------------------------------------------------------------------
{Protheus.doc} ModelDef
DEFINICAO DO MODELO DE DADOS
@author  DS2U (DN)
@since   JUL.2025
@version 1.0
@type    function
---------------------------------------------------------------------------
/*/

Static Function ModelDef()
    Local oModel      := NIL
	Local oStructFake := NIL
    Local oStructCNB  := NIL
    Local oStructSZ3  := NIL
	Local aTrigger 	  := {}
    Local bCommit     := {|| grvEquip(oModel)}
	Local bLinePos    := {|| VldEquip(oModel)}

    //--ESTRUTURA DE DADOS "FAKE" P/ CABECALHO
    oStructFake := FWFormModelStruct():New()
	oStructFake:addTable('', {'C_STRING1'}, 'Equipamentos x Produtos(SV)', {|| ''})
	oStructFake:addField('String 01', 'Campo de texto fake', 'C_STRING1', 'C', 15)

    //--GRID "PRODUTOS(SERVIÇOS)"
    oStructCNB := getStruct('CNB', 1)

    //--GRID "EQUIPAMENTOS"
    oStructSZ3 := getStruct('SZ3' , 1)
	aTrigger := FwStruTrigger('EQUIP', 'DESCR', 'SB1->B1_DESC', .T., 'SB1', 1, 'xFilial("SB1")+M->EQUIP')
	oStructSZ3:AddTrigger(aTrigger[1], aTrigger[2], aTrigger[3], aTrigger[4])


    // --------------------------------------------------
	// CRIA MODEL
	// --------------------------------------------------
	oModel := MPFormModel():New('A020MDL',,, bCommit)
	oModel:SetDescription('Equipamentos x Produtos')

    //--CABECALHO "FAKE"
	oModel:addFields('CABID',, oStructFake,,, {|oMdl| {""}})
	oModel:getModel('CABID'):setOnlyQuery(.T.)

    //--GRID "PRODUTOS(SERVIÇOS)"
	oModel:addGrid('CNBDETAIL', 'CABID', oStructCNB)
	oModel:getModel('CNBDETAIL'):setOnlyQuery(.T.)
	oModel:getModel('CNBDETAIL'):setOptional(.T.)
	oModel:getModel('CNBDETAIL'):setDescription('Produtos(Serviços)')

    //--GRID "EQUIPAMENTOS"
    oModel:addGrid('SZ3DETAIL', 'CNBDETAIL', oStructSZ3,, bLinePos)
	oModel:getModel('SZ3DETAIL'):setOnlyQuery(.T.)
	oModel:getModel('SZ3DETAIL'):setOptional(.T.)
	oModel:getModel('SZ3DETAIL'):setDescription('Equipamentos')

    oModel:setActivate({|oModel| Processa({|| loadData(oModel)}, 'Aguarde...', 'Carregando dados...')})

Return(oModel)

/*/
---------------------------------------------------------------------------
{Protheus.doc} ViewDef
DEFINICAO DA VIEW
@author  DS2U (DN)
@since   abr.2021
@version 1.0
@type    function
---------------------------------------------------------------------------
/*/

Static Function ViewDef()
    Local oView       := NIL
    Local oModel      := ModelDef()
	Local oStructFake := NIL
	Local oStructCNB  := NIL
    Local oStructSZ3  := NIL

    // --------------------------------------------------
	// ESTRUTURA DE DADOS
	// --------------------------------------------------

	//--ESTRUTURA DE DADOS "FAKE" P/ CABECALHO
	oStructFake := FWFormViewStruct():New()
	oStructFake:addField("C_STRING1", "01" , "String 01", "Campo de texto", , "C" )

	//--GRID "SERVICOS"
	oStructCNB := getStruct('CNB', 2)

    //--GRID "EQUIPAMENTOS"
    oStructSZ3 := getStruct('SZ3', 2)
	oStructSZ3:removeField('FILSZ3')
	oStructSZ3:removeField('CLIENTE')
	oStructSZ3:removeField('LOJA')
    
    // --------------------------------------------------
	// CRIA VIEW
	// --------------------------------------------------
	oView := FWFormView():New()
	oView:SetModel(oModel)

    oView:CreateHorizontalBox('TOHIDE'  , 00)
	oView:CreateHorizontalBox('SPACE'   , 02)
	oView:CreateHorizontalBox('GRIDCNB' , 40)
	oView:CreateHorizontalBox('SPACE'   , 02)
	oView:CreateHorizontalBox('BUTTON'  , 12)
	oView:CreateHorizontalBox('SPACE'   , 02)
    oView:CreateHorizontalBox('GRIDSZ3' , 40)


    //-- CABECALHO
	oView:addField('CABEC', oStructFake, 'CABID')
	oView:setOwnerView('CABEC', 'TOHIDE')

    //--GRID "ATENDENTES"
	oView:addGrid('GRID_CNB', oStructCNB, 'CNBDETAIL')
	oView:SetOwnerView('GRID_CNB', 'GRIDCNB')
	oView:EnableTitleView('GRID_CNB', oModel:GetModel('CNBDETAIL'):GetDescription())
	oView:setNoInsertLine('CNBDETAIL')
	oView:setNoDeleteLine('CNBDETAIL')

    //--GRID "DADOS EQUIPAMENTOS"
    oView:addGrid('GRID_SZ3', oStructSZ3, 'SZ3DETAIL')
	oView:SetOwnerView('GRID_SZ3', 'GRIDSZ3')
	oView:EnableTitleView('GRID_SZ3', oModel:GetModel('SZ3DETAIL'):GetDescription())
	oView:setNoInsertLine('SZ3DETAIL')
	oView:setNoDeleteLine('SZ3DETAIL')

	oView:AddIncrementField('GRID_SZ3', 'ITEM')

    oView:SetCloseOnOk({|| .T.})

Return(oView)

/*/
---------------------------------------------------------------------------
{Protheus.doc} loadData()
CARREGA DADOS DO MODELO

@author  DS2U (DN)
@since   JUL.2025
@version 1.0
@type    function
---------------------------------------------------------------------------
/*/
Static Function loadData(oModel)
	Local oGridCNB  := oModel:getModel('CNBDETAIL')
    Local oGridSZ3  := oModel:getModel('SZ3DETAIL')
	Local cContra 	:= CN9->CN9_NUMERO
	Local cSituac   := CN9->CN9_SITUAC
	Local cQuebra 	:= ''
	Local cAliasQry := ''
	Local lAddCNB   := .F.
	Local lAddSZ3 	:= .F.
	Local lRet      := .T.
	Local nTotReg   := 0


    cAliasQry := getNextAlias()
	BeginSQL Alias cAliasQry
        SELECT CN9.CN9_FILIAL, CN9.CN9_NUMERO, CN9.CN9_REVISA, CNA.CNA_NUMERO, CNA.CNA_CLIENT, CNA.CNA_LOJACL, CNB.CNB_ITEM, CNB.CNB_PRODUT, 
			   CNB.CNB_DESCRI, SZ3.Z3_FILIAL, SZ3.Z3_ITEM, SZ3.Z3_PRODUTO, SZ3.Z3_QUANT, SZ3.Z3_QTDALC, SZ3.Z3_CLIENTE, SZ3.Z3_LOJA, SB1.B1_DESC

          FROM %Table:CN9% CN9

          JOIN %Table:CNA% CNA
            ON CNA.CNA_FILIAL = CN9.CN9_FILIAL
           AND CNA.CNA_CONTRA = CN9.CN9_NUMERO
           AND CNA.CNA_REVISA = CN9.CN9_REVISA
           AND CNA.%NotDel%

		  LEFT JOIN %Table:SZ3% SZ3
			ON SZ3.Z3_FILIAL = %xFilial:SZ3%
		   AND SZ3.Z3_CONTRAT = %Exp:cContra%
		   AND SZ3.Z3_PLANI = CNA.CNA_NUMERO
		   AND SZ3.%NotDel%

		  LEFT JOIN %Table:SB1% SB1
		    ON SB1.B1_FILIAL = %xFilial:SB1%
		   AND SB1.B1_COD = SZ3.Z3_PRODUTO
		   AND SB1.%NotDel%	 

          JOIN %Table:CNB% CNB
            ON CNB.CNB_FILIAL = CNA.CNA_FILIAL
           AND CNB.CNB_CONTRA = CNA.CNA_CONTRA
           AND CNB.CNB_NUMERO = CNA.CNA_NUMERO
           AND CNB.CNB_REVISA = CNA.CNA_REVISA
		   AND CNB.CNB_VINEQP = '1'
           AND CNB.%NotDel%	   

		 WHERE CN9.CN9_FILIAL = %xFilial:CN9%
		   AND CN9.CN9_NUMERO = %Exp:cContra%
		   AND CN9.%NotDel%

		   ORDER BY CNA.CNA_NUMERO, SZ3.Z3_ITEM

    EndSQL


    If !(cAliasQry)->(Eof())
        // --------------------------------------------------
		// CARREGA GRID COM OS PRODUTOS(SERVIÇOS)
		// --------------------------------------------------

        //--"DESTRAVA" EDICAO NOS GRIDS
		oGridCNB:setNoInsertLine(.F.)
		oGridCNB:setNoDeleteLine(.F.)

		oGridSZ3:SetNoInsertLine(.F.)
		oGridSZ3:setNoDeleteLine(.F.)

        nTotReg := Contar(cAliasQry, '!Eof()')
        ProcRegua(nTotReg)

        (cAliasQry)->(dbGoTop())
		While !(cAliasQry)->(Eof())
			If lAddCNB
				oGridCNB:addLine()
				lAddCNB := .F.
			Else
				lAddCNB := .T.
			EndIf
			oGridCNB:loadValue('CN9_FILIAL' , (cAliasQry)->CN9_FILIAL)
            oGridCNB:loadValue('CN9_NUMERO' , (cAliasQry)->CN9_NUMERO)
			oGridCNB:loadValue('CN9_REVISA' , (cAliasQry)->CN9_REVISA)
			oGridCNB:loadValue('CNA_NUMERO' , (cAliasQry)->CNA_NUMERO)
			oGridCNB:loadValue('CNA_CLIENT' , (cAliasQry)->CNA_CLIENT)
			oGridCNB:loadValue('CNA_LOJACL' , (cAliasQry)->CNA_LOJACL)
			oGridCNB:loadValue('CNB_ITEM'   , (cAliasQry)->CNB_ITEM)
			oGridCNB:loadValue('CNB_PRODUT' , (cAliasQry)->CNB_PRODUT)
			oGridCNB:loadValue('CNB_DESCRI' , (cAliasQry)->CNB_DESCRI)

			cQuebra := (cAliasQry)->CNA_NUMERO

			While !(cAliasQry)->(EoF()) .and. cQuebra == (cAliasQry)->CNA_NUMERO
				If lAddSZ3
					oGridSZ3:addLine()
				Else
					lAddSZ3 := .T.
				EndIf
				oGridSZ3:loadValue('FILSZ3' , (cAliasQry)->Z3_FILIAL)
            	oGridSZ3:loadValue('ITEM'   , (cAliasQry)->Z3_ITEM)
				oGridSZ3:loadValue('EQUIP'  , (cAliasQry)->Z3_PRODUTO)
				oGridSZ3:loadValue('DESCR'  , (cAliasQry)->B1_DESC)
				oGridSZ3:loadValue('QUANT'  , (cAliasQry)->Z3_QUANT)
				oGridSZ3:loadValue('QTDALC' , (cAliasQry)->Z3_QTDALC)
				oGridSZ3:loadValue('CLIENTE', (cAliasQry)->Z3_CLIENTE)
				oGridSZ3:loadValue('LOJA'   , (cAliasQry)->Z3_LOJA)

				(cAliasQry)->(dbSkip())
            	IncProc()
				
			End

            lAddSZ3 := .F.
        End

        //--"TRAVA" EDICOES NOS GRIDS
		oGridCNB:setNoInsertLine(.T.)
		oGridCNB:setNoDeleteLine(.T.)

		If cSituac <> '02' .and. cSituac <> '09'
			MsgInfo('Não será possivel realizar alterações para um contrato que não esteja em elaboração.' + CRLF + 'Para realizar alterações mude a situação atual do contrato.', 'Atenção!')
			
			oGridSZ3:SetNoInsertLine(.T.)
			oGridSZ3:setNoDeleteLine(.T.)
			oGridSZ3:SetNoUpdateLine(.T.)
		EndIf


        oGridCNB:goLine(1)
		oGridSZ3:goLine(1)

    Else
        lRet := .F.
        oModel:GetModel():SetErrorMessage(,, oModel:GetId(),, 'OM30A020',;
            'Nao existem dados para o registro posicionado.')

    EndIf

	(cAliasQry)->(dbCloseArea())

Return(lRet)

/*/
---------------------------------------------------------------------------
{Protheus.doc} VldEqp()
VALIDA LINHAS DO GRID SZ3
@author  DS2U (DN)
@since   JUL.2025
@version 1.0
@type    function
---------------------------------------------------------------------------
/*/

Static Function VldEquip(oModel)
	Local lRet 	   := .T.
	Local oGridSZ3 := oModel:GetModel('SZ3DETAIL')
	Local nQuant   := 0

	cProduto := oGridSZ3:GetValue('EQUIP')
	nQuant 	 := oGridSZ3:GetValue('QUANT')

	If !Empty(cProduto) .AND. nQuant == 0
		Help(,, "Atenção!",, "Quantidade não pode ser igual a '0'", 1, 0,,,,,, {"Defina um valor por quantidade."})
		lRet := .F.
	EndIf

Return(lRet)

/*/
---------------------------------------------------------------------------
{Protheus.doc} grvEquip()
GRAVA OS DADOS EM UMA TABELA ESPECIFICA
@author  DS2U (DN)
@since   JUL.2025
@version 1.0
@type    function
---------------------------------------------------------------------------
/*/

Static Function grvEquip(oModel)
	Local oGridCNB   := oModel:getModel('CNBDETAIL')
	Local oGridSZ3   := oModel:getModel('SZ3DETAIL')
	Local aAreaSZ1   := SZ1->(GetArea())
	Local aAreaSZ2 	 := SZ2->(GetArea())
	Local aAreaSZ3 	 := SZ3->(GetArea())
	Local cContra 	 := ''
	Local cRevisa 	 := ''
	Local cPlani     := ''
	Local cCliente	 := ''
	Local cLojaCli 	 := ''
	Local nCountA    := 0
	Local nCountB    := 0
	Local lGrava     := .T.


	cContra  := oGridCNB:GetValue('CN9_NUMERO')
	cRevisa  := oGridCNB:GetValue('CN9_REVISA')


	Begin Transaction
		
		SZ1->(dbSetOrder(1)) //--Z1_FILIAL+Z1_CONTRAT+Z1_REVISA
		If !SZ1->(dbSeek(xFilial('SZ1')+cContra+cRevisa))
			RecLock('SZ1', .T.)
				SZ1->Z1_FILIAL  := FWxFilial('SZ1')
				SZ1->Z1_CONTRAT := cContra
				SZ1->Z1_REVISA  := cRevisa
			SZ1->(MsUnLock())
		EndIf

		For nCountA := 1 To oGridCNB:Length()
			oGridCNB:goLine(nCountA)
			cPlani := oGridCNB:GetValue('CNA_NUMERO')
			cCliente := oGridCNB:GetValue('CNA_CLIENT')
			cLojaCli := oGridCNB:GetValue('CNA_LOJACL')
			
			SZ2->(dbSetOrder(1)) //--Z2_FILIAL+Z2_CONTRAT+Z2_REVISA+Z2_PLANI
			If !SZ2->(dbSeek(xFilial('SZ2')+cContra+cRevisa+cPlani))
				RecLock('SZ2', .T.)
					SZ2->Z2_FILIAL  := FWxFilial('SZ2')
					SZ2->Z2_CONTRAT := cContra
					SZ2->Z2_REVISA  := cRevisa
					SZ2->Z2_PLANI   := cPlani
					SZ2->Z2_CLIENTE := oGridCNB:GetValue('CNA_CLIENT')
					SZ2->Z2_LOJA    := oGridCNB:GetValue('CNA_LOJACL')
					SZ2->Z2_ITEM    := oGridCNB:GetValue('CNB_ITEM')
					SZ2->Z2_PRODUTO := oGridCNB:GetValue('CNB_PRODUT')
				SZ2->(MsUnLock())
			EndIf

			For nCountB := 1 To oGridSZ3:Length()
				oGridSZ3:GoLine(nCountB)
				
				SZ3->(dbSetOrder(1)) //--Z3_FILIAL+Z3_CONTRAT+Z3_REVISA+Z3_PLANI+Z3_ITEM
				If SZ3->(dbSeek(xFilial('SZ3')+cContra+cRevisa+cPlani+oGridSZ3:GetValue('ITEM')))
					If oGridSZ3:isDeleted()
						lGrava := .F.
						recLock('SZ3', .F.)
							SZ3->(dbDelete())
						SZ3->(msUnLock())
					Else
						If oGridSZ3:GetValue('QUANT') == 0
							MsgInfo('Quantidade do equipamento não pode ser igual a 0', 'Atenção!')
							lGrava := .F.
							Exit
						Else
							lGrava := .T.
							recLock('SZ3', .F.)
						EndIf
					EndIf
				Else
					If oGridSZ3:isDeleted()
						lGrava := .F.
					Else
						If oGridSZ3:GetValue('QUANT') == 0
							MsgInfo('Quantidade do equipamento não pode ser igual a 0', 'Atenção!')
							lGrava := .F.
						Else
							lGrava := .T.
							recLock('SZ3', .T.)
						EndIf					
					EndIf				
				EndIf

				If lGrava
					SZ3->Z3_FILIAL  := FWxFilial('SZ3')
					SZ3->Z3_CONTRAT := cContra
					SZ3->Z3_REVISA  := cRevisa
					SZ3->Z3_PLANI 	:= cPlani
					SZ3->Z3_CLIENTE	:= cCliente
					SZ3->Z3_LOJA	:= cLojaCli
					SZ3->Z3_ITEM    := oGridSZ3:GetValue('ITEM')
					SZ3->Z3_PRODUTO := oGridSZ3:GetValue('EQUIP')
					SZ3->Z3_QUANT   := oGridSZ3:GetValue('QUANT')
					SZ3->Z3_QTDALC	:= oGridSZ3:GetValue('QTDALC')
					SZ3->(MsUnLock())
				EndIf

			Next nCountB

		Next nCountA

	End Transaction


	RestArea(aAreaSZ3)
	RestArea(aAreaSZ2)
	RestArea(aAreaSZ1)

Return(lGrava)

/*/
	---------------------------------------------------------------------------
	{Protheus.doc} getStruct
	RETORNA ESTRUTURA DE DADOS PARA O MODELO DE DADOS/VIEW

	@author  DS2U (VR)
	@since   abr.2021
	@version 1.0
	@type    function
	---------------------------------------------------------------------------
/*/
Static Function getStruct(cAlias, nTipo)
	Local oStructRet := NIL
	Local aCampos    := getFields(cAlias)
	Local nCountA    := 0

	If nTipo == 1 //--MODEL
		oStructRet := FWFormModelStruct():New()
		oStructRet:addTable('', {}, '')

	ElseIf nTipo == 2 //--VIEW
		oStructRet := FWFormViewStruct():New()

	EndIf

	For nCountA := 1 To Len(aCampos)
		If nTipo == 1 //--MODEL
			oStructRet:AddField( aCampos[nCountA][DEF_TITULO_DO_CAMPO],;
				aCampos[nCountA][DEF_TOOLTIP_DO_CAMPO],;
				aCampos[nCountA][DEF_IDENTIFICADOR	],;
				aCampos[nCountA][DEF_TIPO_DO_CAMPO	],;
				aCampos[nCountA][DEF_TAMANHO_DO_CAMPO],;
				aCampos[nCountA][DEF_DECIMAL_DO_CAMPO],;
				aCampos[nCountA][DEF_CODEBLOCK_VALID],;
				aCampos[nCountA][DEF_CODEBLOCK_WHEN],;
				aCampos[nCountA][DEF_LISTA_VAL],;
				aCampos[nCountA][DEF_OBRIGAT],;
				aCampos[nCountA][DEF_CODEBLOCK_INIT],;
				aCampos[nCountA][DEF_CAMPO_CHAVE],;
				aCampos[nCountA][DEF_RECEBE_VAL],;
				aCampos[nCountA][DEF_VIRTUAL],;
				aCampos[nCountA][DEF_VALID_USER])

		ElseIf nTipo == 2 //--VIEW
			oStructRet:addField( aCampos[nCountA][DEF_IDENTIFICADOR],;
				aCampos[nCountA][DEF_ORDEM],;
				aCampos[nCountA][DEF_TITULO_DO_CAMPO],;
				aCampos[nCountA][DEF_TOOLTIP_DO_CAMPO],;
				aCampos[nCountA][DEF_HELP],;
				aCampos[nCountA][DEF_TIPO_CAMPO_VIEW],;
				aCampos[nCountA][DEF_PICTURE],;
				aCampos[nCountA][DEF_PICT_VAR],;
				aCampos[nCountA][DEF_LOOKUP],;
				aCampos[nCountA][DEF_CAN_CHANGE],;
				aCampos[nCountA][DEF_ID_FOLDER],;
				aCampos[nCountA][DEF_ID_GROUP],;
				aCampos[nCountA][DEF_COMBO_VAL],;
				aCampos[nCountA][DEF_TAM_MAX_COMBO],;
				aCampos[nCountA][DEF_INIC_BROWSE],;
				aCampos[nCountA][DEF_VIRTUAL],;
				aCampos[nCountA][DEF_PICTURE_VARIAVEL],;
				aCampos[nCountA][DEF_INSERT_LINE],;
				aCampos[nCountA][DEF_WIDTH] )

		EndIf
	Next nCountA

Return(oStructRet)

/*/
---------------------------------------------------------------------------
{Protheus.doc} getFields
RETORNA CAMPOS P/ MONTAR ESTRUTURA DE DADOS DO MODEL/VIEW
@author  DS2U (VR)
@since   abr.2021
@version 1.0
@type    function
---------------------------------------------------------------------------
/*/
Static Function getFields(cAlias)
	Local aCpos    := {}
	Local aRetCpos := {}
	Local nCountA  := 0

	If cAlias == 'CNB'
		aCpos := {  'CN9_FILIAL',;
					'CN9_NUMERO',;
					'CN9_REVISA',;
					'CNA_NUMERO',;
					'CNA_CLIENT',;
					'CNA_LOJACL',;
					'CNB_ITEM',;
					'CNB_PRODUT',;
					'CNB_DESCRI'}

    ElseIf cAlias == 'SZ3'
		aAdd(aCpos, {   'FILSZ3',;                                //--[01] ID CAMPO
						'Filial',;     		  	  			      //--[02] TITULO CAMPO
						'',;      						  		  //--[03] DESCRICAO (TOOLTIP) CAMPO
						GetSX3Cache('CNB_FILIAL', 'X3_TIPO'),;    //--[04] TIPO DO CAMPO
						GetSX3Cache('CNB_FILIAL', 'X3_TAMANHO'),; //--[05] TAMANHO DO CAMPO
						GetSX3Cache('CNB_FILIAL', 'X3_DECIMAL'),; //--[06] DECIMAIS
						{|| CriaVar('CNB_FILIAL', .F.)},;    	  //--[07] INICIALIZADOR PADRAO
						GetSX3Cache('CNB_FILIAL', 'X3_PICTURE'),; //--[08] PICTURE
						GetSX3Cache('CNB_FILIAL', 'X3_TIPO'),;    //--[09] TIPO DO CAMPO "VIEW"
						.F.,;   							      //--[10] PERMITE EDICAO
						'' })        			     			  //--[11] CONSULTA (F3)


		aAdd(aCpos, {   'ITEM',;                                  //--[01] ID CAMPO
						'Item',;     		  	  			      //--[02] TITULO CAMPO
						'Item Equipamento',;      				  //--[03] DESCRICAO (TOOLTIP) CAMPO
						GetSX3Cache('CNB_ITEM', 'X3_TIPO'),;      //--[04] TIPO DO CAMPO
						GetSX3Cache('CNB_ITEM', 'X3_TAMANHO'),;   //--[05] TAMANHO DO CAMPO
						GetSX3Cache('CNB_ITEM', 'X3_DECIMAL'),;   //--[06] DECIMAIS
						{|| CriaVar('CNB_ITEM', .F.)},;    		  //--[07] INICIALIZADOR PADRAO
						GetSX3Cache('CNB_ITEM', 'X3_PICTURE'),;   //--[08] PICTURE
						GetSX3Cache('CNB_ITEM', 'X3_TIPO'),;      //--[09] TIPO DO CAMPO "VIEW"
						.F.,;   							      //--[10] PERMITE EDICAO
						'' })        			     			  //--[11] CONSULTA (F3)

        aAdd(aCpos, {   'EQUIP',;                                 //--[01] ID CAMPO
						'Cod. Equipamento',;     				  //--[02] TITULO CAMPO
						GetSX3Cache('B1_COD', 'X3_DESCRIC'),;     //--[03] DESCRICAO (TOOLTIP) CAMPO
						GetSX3Cache('B1_COD', 'X3_TIPO'),;        //--[04] TIPO DO CAMPO
						GetSX3Cache('B1_COD', 'X3_TAMANHO'),;     //--[05] TAMANHO DO CAMPO
						GetSX3Cache('B1_COD', 'X3_DECIMAL'),;     //--[06] DECIMAIS
						{|| CriaVar('B1_COD', .F.)},;             //--[07] INICIALIZADOR PADRAO
						GetSX3Cache('B1_COD', 'X3_PICTURE'),;     //--[08] PICTURE
						GetSX3Cache('B1_COD', 'X3_TIPO'),;        //--[09] TIPO DO CAMPO "VIEW"
						.T.,;								      //--[10] PERMITE EDICAO
						'SB1' })        						  //--[11] CONSULTA (F3)               

        aAdd(aCpos, {   'DESCR',;                                 //--[01] ID CAMPO
						GetSX3Cache('B1_DESC', 'X3_TITULO'),;     //--[02] TITULO CAMPO
						GetSX3Cache('B1_DESC', 'X3_DESCRIC'),;    //--[03] DESCRICAO (TOOLTIP) CAMPO
						GetSX3Cache('B1_DESC', 'X3_TIPO'),;       //--[04] TIPO DO CAMPO
						GetSX3Cache('B1_DESC', 'X3_TAMANHO'),;    //--[05] TAMANHO DO CAMPO
						GetSX3Cache('B1_DESC', 'X3_DECIMAL'),;    //--[06] DECIMAIS
						{|| CriaVar('B1_DESC', .F.)},;            //--[07] INICIALIZADOR PADRAO
						GetSX3Cache('B1_DESC', 'X3_PICTURE'),;    //--[08] PICTURE
						GetSX3Cache('B1_DESC', 'X3_TIPO'),;       //--[09] TIPO DO CAMPO "VIEW"
						.F.,;									  //--[10] PERMITE EDICAO
						'' })        						      //--[11] CONSULTA (F3)

		aAdd(aCpos, {   'QUANT',;                                 //--[01] ID CAMPO
						GetSX3Cache('B2_QATU', 'X3_TITULO'),;     //--[02] TITULO CAMPO
						GetSX3Cache('B2_QATU', 'X3_DESCRIC'),;    //--[03] DESCRICAO (TOOLTIP) CAMPO
						GetSX3Cache('B2_QATU', 'X3_TIPO'),;       //--[04] TIPO DO CAMPO
						GetSX3Cache('B2_QATU', 'X3_TAMANHO'),;    //--[05] TAMANHO DO CAMPO
						GetSX3Cache('B2_QATU', 'X3_DECIMAL'),;    //--[06] DECIMAIS
						{|| CriaVar('B2_QATU', .F.)},;            //--[07] INICIALIZADOR PADRAO
						GetSX3Cache('B2_QATU', 'X3_PICTURE'),;    //--[08] PICTURE
						GetSX3Cache('B2_QATU', 'X3_TIPO'),;       //--[09] TIPO DO CAMPO "VIEW"
						.T.,;									  //--[10] PERMITE EDICAO
						'' })        						      //--[11] CONSULTA (F3)

		aAdd(aCpos, {   'QTDALC',;                                //--[01] ID CAMPO
						GetSX3Cache('Z3_QTDALC', 'X3_TITULO'),;   //--[02] TITULO CAMPO
						GetSX3Cache('Z3_QTDALC', 'X3_DESCRIC'),;  //--[03] DESCRICAO (TOOLTIP) CAMPO
						GetSX3Cache('Z3_QTDALC', 'X3_TIPO'),;     //--[04] TIPO DO CAMPO
						GetSX3Cache('Z3_QTDALC', 'X3_TAMANHO'),;  //--[05] TAMANHO DO CAMPO
						GetSX3Cache('Z3_QTDALC', 'X3_DECIMAL'),;  //--[06] DECIMAIS
						{|| CriaVar('Z3_QTDALC', .F.)},;          //--[07] INICIALIZADOR PADRAO
						GetSX3Cache('Z3_QTDALC', 'X3_PICTURE'),;  //--[08] PICTURE
						GetSX3Cache('Z3_QTDALC', 'X3_TIPO'),;     //--[09] TIPO DO CAMPO "VIEW"
						.F.,;									  //--[10] PERMITE EDICAO
						'' })        						      //--[11] CONSULTA (F3)

		aAdd(aCpos, {   'CLIENTE',;                                //--[01] ID CAMPO
						GetSX3Cache('Z3_CLIENTE', 'X3_TITULO'),;   //--[02] TITULO CAMPO
						GetSX3Cache('Z3_CLIENTE', 'X3_DESCRIC'),;  //--[03] DESCRICAO (TOOLTIP) CAMPO
						GetSX3Cache('Z3_CLIENTE', 'X3_TIPO'),;     //--[04] TIPO DO CAMPO
						GetSX3Cache('Z3_CLIENTE', 'X3_TAMANHO'),;  //--[05] TAMANHO DO CAMPO
						GetSX3Cache('Z3_CLIENTE', 'X3_DECIMAL'),;  //--[06] DECIMAIS
						{|| CriaVar('Z3_CLIENTE', .F.)},;          //--[07] INICIALIZADOR PADRAO
						GetSX3Cache('Z3_CLIENTE', 'X3_PICTURE'),;  //--[08] PICTURE
						GetSX3Cache('Z3_CLIENTE', 'X3_TIPO'),;     //--[09] TIPO DO CAMPO "VIEW"
						.F.,;									   //--[10] PERMITE EDICAO
						'' })        						       //--[11] CONSULTA (F3)

		aAdd(aCpos, {   'LOJA',;                                //--[01] ID CAMPO
						GetSX3Cache('Z3_LOJA', 'X3_TITULO'),;   //--[02] TITULO CAMPO
						GetSX3Cache('Z3_LOJA', 'X3_DESCRIC'),;  //--[03] DESCRICAO (TOOLTIP) CAMPO
						GetSX3Cache('Z3_LOJA', 'X3_TIPO'),;     //--[04] TIPO DO CAMPO
						GetSX3Cache('Z3_LOJA', 'X3_TAMANHO'),;  //--[05] TAMANHO DO CAMPO
						GetSX3Cache('Z3_LOJA', 'X3_DECIMAL'),;  //--[06] DECIMAIS
						{|| CriaVar('Z3_LOJA', .F.)},;          //--[07] INICIALIZADOR PADRAO
						GetSX3Cache('Z3_LOJA', 'X3_PICTURE'),;  //--[08] PICTURE
						GetSX3Cache('Z3_LOJA', 'X3_TIPO'),;     //--[09] TIPO DO CAMPO "VIEW"
						.F.,;								    //--[10] PERMITE EDICAO
						'' })        					        //--[11] CONSULTA (F3)

    EndIf

    For nCountA := 1 To Len(aCpos)
		If ValType(aCpos[nCountA]) == 'C'
			aAdd(aRetCpos, Array(QUANTIDADE_DEFS))
			aTail(aRetCpos)[DEF_TITULO_DO_CAMPO]  := GetSX3Cache(aCpos[nCountA], 'X3_DESCRIC')
			aTail(aRetCpos)[DEF_TOOLTIP_DO_CAMPO] := GetSX3Cache(aCpos[nCountA], 'X3_DESCRIC')
			aTail(aRetCpos)[DEF_IDENTIFICADOR]    := aCpos[nCountA]
			aTail(aRetCpos)[DEF_TIPO_DO_CAMPO]    := GetSX3Cache(aCpos[nCountA], 'X3_TIPO')
			aTail(aRetCpos)[DEF_TIPO_CAMPO_VIEW]  := GetSX3Cache(aCpos[nCountA], 'X3_TIPO')
			aTail(aRetCpos)[DEF_TAMANHO_DO_CAMPO] := GetSX3Cache(aCpos[nCountA], 'X3_TAMANHO')
			aTail(aRetCpos)[DEF_DECIMAL_DO_CAMPO] := GetSX3Cache(aCpos[nCountA], 'X3_DECIMAL')
			aTail(aRetCpos)[DEF_CODEBLOCK_WHEN]   := {|| .F.}
			aTail(aRetCpos)[DEF_OBRIGAT]          := .F.
			aTail(aRetCpos)[DEF_CODEBLOCK_INIT]   := &("{|| CriaVar('" + aCpos[nCountA] + "', .T.)}")
			aTail(aRetCpos)[DEF_RECEBE_VAL]       := .T.
			aTail(aRetCpos)[DEF_VIRTUAL]          := .T.
			aTail(aRetCpos)[DEF_ORDEM]            := StrZero(nCountA, 2)
			aTail(aRetCpos)[DEF_PICTURE]          := GetSX3Cache(aCpos[nCountA], 'X3_PICTURE')
			aTail(aRetCpos)[DEF_CAN_CHANGE]       := .T.
			aTail(aRetCpos)[DEF_LOOKUP] 		  := GetSX3Cache(aCpos[nCountA], 'X3_F3')

		ElseIf ValType(aCpos[nCountA]) == 'A'
			aAdd(aRetCpos, Array(QUANTIDADE_DEFS))
			aTail(aRetCpos)[DEF_TITULO_DO_CAMPO]  := aCpos[nCountA, 2]
			aTail(aRetCpos)[DEF_TOOLTIP_DO_CAMPO] := aCpos[nCountA, 3]
			aTail(aRetCpos)[DEF_IDENTIFICADOR]    := aCpos[nCountA, 1]
			aTail(aRetCpos)[DEF_TIPO_DO_CAMPO]    := aCpos[nCountA, 4]
			aTail(aRetCpos)[DEF_TIPO_CAMPO_VIEW]  := aCpos[nCountA, 9]
			aTail(aRetCpos)[DEF_TAMANHO_DO_CAMPO] := aCpos[nCountA, 5]
			aTail(aRetCpos)[DEF_DECIMAL_DO_CAMPO] := aCpos[nCountA, 6]
			aTail(aRetCpos)[DEF_CODEBLOCK_WHEN]   := {|| .T.}
			aTail(aRetCpos)[DEF_OBRIGAT]          := .F.
			aTail(aRetCpos)[DEF_CODEBLOCK_INIT]   := aCpos[nCountA, 7]
			aTail(aRetCpos)[DEF_RECEBE_VAL]       := .T.
			aTail(aRetCpos)[DEF_VIRTUAL]          := .T.
			aTail(aRetCpos)[DEF_ORDEM]            := StrZero(nCountA, 2)
			aTail(aRetCpos)[DEF_PICTURE]          := aCpos[nCountA, 8]
			aTail(aRetCpos)[DEF_CAN_CHANGE]       := aCpos[nCountA, 10]
			aTail(aRetCpos)[DEF_LOOKUP]           := aCpos[nCountA, 11]

		EndIf

	Next nCountA

Return(aRetCpos)
