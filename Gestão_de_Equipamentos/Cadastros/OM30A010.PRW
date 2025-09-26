#Include "Totvs.ch"
#Include "FWMVCDef.ch"

/* ---------------------------------------------------
Nome: OM30A010.PRW
Rotina para Gestao de Equipamentos.
@type user function
@author Douglas Sousa
@since 07/07/2025
@version version
---------------------------------------------------- */

User Function OM30A010()
    Local oBrowse

    oBrowse := FWmBrowse():New()
    oBrowse:SetAlias('SZ0')
    oBrowse:SetDescription('Gestao de Equipamentos')

    oBrowse:AddLegend("SZ0->Z0_STATUS == '0'", "BR_VERMELHO"  , "Ind/Bloq")
    oBrowse:AddLegend("SZ0->Z0_STATUS == '1'", "BR_VERDE"     , "Disponível")
    oBrowse:AddLegend("SZ0->Z0_STATUS == '2'", "BR_AMARELO"   , "Alocado")

    oBrowse:DisableDetails()

    oBrowse:Activate()
Return

//--DEFINE OS MENUS DO BROWSE
Static Function MenuDef()
    Local aRotina := {}

    ADD OPTION aRotina TITLE "Visualizar"          ACTION "VIEWDEF.OM30A010"        OPERATION 2  ACCESS 0
    ADD OPTION aRotina TITLE "Incluir"             ACTION "VIEWDEF.OM30A010"        OPERATION 3  ACCESS 0
    ADD OPTION aRotina TITLE "Alterar"             ACTION "VIEWDEF.OM30A010"        OPERATION 4  ACCESS 0
    ADD OPTION aRotina TITLE "Excluír"             ACTION "VIEWDEF.OM30A010"        OPERATION 5  ACCESS 0
    ADD OPTION aRotina TITLE "Legenda"             ACTION "U_SZ0LEG"                OPERATION 6  ACCESS 0
    ADD OPTION aRotina TITLE "Ind/Bloq"            ACTION "U_SZ0BLOQ"               OPERATION 10 ACCESS 0
    ADD OPTION aRotina TITLE "Disponivel"          ACTION "U_SZ0DISP"               OPERATION 11 ACCESS 0
    ADD OPTION aRotina TITLE "Alocado"             ACTION "U_SZ0ALOC"               OPERATION 12 ACCESS 0
Return aRotina

//--DIFINIÇÃO DO MODELO DE DADOS
Static Function ModelDef()
    Local oStruSZ0  := FWFormStruct(1, 'SZ0',,)
    Local oModel    := Nil

    oModel := MPFormModel():New('EQUIPAM',,,,)
    oModel:AddFields('SZ0MASTER', /*cOwner*/, oStruSZ0)
    oModel:SetDescription('Gestao de Equipamentos')
    oModel:GetModel('SZ0MASTER'):SetDescription('Gestao de Equipamentos')
    oModel:SetPrimaryKey({'Z0_FILIAL', 'Z0_CODIGO'})

Return oModel

//--CAMADA VISUAL DA TABELA
Static Function ViewDef()
    Local oStruSZ0  := FWFormStruct(2, 'SZ0')
    Local oModel    := FWLoadModel('OM30A010')
    Local oView     := Nil

    oView := FWFormView():New()
    oView:SetModel(oModel)
    oView:AddField('VIEW_SZ0', oStruSZ0, 'SZ0MASTER')
    oView:CreateHorizontalBox('TELA', 100)
    oView:SetOwnerView('VIEW_SZ0', 'TELA')

Return oView


/*/
--------------------------------------------------------------------------
{Protheus.doc} SZ0LEG()
LEGENDA COLORIDA DO BROWSE INDICANDO O STATUS
@type user function
@author Douglas Sousa
@since 07/07/2025
@version version
--------------------------------------------------------------------------
/*/
User Function SZ0LEG()
    Local aLegenda  := {}

    aAdd(aLegenda, {"BR_VERMELHO"  , "Ind/Bloq"})
    aAdd(aLegenda, {"BR_VERDE"     , "Disponível"})
    aAdd(aLegenda, {"BR_AMARELO"   , "Alocado"})

    BrwLegenda("Status", "Patrimonios", aLegenda)

Return(aLegenda)

/*/
-----------------------------------------------------------------------------------
{Protheus.doc} SZ0DISP()
Define Status para Disponível

@type user function
@author DN
@since 16/07/2025
@version version
-----------------------------------------------------------------------------------
/*/

User Function SZ0DISP()
    Local aArea     := GetArea()
    Local lRet      := .T.
    Local lConfirma := .F.
    Local cStatus   := SZ0->Z0_STATUS

    lConfirma := MsgYesNo("Deseja tornar disponível o patrimônio selecionado: " + SZ0->Z0_CODPATR + "?", "Atenção!")

    If lConfirma .and. cStatus == '1'
        Alert("O Patrimônio: " + SZ0->Z0_CODPATR + " já se encontra disponível, verifique se está posicionado no patrimonio correto!")
        lRet := .F.
    
    Else
        If lConfirma .and. cStatus <> '1'
            RecLock('SZ0', .F.)
                SZ0->Z0_STATUS  := '1'
            SZ0->(MsUnlock())
        EndIf
    EndIf

    RestArea(aArea)
Return(lRet)

/*/
-----------------------------------------------------------------------------------
{Protheus.doc} SZ0BLOQ()
Define Status para Indisponível/Bloqueado

@type user function
@author DN
@since 16/07/2025
@version version
-----------------------------------------------------------------------------------
/*/

User Function SZ0BLOQ()
    Local aArea     := GetArea()
    Local lRet      := .T.
    Local lConfirma := .F.
    Local cStatus   := SZ0->Z0_STATUS

    lConfirma := MsgYesNo("Deseja tornar Indisponível/Bloqueado o patrimônio selecionado: " + SZ0->Z0_CODPATR + "?", "Atenção!")

    If lConfirma .and. cStatus == '0'
        Alert("O Patrimônio: " + SZ0->Z0_CODPATR + " já está indisponível/Bloqueado, verifique se está posicionado no patrimonio correto!")
        lRet := .F.
    
    Else
        If lConfirma .and. cStatus <> '0'
            RecLock('SZ0', .F.)
                SZ0->Z0_STATUS  := '0'
            SZ0->(MsUnlock())
        EndIf
    EndIf

    RestArea(aArea)
Return(lRet)

/*/
-----------------------------------------------------------------------------------
{Protheus.doc} SZ0ALOC()
Define Status para Alocado

@type user function
@author DN
@since Set.2025
@version version
-----------------------------------------------------------------------------------
/*/
User Function SZ0ALOC()
    Local aArea     := GetArea()
    Local lRet      := .T.
    Local lConfirma := .F.
    Local cStatus   := SZ0->Z0_STATUS

    lConfirma := MsgYesNo("Deseja tornar Alocado o patrimônio selecionado: " + SZ0->Z0_CODPATR + "?", "Atenção!")

    If lConfirma .and. cStatus == '2'
        Alert("O Patrimônio: " + SZ0->Z0_CODPATR + " já se econtra Alocado, verifique se está posicionado no patrimonio correto!")
        lRet := .F.
    
    Else
        If lConfirma .and. cStatus <> '2'
            RecLock('SZ0', .F.)
                SZ0->Z0_STATUS  := '2'
            SZ0->(MsUnlock())
        EndIf
    EndIf

    RestArea(aArea)
Return(lRet)
