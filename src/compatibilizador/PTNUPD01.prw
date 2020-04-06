#INCLUDE "PROTHEUS.CH"

#DEFINE SIMPLES Char( 39 )
#DEFINE DUPLAS  Char( 34 )

#DEFINE CSSBOTAO	"QPushButton { color: #024670; "+;
  "    border-image: url(rpo:fwstd_btn_nml.png) 3 3 3 3 stretch; "+;
  "    border-top-width: 3px; "+;
  "    border-left-width: 3px; "+;
  "    border-right-width: 3px; "+;
  "    border-bottom-width: 3px }"+;
  "QPushButton:pressed {	color: #FFFFFF; "+;
  "    border-image: url(rpo:fwstd_btn_prd.png) 3 3 3 3 stretch; "+;
  "    border-top-width: 3px; "+;
  "    border-left-width: 3px; "+;
  "    border-right-width: 3px; "+;
  "    border-bottom-width: 3px }"

//--------------------------------------------------------------------
/*/{Protheus.doc} PTNUPD01
Função de update de dicionários para compatibilização

@author TOTVS Protheus
@since  06/04/2020
@obs    Gerado por EXPORDIC - V.6.3.0.1 EFS / Upd. V.5.0.0 EFS
@version 1.0
/*/
//--------------------------------------------------------------------
User Function PTNUPD01( cEmpAmb, cFilAmb )

  Local   aSay      := {}
  Local   aButton   := {}
  Local   aMarcadas := {}
  Local   cTitulo   := "ATUALIZAÇÃO DE DICIONÁRIOS E TABELAS"
  Local   cDesc1    := "Esta rotina tem como função fazer  a atualização  dos dicionários do Sistema ( SX?/SIX )"
  Local   cDesc2    := "Este processo deve ser executado em modo EXCLUSIVO, ou seja não podem haver outros"
  Local   cDesc3    := "usuários  ou  jobs utilizando  o sistema.  É EXTREMAMENTE recomendavél  que  se  faça um"
  Local   cDesc4    := "BACKUP  dos DICIONÁRIOS  e da  BASE DE DADOS antes desta atualização, para que caso "
  Local   cDesc5    := "ocorram eventuais falhas, esse backup possa ser restaurado."
  Local   cDesc6    := ""
  Local   cDesc7    := ""
  Local   cMsg      := ""
  Local   lOk       := .F.
  Local   lAuto     := ( cEmpAmb <> NIL .or. cFilAmb <> NIL )

  Private oMainWnd  := NIL
  Private oProcess  := NIL

  #IFDEF TOP
    TCInternal( 5, "*OFF" ) // Desliga Refresh no Lock do Top
  #ENDIF

  __cInterNet := NIL
  __lPYME     := .F.

  Set Dele On

// Mensagens de Tela Inicial
  aAdd( aSay, cDesc1 )
  aAdd( aSay, cDesc2 )
  aAdd( aSay, cDesc3 )
  aAdd( aSay, cDesc4 )
  aAdd( aSay, cDesc5 )
//aAdd( aSay, cDesc6 )
//aAdd( aSay, cDesc7 )

// Botoes Tela Inicial
  aAdd(  aButton, {  1, .T., { || lOk := .T., FechaBatch() } } )
  aAdd(  aButton, {  2, .T., { || lOk := .F., FechaBatch() } } )

  If lAuto
    lOk := .T.
  Else
    FormBatch(  cTitulo,  aSay,  aButton )
  EndIf

  If lOk

    If FindFunction( "MPDicInDB" ) .AND. MPDicInDB()
      cMsg := "Este update NÃO PODE ser executado neste Ambiente." + CRLF + CRLF + ;
        "Os arquivos de dicionários se encontram no Banco de Dados e este update está preparado " + ;
        "para atualizar apenas ambientes com dicionários no formato ISAM (.dbf ou .dtc)."

      If lAuto
        AutoGrLog( Replicate( "-", 128 ) )
        AutoGrLog( Replicate( " ", 128 ) )
        AutoGrLog( "LOG DA ATUALIZAÇÃO DOS DICIONÁRIOS" )
        AutoGrLog( Replicate( " ", 128 ) )
        AutoGrLog( Replicate( "-", 128 ) )
        AutoGrLog( Replicate( " ", 128 ) )
        AutoGrLog( cMsg )
        ConOut( DToC(Date()) + "|" + Time() + cMsg )
      Else
        MsgInfo( cMsg )
      EndIf

      Return NIL
    EndIf

    If lAuto
      aMarcadas :={{ cEmpAmb, cFilAmb, "" }}
    Else

      aMarcadas := EscEmpresa()
    EndIf

    If !Empty( aMarcadas )
      If lAuto .OR. MsgNoYes( "Confirma a atualização dos dicionários ?", cTitulo )
        oProcess := MsNewProcess():New( { | lEnd | lOk := FSTProc( @lEnd, aMarcadas, lAuto ) }, "Atualizando", "Aguarde, atualizando ...", .F. )
        oProcess:Activate()

        If lAuto
          If lOk
            MsgStop( "Atualização Realizada.", "PTNUPD01" )
          Else
            MsgStop( "Atualização não Realizada.", "PTNUPD01" )
          EndIf
          dbCloseAll()
        Else
          If lOk
            Final( "Atualização Realizada." )
          Else
            Final( "Atualização não Realizada." )
          EndIf
        EndIf

      Else
        Final( "Atualização não Realizada." )

      EndIf

    Else
      Final( "Atualização não Realizada." )

    EndIf

  EndIf

Return NIL


//--------------------------------------------------------------------
/*/{Protheus.doc} FSTProc
Função de processamento da gravação dos arquivos

@author TOTVS Protheus
@since  06/04/2020
@obs    Gerado por EXPORDIC - V.6.3.0.1 EFS / Upd. V.5.0.0 EFS
@version 1.0
/*/
//--------------------------------------------------------------------
Static Function FSTProc( lEnd, aMarcadas, lAuto )
  Local   aInfo     := {}
  Local   aRecnoSM0 := {}
  Local   cAux      := ""
  Local   cFile     := ""
  Local   cFileLog  := ""
  Local   cMask     := "Arquivos Texto" + "(*.TXT)|*.txt|"
  Local   cTCBuild  := "TCGetBuild"
  Local   cTexto    := ""
  Local   cTopBuild := ""
  Local   lOpen     := .F.
  Local   lRet      := .T.
  Local   nI        := 0
  Local   nPos      := 0
  Local   nRecno    := 0
  Local   nX        := 0
  Local   oDlg      := NIL
  Local   oFont     := NIL
  Local   oMemo     := NIL

  Private aArqUpd   := {}

  If ( lOpen := MyOpenSm0(.T.) )

    dbSelectArea( "SM0" )
    dbGoTop()

    While !SM0->( EOF() )
      // Só adiciona no aRecnoSM0 se a empresa for diferente
      If aScan( aRecnoSM0, { |x| x[2] == SM0->M0_CODIGO } ) == 0 ;
          .AND. aScan( aMarcadas, { |x| x[1] == SM0->M0_CODIGO } ) > 0
        aAdd( aRecnoSM0, { Recno(), SM0->M0_CODIGO } )
      EndIf
      SM0->( dbSkip() )
    End

    SM0->( dbCloseArea() )

    If lOpen

      For nI := 1 To Len( aRecnoSM0 )

        If !( lOpen := MyOpenSm0(.F.) )
          MsgStop( "Atualização da empresa " + aRecnoSM0[nI][2] + " não efetuada." )
          Exit
        EndIf

        SM0->( dbGoTo( aRecnoSM0[nI][1] ) )

        RpcSetType( 3 )
        RpcSetEnv( SM0->M0_CODIGO, SM0->M0_CODFIL )

        lMsFinalAuto := .F.
        lMsHelpAuto  := .F.

        AutoGrLog( Replicate( "-", 128 ) )
        AutoGrLog( Replicate( " ", 128 ) )
        AutoGrLog( "LOG DA ATUALIZAÇÃO DOS DICIONÁRIOS" )
        AutoGrLog( Replicate( " ", 128 ) )
        AutoGrLog( Replicate( "-", 128 ) )
        AutoGrLog( " " )
        AutoGrLog( " Dados Ambiente" )
        AutoGrLog( " --------------------" )
        AutoGrLog( " Empresa / Filial...: " + cEmpAnt + "/" + cFilAnt )
        AutoGrLog( " Nome Empresa.......: " + Capital( AllTrim( GetAdvFVal( "SM0", "M0_NOMECOM", cEmpAnt + cFilAnt, 1, "" ) ) ) )
        AutoGrLog( " Nome Filial........: " + Capital( AllTrim( GetAdvFVal( "SM0", "M0_FILIAL" , cEmpAnt + cFilAnt, 1, "" ) ) ) )
        AutoGrLog( " DataBase...........: " + DtoC( dDataBase ) )
        AutoGrLog( " Data / Hora Ínicio.: " + DtoC( Date() )  + " / " + Time() )
        AutoGrLog( " Environment........: " + GetEnvServer()  )
        AutoGrLog( " StartPath..........: " + GetSrvProfString( "StartPath", "" ) )
        AutoGrLog( " RootPath...........: " + GetSrvProfString( "RootPath" , "" ) )
        AutoGrLog( " Versão.............: " + GetVersao(.T.) )
        AutoGrLog( " Usuário TOTVS .....: " + __cUserId + " " +  cUserName )
        AutoGrLog( " Computer Name......: " + GetComputerName() )

        aInfo   := GetUserInfo()
        If ( nPos    := aScan( aInfo,{ |x,y| x[3] == ThreadId() } ) ) > 0
          AutoGrLog( " " )
          AutoGrLog( " Dados Thread" )
          AutoGrLog( " --------------------" )
          AutoGrLog( " Usuário da Rede....: " + aInfo[nPos][1] )
          AutoGrLog( " Estação............: " + aInfo[nPos][2] )
          AutoGrLog( " Programa Inicial...: " + aInfo[nPos][5] )
          AutoGrLog( " Environment........: " + aInfo[nPos][6] )
          AutoGrLog( " Conexão............: " + AllTrim( StrTran( StrTran( aInfo[nPos][7], Chr( 13 ), "" ), Chr( 10 ), "" ) ) )
        EndIf
        AutoGrLog( Replicate( "-", 128 ) )
        AutoGrLog( " " )

        If !lAuto
          AutoGrLog( Replicate( "-", 128 ) )
          AutoGrLog( "Empresa : " + SM0->M0_CODIGO + "/" + SM0->M0_NOME + CRLF )
        EndIf

        oProcess:SetRegua1( 8 )

        //------------------------------------
        // Atualiza o dicionário SX2
        //------------------------------------
        oProcess:IncRegua1( "Dicionário de arquivos" + " - " + SM0->M0_CODIGO + " " + SM0->M0_NOME + " ..." )
        FSAtuSX2()

        //------------------------------------
        // Atualiza o dicionário SX3
        //------------------------------------
        FSAtuSX3()

        //------------------------------------
        // Atualiza o dicionário SIX
        //------------------------------------
        oProcess:IncRegua1( "Dicionário de índices" + " - " + SM0->M0_CODIGO + " " + SM0->M0_NOME + " ..." )
        FSAtuSIX()

        oProcess:IncRegua1( "Dicionário de dados" + " - " + SM0->M0_CODIGO + " " + SM0->M0_NOME + " ..." )
        oProcess:IncRegua2( "Atualizando campos/índices" )

        // Alteração física dos arquivos
        __SetX31Mode( .F. )

        If FindFunction(cTCBuild)
          cTopBuild := &cTCBuild.()
        EndIf

        For nX := 1 To Len( aArqUpd )

          If cTopBuild >= "20090811" .AND. TcInternal( 89 ) == "CLOB_SUPPORTED"
            If ( ( aArqUpd[nX] >= "NQ " .AND. aArqUpd[nX] <= "NZZ" ) .OR. ( aArqUpd[nX] >= "O0 " .AND. aArqUpd[nX] <= "NZZ" ) ) .AND.;
                !aArqUpd[nX] $ "NQD,NQF,NQP,NQT"
              TcInternal( 25, "CLOB" )
            EndIf
          EndIf

          If Select( aArqUpd[nX] ) > 0
            dbSelectArea( aArqUpd[nX] )
            dbCloseArea()
          EndIf

          X31UpdTable( aArqUpd[nX] )

          If __GetX31Error()
            Alert( __GetX31Trace() )
            MsgStop( "Ocorreu um erro desconhecido durante a atualização da tabela : " + aArqUpd[nX] + ". Verifique a integridade do dicionário e da tabela.", "ATENÇÃO" )
            AutoGrLog( "Ocorreu um erro desconhecido durante a atualização da estrutura da tabela : " + aArqUpd[nX] )
          EndIf

          If cTopBuild >= "20090811" .AND. TcInternal( 89 ) == "CLOB_SUPPORTED"
            TcInternal( 25, "OFF" )
          EndIf

        Next nX

        AutoGrLog( Replicate( "-", 128 ) )
        AutoGrLog( " Data / Hora Final.: " + DtoC( Date() ) + " / " + Time() )
        AutoGrLog( Replicate( "-", 128 ) )

        RpcClearEnv()

      Next nI

      If !lAuto

        cTexto := LeLog()

        Define Font oFont Name "Mono AS" Size 5, 12

        Define MsDialog oDlg Title "Atualização concluida." From 3, 0 to 340, 417 Pixel

        @ 5, 5 Get oMemo Var cTexto Memo Size 200, 145 Of oDlg Pixel
        oMemo:bRClicked := { || AllwaysTrue() }
        oMemo:oFont     := oFont

        Define SButton From 153, 175 Type  1 Action oDlg:End() Enable Of oDlg Pixel // Apaga
        Define SButton From 153, 145 Type 13 Action ( cFile := cGetFile( cMask, "" ), If( cFile == "", .T., ;
          MemoWrite( cFile, cTexto ) ) ) Enable Of oDlg Pixel

        Activate MsDialog oDlg Center

      EndIf

    EndIf

  Else

    lRet := .F.

  EndIf

Return lRet


//--------------------------------------------------------------------
/*/{Protheus.doc} FSAtuSX2
Função de processamento da gravação do SX2 - Arquivos

@author TOTVS Protheus
@since  06/04/2020
@obs    Gerado por EXPORDIC - V.6.3.0.1 EFS / Upd. V.5.0.0 EFS
@version 1.0
/*/
//--------------------------------------------------------------------
Static Function FSAtuSX2()
  Local aEstrut   := {}
  Local aSX2      := {}
  Local cAlias    := ""
  Local cCpoUpd   := "X2_ROTINA /X2_UNICO  /X2_DISPLAY/X2_SYSOBJ /X2_USROBJ /X2_POSLGT /"
  Local cEmpr     := ""
  Local cPath     := ""
  Local nI        := 0
  Local nJ        := 0

  AutoGrLog( "Ínicio da Atualização" + " SX2" + CRLF )

  aEstrut := { "X2_CHAVE"  , "X2_PATH"   , "X2_ARQUIVO", "X2_NOME"   , "X2_NOMESPA", "X2_NOMEENG", "X2_MODO"   , ;
    "X2_TTS"    , "X2_ROTINA" , "X2_PYME"   , "X2_UNICO"  , "X2_DISPLAY", "X2_SYSOBJ" , "X2_USROBJ" , ;
    "X2_POSLGT" , "X2_CLOB"   , "X2_AUTREC" , "X2_MODOEMP", "X2_MODOUN" , "X2_MODULO" }


  dbSelectArea( "SX2" )
  SX2->( dbSetOrder( 1 ) )
  SX2->( dbGoTop() )
  cPath := SX2->X2_PATH
  cPath := IIf( Right( AllTrim( cPath ), 1 ) <> "\", PadR( AllTrim( cPath ) + "\", Len( cPath ) ), cPath )
  cEmpr := Substr( SX2->X2_ARQUIVO, 4 )

//
// Tabela Z20
//
  aAdd( aSX2, { ;
    'Z20'																	, ; //X2_CHAVE
  cPath																	, ; //X2_PATH
  'Z20'+cEmpr																, ; //X2_ARQUIVO
  'CONTROLE DE USUARIOS'													, ; //X2_NOME
  'CONTROLE DE USUARIOS'													, ; //X2_NOMESPA
  'CONTROLE DE USUARIOS'													, ; //X2_NOMEENG
  'C'																		, ; //X2_MODO
  ''																		, ; //X2_TTS
  ''																		, ; //X2_ROTINA
  ''																		, ; //X2_PYME
  ''																		, ; //X2_UNICO
  ''																		, ; //X2_DISPLAY
  ''																		, ; //X2_SYSOBJ
  ''																		, ; //X2_USROBJ
  ''																		, ; //X2_POSLGT
  ''																		, ; //X2_CLOB
  ''																		, ; //X2_AUTREC
  'C'																		, ; //X2_MODOEMP
  'C'																		, ; //X2_MODOUN
  0																		} ) //X2_MODULO

//
// Tabela Z21
//
  aAdd( aSX2, { ;
    'Z21'																	, ; //X2_CHAVE
  cPath																	, ; //X2_PATH
  'Z21'+cEmpr																, ; //X2_ARQUIVO
  'CONTROLE DE AUTENTICACAO TOKEN'										, ; //X2_NOME
  'CONTROLE DE AUTENTICACAO TOKEN'										, ; //X2_NOMESPA
  'CONTROLE DE AUTENTICACAO TOKEN'										, ; //X2_NOMEENG
  'C'																		, ; //X2_MODO
  ''																		, ; //X2_TTS
  ''																		, ; //X2_ROTINA
  ''																		, ; //X2_PYME
  ''																		, ; //X2_UNICO
  ''																		, ; //X2_DISPLAY
  ''																		, ; //X2_SYSOBJ
  ''																		, ; //X2_USROBJ
  ''																		, ; //X2_POSLGT
  ''																		, ; //X2_CLOB
  ''																		, ; //X2_AUTREC
  'C'																		, ; //X2_MODOEMP
  'C'																		, ; //X2_MODOUN
  0																		} ) //X2_MODULO

//
// Atualizando dicionário
//
  oProcess:SetRegua2( Len( aSX2 ) )

  dbSelectArea( "SX2" )
  dbSetOrder( 1 )

  For nI := 1 To Len( aSX2 )

    oProcess:IncRegua2( "Atualizando Arquivos (SX2)..." )

    If !SX2->( dbSeek( aSX2[nI][1] ) )

      If !( aSX2[nI][1] $ cAlias )
        cAlias += aSX2[nI][1] + "/"
        AutoGrLog( "Foi incluída a tabela " + aSX2[nI][1] )
      EndIf

      RecLock( "SX2", .T. )
      For nJ := 1 To Len( aSX2[nI] )
        If FieldPos( aEstrut[nJ] ) > 0
          If AllTrim( aEstrut[nJ] ) == "X2_ARQUIVO"
            FieldPut( FieldPos( aEstrut[nJ] ), SubStr( aSX2[nI][nJ], 1, 3 ) + cEmpAnt +  "0" )
          Else
            FieldPut( FieldPos( aEstrut[nJ] ), aSX2[nI][nJ] )
          EndIf
        EndIf
      Next nJ
      MsUnLock()

    Else

      If  !( StrTran( Upper( AllTrim( SX2->X2_UNICO ) ), " ", "" ) == StrTran( Upper( AllTrim( aSX2[nI][12]  ) ), " ", "" ) )
        RecLock( "SX2", .F. )
        SX2->X2_UNICO := aSX2[nI][12]
        MsUnlock()

        If MSFILE( RetSqlName( aSX2[nI][1] ),RetSqlName( aSX2[nI][1] ) + "_UNQ"  )
          TcInternal( 60, RetSqlName( aSX2[nI][1] ) + "|" + RetSqlName( aSX2[nI][1] ) + "_UNQ" )
        EndIf

        AutoGrLog( "Foi alterada a chave única da tabela " + aSX2[nI][1] )
      EndIf

      RecLock( "SX2", .F. )
      For nJ := 1 To Len( aSX2[nI] )
        If FieldPos( aEstrut[nJ] ) > 0
          If PadR( aEstrut[nJ], 10 ) $ cCpoUpd
            FieldPut( FieldPos( aEstrut[nJ] ), aSX2[nI][nJ] )
          EndIf

        EndIf
      Next nJ
      MsUnLock()

    EndIf

  Next nI

  AutoGrLog( CRLF + "Final da Atualização" + " SX2" + CRLF + Replicate( "-", 128 ) + CRLF )

Return NIL


//--------------------------------------------------------------------
/*/{Protheus.doc} FSAtuSX3
Função de processamento da gravação do SX3 - Campos

@author TOTVS Protheus
@since  06/04/2020
@obs    Gerado por EXPORDIC - V.6.3.0.1 EFS / Upd. V.5.0.0 EFS
@version 1.0
/*/
//--------------------------------------------------------------------
Static Function FSAtuSX3()
  Local aEstrut   := {}
  Local aSX3      := {}
  Local cAlias    := ""
  Local cAliasAtu := ""
  Local cMsg      := ""
  Local cSeqAtu   := ""
  Local cX3Campo  := ""
  Local cX3Dado   := ""
  Local lTodosNao := .F.
  Local lTodosSim := .F.
  Local nI        := 0
  Local nJ        := 0
  Local nOpcA     := 0
  Local nPosArq   := 0
  Local nPosCpo   := 0
  Local nPosOrd   := 0
  Local nPosSXG   := 0
  Local nPosTam   := 0
  Local nPosVld   := 0
  Local nSeqAtu   := 0
  Local nTamSeek  := Len( SX3->X3_CAMPO )

  AutoGrLog( "Ínicio da Atualização" + " SX3" + CRLF )

  aEstrut := { { "X3_ARQUIVO", 0 }, { "X3_ORDEM"  , 0 }, { "X3_CAMPO"  , 0 }, { "X3_TIPO"   , 0 }, { "X3_TAMANHO", 0 }, { "X3_DECIMAL", 0 }, { "X3_TITULO" , 0 }, ;
    { "X3_TITSPA" , 0 }, { "X3_TITENG" , 0 }, { "X3_DESCRIC", 0 }, { "X3_DESCSPA", 0 }, { "X3_DESCENG", 0 }, { "X3_PICTURE", 0 }, { "X3_VALID"  , 0 }, ;
    { "X3_USADO"  , 0 }, { "X3_RELACAO", 0 }, { "X3_F3"     , 0 }, { "X3_NIVEL"  , 0 }, { "X3_RESERV" , 0 }, { "X3_CHECK"  , 0 }, { "X3_TRIGGER", 0 }, ;
    { "X3_PROPRI" , 0 }, { "X3_BROWSE" , 0 }, { "X3_VISUAL" , 0 }, { "X3_CONTEXT", 0 }, { "X3_OBRIGAT", 0 }, { "X3_VLDUSER", 0 }, { "X3_CBOX"   , 0 }, ;
    { "X3_CBOXSPA", 0 }, { "X3_CBOXENG", 0 }, { "X3_PICTVAR", 0 }, { "X3_WHEN"   , 0 }, { "X3_INIBRW" , 0 }, { "X3_GRPSXG" , 0 }, { "X3_FOLDER" , 0 }, ;
    { "X3_CONDSQL", 0 }, { "X3_CHKSQL" , 0 }, { "X3_IDXSRV" , 0 }, { "X3_ORTOGRA", 0 }, { "X3_TELA"   , 0 }, { "X3_POSLGT" , 0 }, { "X3_IDXFLD" , 0 }, ;
    { "X3_AGRUP"  , 0 }, { "X3_MODAL"  , 0 }, { "X3_PYME"   , 0 } }

  aEval( aEstrut, { |x| x[2] := SX3->( FieldPos( x[1] ) ) } )


//
// Campos Tabela Z20
//
  aAdd( aSX3, { ;
    'Z20'																	, ; //X3_ARQUIVO
  '01'																	, ; //X3_ORDEM
  'Z20_FILIAL'															, ; //X3_CAMPO
  'C'																		, ; //X3_TIPO
  2																		, ; //X3_TAMANHO
  0																		, ; //X3_DECIMAL
  'Filial'																, ; //X3_TITULO
  'Sucursal'																, ; //X3_TITSPA
  'Branch'																, ; //X3_TITENG
  'Filial do Sistema'														, ; //X3_DESCRIC
  'Sucursal'																, ; //X3_DESCSPA
  'Branch of the System'													, ; //X3_DESCENG
  '@!'																	, ; //X3_PICTURE
  ''																		, ; //X3_VALID
  Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
    Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
    Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128)					, ; //X3_USADO
  ''																		, ; //X3_RELACAO
  ''																		, ; //X3_F3
  1																		, ; //X3_NIVEL
  Chr(254) + Chr(192)														, ; //X3_RESERV
  ''																		, ; //X3_CHECK
  ''																		, ; //X3_TRIGGER
  'U'																		, ; //X3_PROPRI
  'N'																		, ; //X3_BROWSE
  ''																		, ; //X3_VISUAL
  ''																		, ; //X3_CONTEXT
  ''																		, ; //X3_OBRIGAT
  ''																		, ; //X3_VLDUSER
  ''																		, ; //X3_CBOX
  ''																		, ; //X3_CBOXSPA
  ''																		, ; //X3_CBOXENG
  ''																		, ; //X3_PICTVAR
  ''																		, ; //X3_WHEN
  ''																		, ; //X3_INIBRW
  '033'																	, ; //X3_GRPSXG
  ''																		, ; //X3_FOLDER
  ''																		, ; //X3_CONDSQL
  ''																		, ; //X3_CHKSQL
  ''																		, ; //X3_IDXSRV
  ''																		, ; //X3_ORTOGRA
  ''																		, ; //X3_TELA
  ''																		, ; //X3_POSLGT
  ''																		, ; //X3_IDXFLD
  ''																		, ; //X3_AGRUP
  ''																		, ; //X3_MODAL
  ''																		} ) //X3_PYME

  aAdd( aSX3, { ;
    'Z20'																	, ; //X3_ARQUIVO
  '02'																	, ; //X3_ORDEM
  'Z20_CODROT'															, ; //X3_CAMPO
  'C'																		, ; //X3_TIPO
  6																		, ; //X3_TAMANHO
  0																		, ; //X3_DECIMAL
  'Cod Rotina'															, ; //X3_TITULO
  'Cod Rotina'															, ; //X3_TITSPA
  'Cod Rotina'															, ; //X3_TITENG
  'Cod Rotina'															, ; //X3_DESCRIC
  'Cod Rotina'															, ; //X3_DESCSPA
  'Cod Rotina'															, ; //X3_DESCENG
  '@!'																	, ; //X3_PICTURE
  ''																		, ; //X3_VALID
  Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
    Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
    Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, ; //X3_USADO
  ''																		, ; //X3_RELACAO
  ''																		, ; //X3_F3
  0																		, ; //X3_NIVEL
  Chr(254) + Chr(192)														, ; //X3_RESERV
  ''																		, ; //X3_CHECK
  ''																		, ; //X3_TRIGGER
  'U'																		, ; //X3_PROPRI
  'S'																		, ; //X3_BROWSE
  'A'																		, ; //X3_VISUAL
  'R'																		, ; //X3_CONTEXT
  ''																		, ; //X3_OBRIGAT
  ''																		, ; //X3_VLDUSER
  ''																		, ; //X3_CBOX
  ''																		, ; //X3_CBOXSPA
  ''																		, ; //X3_CBOXENG
  ''																		, ; //X3_PICTVAR
  ''																		, ; //X3_WHEN
  ''																		, ; //X3_INIBRW
  ''																		, ; //X3_GRPSXG
  ''																		, ; //X3_FOLDER
  ''																		, ; //X3_CONDSQL
  ''																		, ; //X3_CHKSQL
  ''																		, ; //X3_IDXSRV
  ''																		, ; //X3_ORTOGRA
  ''																		, ; //X3_TELA
  ''																		, ; //X3_POSLGT
  ''																		, ; //X3_IDXFLD
  ''																		, ; //X3_AGRUP
  ''																		, ; //X3_MODAL
  ''																		} ) //X3_PYME

  aAdd( aSX3, { ;
    'Z20'																	, ; //X3_ARQUIVO
  '03'																	, ; //X3_ORDEM
  'Z20_ROTINA'															, ; //X3_CAMPO
  'C'																		, ; //X3_TIPO
  7																		, ; //X3_TAMANHO
  0																		, ; //X3_DECIMAL
  'Rotina'																, ; //X3_TITULO
  'Rotina'																, ; //X3_TITSPA
  'Rotina'																, ; //X3_TITENG
  'Rotina'																, ; //X3_DESCRIC
  'Rotina'																, ; //X3_DESCSPA
  'Rotina'																, ; //X3_DESCENG
  '@!'																	, ; //X3_PICTURE
  ''																		, ; //X3_VALID
  Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
    Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
    Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, ; //X3_USADO
  ''																		, ; //X3_RELACAO
  ''																		, ; //X3_F3
  0																		, ; //X3_NIVEL
  Chr(254) + Chr(192)														, ; //X3_RESERV
  ''																		, ; //X3_CHECK
  ''																		, ; //X3_TRIGGER
  'U'																		, ; //X3_PROPRI
  'S'																		, ; //X3_BROWSE
  'A'																		, ; //X3_VISUAL
  'R'																		, ; //X3_CONTEXT
  ''																		, ; //X3_OBRIGAT
  ''																		, ; //X3_VLDUSER
  ''																		, ; //X3_CBOX
  ''																		, ; //X3_CBOXSPA
  ''																		, ; //X3_CBOXENG
  ''																		, ; //X3_PICTVAR
  ''																		, ; //X3_WHEN
  ''																		, ; //X3_INIBRW
  ''																		, ; //X3_GRPSXG
  ''																		, ; //X3_FOLDER
  ''																		, ; //X3_CONDSQL
  ''																		, ; //X3_CHKSQL
  ''																		, ; //X3_IDXSRV
  ''																		, ; //X3_ORTOGRA
  ''																		, ; //X3_TELA
  ''																		, ; //X3_POSLGT
  ''																		, ; //X3_IDXFLD
  ''																		, ; //X3_AGRUP
  ''																		, ; //X3_MODAL
  ''																		} ) //X3_PYME

  aAdd( aSX3, { ;
    'Z20'																	, ; //X3_ARQUIVO
  '04'																	, ; //X3_ORDEM
  'Z20_ROTDES'															, ; //X3_CAMPO
  'C'																		, ; //X3_TIPO
  30																		, ; //X3_TAMANHO
  0																		, ; //X3_DECIMAL
  'Desc. Rotina'															, ; //X3_TITULO
  'Desc. Rotina'															, ; //X3_TITSPA
  'Desc. Rotina'															, ; //X3_TITENG
  'Desc. Rotina'															, ; //X3_DESCRIC
  'Desc. Rotina'															, ; //X3_DESCSPA
  'Desc. Rotina'															, ; //X3_DESCENG
  '@!'																	, ; //X3_PICTURE
  ''																		, ; //X3_VALID
  Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
    Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
    Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, ; //X3_USADO
  ''																		, ; //X3_RELACAO
  ''																		, ; //X3_F3
  0																		, ; //X3_NIVEL
  Chr(254) + Chr(192)														, ; //X3_RESERV
  ''																		, ; //X3_CHECK
  ''																		, ; //X3_TRIGGER
  'U'																		, ; //X3_PROPRI
  'S'																		, ; //X3_BROWSE
  'A'																		, ; //X3_VISUAL
  'R'																		, ; //X3_CONTEXT
  ''																		, ; //X3_OBRIGAT
  ''																		, ; //X3_VLDUSER
  ''																		, ; //X3_CBOX
  ''																		, ; //X3_CBOXSPA
  ''																		, ; //X3_CBOXENG
  ''																		, ; //X3_PICTVAR
  ''																		, ; //X3_WHEN
  ''																		, ; //X3_INIBRW
  ''																		, ; //X3_GRPSXG
  ''																		, ; //X3_FOLDER
  ''																		, ; //X3_CONDSQL
  ''																		, ; //X3_CHKSQL
  ''																		, ; //X3_IDXSRV
  ''																		, ; //X3_ORTOGRA
  ''																		, ; //X3_TELA
  ''																		, ; //X3_POSLGT
  ''																		, ; //X3_IDXFLD
  ''																		, ; //X3_AGRUP
  ''																		, ; //X3_MODAL
  ''																		} ) //X3_PYME

  aAdd( aSX3, { ;
    'Z20'																	, ; //X3_ARQUIVO
  '05'																	, ; //X3_ORDEM
  'Z20_IDUSR'																, ; //X3_CAMPO
  'C'																		, ; //X3_TIPO
  6																		, ; //X3_TAMANHO
  0																		, ; //X3_DECIMAL
  'Id Usuario'															, ; //X3_TITULO
  'Id Usuario'															, ; //X3_TITSPA
  'Id Usuario'															, ; //X3_TITENG
  'Id Usuario'															, ; //X3_DESCRIC
  'Id Usuario'															, ; //X3_DESCSPA
  'Id Usuario'															, ; //X3_DESCENG
  '@!'																	, ; //X3_PICTURE
  ''																		, ; //X3_VALID
  Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
    Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
    Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, ; //X3_USADO
  ''																		, ; //X3_RELACAO
  'US2'																	, ; //X3_F3
  0																		, ; //X3_NIVEL
  Chr(254) + Chr(192)														, ; //X3_RESERV
  ''																		, ; //X3_CHECK
  'S'																		, ; //X3_TRIGGER
  'U'																		, ; //X3_PROPRI
  'S'																		, ; //X3_BROWSE
  'A'																		, ; //X3_VISUAL
  'R'																		, ; //X3_CONTEXT
  ''																		, ; //X3_OBRIGAT
  ''																		, ; //X3_VLDUSER
  ''																		, ; //X3_CBOX
  ''																		, ; //X3_CBOXSPA
  ''																		, ; //X3_CBOXENG
  ''																		, ; //X3_PICTVAR
  ''																		, ; //X3_WHEN
  ''																		, ; //X3_INIBRW
  ''																		, ; //X3_GRPSXG
  ''																		, ; //X3_FOLDER
  ''																		, ; //X3_CONDSQL
  ''																		, ; //X3_CHKSQL
  ''																		, ; //X3_IDXSRV
  ''																		, ; //X3_ORTOGRA
  ''																		, ; //X3_TELA
  ''																		, ; //X3_POSLGT
  ''																		, ; //X3_IDXFLD
  ''																		, ; //X3_AGRUP
  ''																		, ; //X3_MODAL
  ''																		} ) //X3_PYME

  aAdd( aSX3, { ;
    'Z20'																	, ; //X3_ARQUIVO
  '06'																	, ; //X3_ORDEM
  'Z20_USRNOM'															, ; //X3_CAMPO
  'C'																		, ; //X3_TIPO
  30																		, ; //X3_TAMANHO
  0																		, ; //X3_DECIMAL
  'Nome Usuario'															, ; //X3_TITULO
  'Nome Usuario'															, ; //X3_TITSPA
  'Nome Usuario'															, ; //X3_TITENG
  'Nome Usuario'															, ; //X3_DESCRIC
  'Nome Usuario'															, ; //X3_DESCSPA
  'Nome Usuario'															, ; //X3_DESCENG
  '@!'																	, ; //X3_PICTURE
  ''																		, ; //X3_VALID
  Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
    Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
    Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, ; //X3_USADO
  ''																		, ; //X3_RELACAO
  ''																		, ; //X3_F3
  0																		, ; //X3_NIVEL
  Chr(254) + Chr(192)														, ; //X3_RESERV
  ''																		, ; //X3_CHECK
  ''																		, ; //X3_TRIGGER
  'U'																		, ; //X3_PROPRI
  'S'																		, ; //X3_BROWSE
  'A'																		, ; //X3_VISUAL
  'R'																		, ; //X3_CONTEXT
  ''																		, ; //X3_OBRIGAT
  ''																		, ; //X3_VLDUSER
  ''																		, ; //X3_CBOX
  ''																		, ; //X3_CBOXSPA
  ''																		, ; //X3_CBOXENG
  ''																		, ; //X3_PICTVAR
  ''																		, ; //X3_WHEN
  ''																		, ; //X3_INIBRW
  ''																		, ; //X3_GRPSXG
  ''																		, ; //X3_FOLDER
  ''																		, ; //X3_CONDSQL
  ''																		, ; //X3_CHKSQL
  ''																		, ; //X3_IDXSRV
  ''																		, ; //X3_ORTOGRA
  ''																		, ; //X3_TELA
  ''																		, ; //X3_POSLGT
  ''																		, ; //X3_IDXFLD
  ''																		, ; //X3_AGRUP
  ''																		, ; //X3_MODAL
  ''																		} ) //X3_PYME

  aAdd( aSX3, { ;
    'Z20'																	, ; //X3_ARQUIVO
  '07'																	, ; //X3_ORDEM
  'Z20_SETOR'																, ; //X3_CAMPO
  'C'																		, ; //X3_TIPO
  20																		, ; //X3_TAMANHO
  0																		, ; //X3_DECIMAL
  'Setor'																	, ; //X3_TITULO
  'Setor'																	, ; //X3_TITSPA
  'Setor'																	, ; //X3_TITENG
  'Setor'																	, ; //X3_DESCRIC
  'Setor'																	, ; //X3_DESCSPA
  'Setor'																	, ; //X3_DESCENG
  '@!'																	, ; //X3_PICTURE
  ''																		, ; //X3_VALID
  Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
    Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
    Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, ; //X3_USADO
  ''																		, ; //X3_RELACAO
  ''																		, ; //X3_F3
  0																		, ; //X3_NIVEL
  Chr(254) + Chr(192)														, ; //X3_RESERV
  ''																		, ; //X3_CHECK
  ''																		, ; //X3_TRIGGER
  'U'																		, ; //X3_PROPRI
  'S'																		, ; //X3_BROWSE
  'A'																		, ; //X3_VISUAL
  'R'																		, ; //X3_CONTEXT
  ''																		, ; //X3_OBRIGAT
  ''																		, ; //X3_VLDUSER
  ''																		, ; //X3_CBOX
  ''																		, ; //X3_CBOXSPA
  ''																		, ; //X3_CBOXENG
  ''																		, ; //X3_PICTVAR
  ''																		, ; //X3_WHEN
  ''																		, ; //X3_INIBRW
  ''																		, ; //X3_GRPSXG
  ''																		, ; //X3_FOLDER
  ''																		, ; //X3_CONDSQL
  ''																		, ; //X3_CHKSQL
  ''																		, ; //X3_IDXSRV
  ''																		, ; //X3_ORTOGRA
  ''																		, ; //X3_TELA
  ''																		, ; //X3_POSLGT
  ''																		, ; //X3_IDXFLD
  ''																		, ; //X3_AGRUP
  ''																		, ; //X3_MODAL
  ''																		} ) //X3_PYME

  aAdd( aSX3, { ;
    'Z20'																	, ; //X3_ARQUIVO
  '08'																	, ; //X3_ORDEM
  'Z20_NUM1'																, ; //X3_CAMPO
  'C'																		, ; //X3_TIPO
  1																		, ; //X3_TAMANHO
  0																		, ; //X3_DECIMAL
  '1 Opcao'																, ; //X3_TITULO
  '1 Opcao'																, ; //X3_TITSPA
  '1 Opcao'																, ; //X3_TITENG
  '1 Opcao'																, ; //X3_DESCRIC
  '1 Opcao'																, ; //X3_DESCSPA
  '1 Opcao'																, ; //X3_DESCENG
  '@!'																	, ; //X3_PICTURE
  'Pertence( "12" )'														, ; //X3_VALID
  Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
    Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
    Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, ; //X3_USADO
  ''																		, ; //X3_RELACAO
  ''																		, ; //X3_F3
  0																		, ; //X3_NIVEL
  Chr(254) + Chr(192)														, ; //X3_RESERV
  ''																		, ; //X3_CHECK
  ''																		, ; //X3_TRIGGER
  'U'																		, ; //X3_PROPRI
  'N'																		, ; //X3_BROWSE
  'A'																		, ; //X3_VISUAL
  'R'																		, ; //X3_CONTEXT
  ''																		, ; //X3_OBRIGAT
  ''																		, ; //X3_VLDUSER
  '1=Sim;2=Nao'															, ; //X3_CBOX
  ''																		, ; //X3_CBOXSPA
  ''																		, ; //X3_CBOXENG
  ''																		, ; //X3_PICTVAR
  ''																		, ; //X3_WHEN
  ''																		, ; //X3_INIBRW
  ''																		, ; //X3_GRPSXG
  ''																		, ; //X3_FOLDER
  ''																		, ; //X3_CONDSQL
  ''																		, ; //X3_CHKSQL
  ''																		, ; //X3_IDXSRV
  ''																		, ; //X3_ORTOGRA
  ''																		, ; //X3_TELA
  ''																		, ; //X3_POSLGT
  ''																		, ; //X3_IDXFLD
  ''																		, ; //X3_AGRUP
  ''																		, ; //X3_MODAL
  ''																		} ) //X3_PYME

  aAdd( aSX3, { ;
    'Z20'																	, ; //X3_ARQUIVO
  '09'																	, ; //X3_ORDEM
  'Z20_NUM2'																, ; //X3_CAMPO
  'C'																		, ; //X3_TIPO
  1																		, ; //X3_TAMANHO
  0																		, ; //X3_DECIMAL
  '2 Opcao'																, ; //X3_TITULO
  '2 Opcao'																, ; //X3_TITSPA
  '2 Opcao'																, ; //X3_TITENG
  '2 Opcao'																, ; //X3_DESCRIC
  '2 Opcao'																, ; //X3_DESCSPA
  '2 Opcao'																, ; //X3_DESCENG
  '@!'																	, ; //X3_PICTURE
  'Pertence( "12" )'														, ; //X3_VALID
  Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
    Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
    Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, ; //X3_USADO
  ''																		, ; //X3_RELACAO
  ''																		, ; //X3_F3
  0																		, ; //X3_NIVEL
  Chr(254) + Chr(192)														, ; //X3_RESERV
  ''																		, ; //X3_CHECK
  ''																		, ; //X3_TRIGGER
  'U'																		, ; //X3_PROPRI
  'N'																		, ; //X3_BROWSE
  'A'																		, ; //X3_VISUAL
  'R'																		, ; //X3_CONTEXT
  ''																		, ; //X3_OBRIGAT
  ''																		, ; //X3_VLDUSER
  '1=Sim;2=Nao'															, ; //X3_CBOX
  ''																		, ; //X3_CBOXSPA
  ''																		, ; //X3_CBOXENG
  ''																		, ; //X3_PICTVAR
  ''																		, ; //X3_WHEN
  ''																		, ; //X3_INIBRW
  ''																		, ; //X3_GRPSXG
  ''																		, ; //X3_FOLDER
  ''																		, ; //X3_CONDSQL
  ''																		, ; //X3_CHKSQL
  ''																		, ; //X3_IDXSRV
  ''																		, ; //X3_ORTOGRA
  ''																		, ; //X3_TELA
  ''																		, ; //X3_POSLGT
  ''																		, ; //X3_IDXFLD
  ''																		, ; //X3_AGRUP
  ''																		, ; //X3_MODAL
  ''																		} ) //X3_PYME

  aAdd( aSX3, { ;
    'Z20'																	, ; //X3_ARQUIVO
  '10'																	, ; //X3_ORDEM
  'Z20_NUM3'																, ; //X3_CAMPO
  'C'																		, ; //X3_TIPO
  1																		, ; //X3_TAMANHO
  0																		, ; //X3_DECIMAL
  '3 Opcao'																, ; //X3_TITULO
  '3 Opcao'																, ; //X3_TITSPA
  '3 Opcao'																, ; //X3_TITENG
  '3 Opcao'																, ; //X3_DESCRIC
  '3 Opcao'																, ; //X3_DESCSPA
  '3 Opcao'																, ; //X3_DESCENG
  '@!'																	, ; //X3_PICTURE
  'Pertence( "12" )'														, ; //X3_VALID
  Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
    Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
    Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, ; //X3_USADO
  ''																		, ; //X3_RELACAO
  ''																		, ; //X3_F3
  0																		, ; //X3_NIVEL
  Chr(254) + Chr(192)														, ; //X3_RESERV
  ''																		, ; //X3_CHECK
  ''																		, ; //X3_TRIGGER
  'U'																		, ; //X3_PROPRI
  'N'																		, ; //X3_BROWSE
  'A'																		, ; //X3_VISUAL
  'R'																		, ; //X3_CONTEXT
  ''																		, ; //X3_OBRIGAT
  ''																		, ; //X3_VLDUSER
  '1=Sim;2=Nao'															, ; //X3_CBOX
  ''																		, ; //X3_CBOXSPA
  ''																		, ; //X3_CBOXENG
  ''																		, ; //X3_PICTVAR
  ''																		, ; //X3_WHEN
  ''																		, ; //X3_INIBRW
  ''																		, ; //X3_GRPSXG
  ''																		, ; //X3_FOLDER
  ''																		, ; //X3_CONDSQL
  ''																		, ; //X3_CHKSQL
  ''																		, ; //X3_IDXSRV
  ''																		, ; //X3_ORTOGRA
  ''																		, ; //X3_TELA
  ''																		, ; //X3_POSLGT
  ''																		, ; //X3_IDXFLD
  ''																		, ; //X3_AGRUP
  ''																		, ; //X3_MODAL
  ''																		} ) //X3_PYME

  aAdd( aSX3, { ;
    'Z20'																	, ; //X3_ARQUIVO
  '11'																	, ; //X3_ORDEM
  'Z20_NUM4'																, ; //X3_CAMPO
  'C'																		, ; //X3_TIPO
  1																		, ; //X3_TAMANHO
  0																		, ; //X3_DECIMAL
  '4 Opcao'																, ; //X3_TITULO
  '4 Opcao'																, ; //X3_TITSPA
  '4 Opcao'																, ; //X3_TITENG
  '4 Opcao'																, ; //X3_DESCRIC
  '4 Opcao'																, ; //X3_DESCSPA
  '4 Opcao'																, ; //X3_DESCENG
  '@!'																	, ; //X3_PICTURE
  'Pertence( "12" )'														, ; //X3_VALID
  Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
    Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
    Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, ; //X3_USADO
  ''																		, ; //X3_RELACAO
  ''																		, ; //X3_F3
  0																		, ; //X3_NIVEL
  Chr(254) + Chr(192)														, ; //X3_RESERV
  ''																		, ; //X3_CHECK
  ''																		, ; //X3_TRIGGER
  'U'																		, ; //X3_PROPRI
  'N'																		, ; //X3_BROWSE
  'A'																		, ; //X3_VISUAL
  'R'																		, ; //X3_CONTEXT
  ''																		, ; //X3_OBRIGAT
  ''																		, ; //X3_VLDUSER
  '1=Sim;2=Nao'															, ; //X3_CBOX
  ''																		, ; //X3_CBOXSPA
  ''																		, ; //X3_CBOXENG
  ''																		, ; //X3_PICTVAR
  ''																		, ; //X3_WHEN
  ''																		, ; //X3_INIBRW
  ''																		, ; //X3_GRPSXG
  ''																		, ; //X3_FOLDER
  ''																		, ; //X3_CONDSQL
  ''																		, ; //X3_CHKSQL
  ''																		, ; //X3_IDXSRV
  ''																		, ; //X3_ORTOGRA
  ''																		, ; //X3_TELA
  ''																		, ; //X3_POSLGT
  ''																		, ; //X3_IDXFLD
  ''																		, ; //X3_AGRUP
  ''																		, ; //X3_MODAL
  ''																		} ) //X3_PYME

  aAdd( aSX3, { ;
    'Z20'																	, ; //X3_ARQUIVO
  '12'																	, ; //X3_ORDEM
  'Z20_NUM5'																, ; //X3_CAMPO
  'C'																		, ; //X3_TIPO
  1																		, ; //X3_TAMANHO
  0																		, ; //X3_DECIMAL
  '5 Opcao'																, ; //X3_TITULO
  '5 Opcao'																, ; //X3_TITSPA
  '5 Opcao'																, ; //X3_TITENG
  '5 Opcao'																, ; //X3_DESCRIC
  '5 Opcao'																, ; //X3_DESCSPA
  '5 Opcao'																, ; //X3_DESCENG
  '@!'																	, ; //X3_PICTURE
  'Pertence( "12" )'														, ; //X3_VALID
  Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
    Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
    Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, ; //X3_USADO
  ''																		, ; //X3_RELACAO
  ''																		, ; //X3_F3
  0																		, ; //X3_NIVEL
  Chr(254) + Chr(192)														, ; //X3_RESERV
  ''																		, ; //X3_CHECK
  ''																		, ; //X3_TRIGGER
  'U'																		, ; //X3_PROPRI
  'N'																		, ; //X3_BROWSE
  'A'																		, ; //X3_VISUAL
  'R'																		, ; //X3_CONTEXT
  ''																		, ; //X3_OBRIGAT
  ''																		, ; //X3_VLDUSER
  '1=Sim;2=Nao'															, ; //X3_CBOX
  ''																		, ; //X3_CBOXSPA
  ''																		, ; //X3_CBOXENG
  ''																		, ; //X3_PICTVAR
  ''																		, ; //X3_WHEN
  ''																		, ; //X3_INIBRW
  ''																		, ; //X3_GRPSXG
  ''																		, ; //X3_FOLDER
  ''																		, ; //X3_CONDSQL
  ''																		, ; //X3_CHKSQL
  ''																		, ; //X3_IDXSRV
  ''																		, ; //X3_ORTOGRA
  ''																		, ; //X3_TELA
  ''																		, ; //X3_POSLGT
  ''																		, ; //X3_IDXFLD
  ''																		, ; //X3_AGRUP
  ''																		, ; //X3_MODAL
  ''																		} ) //X3_PYME

  aAdd( aSX3, { ;
    'Z20'																	, ; //X3_ARQUIVO
  '13'																	, ; //X3_ORDEM
  'Z20_NUM6'																, ; //X3_CAMPO
  'C'																		, ; //X3_TIPO
  1																		, ; //X3_TAMANHO
  0																		, ; //X3_DECIMAL
  '6 Opcao'																, ; //X3_TITULO
  '6 Opcao'																, ; //X3_TITSPA
  '6 Opcao'																, ; //X3_TITENG
  '6 Opcao'																, ; //X3_DESCRIC
  '6 Opcao'																, ; //X3_DESCSPA
  '6 Opcao'																, ; //X3_DESCENG
  '@!'																	, ; //X3_PICTURE
  'Pertence( "12" )'														, ; //X3_VALID
  Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
    Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
    Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, ; //X3_USADO
  ''																		, ; //X3_RELACAO
  ''																		, ; //X3_F3
  0																		, ; //X3_NIVEL
  Chr(254) + Chr(192)														, ; //X3_RESERV
  ''																		, ; //X3_CHECK
  ''																		, ; //X3_TRIGGER
  'U'																		, ; //X3_PROPRI
  'N'																		, ; //X3_BROWSE
  'A'																		, ; //X3_VISUAL
  'R'																		, ; //X3_CONTEXT
  ''																		, ; //X3_OBRIGAT
  ''																		, ; //X3_VLDUSER
  '1=Sim;2=Nao'															, ; //X3_CBOX
  ''																		, ; //X3_CBOXSPA
  ''																		, ; //X3_CBOXENG
  ''																		, ; //X3_PICTVAR
  ''																		, ; //X3_WHEN
  ''																		, ; //X3_INIBRW
  ''																		, ; //X3_GRPSXG
  ''																		, ; //X3_FOLDER
  ''																		, ; //X3_CONDSQL
  ''																		, ; //X3_CHKSQL
  ''																		, ; //X3_IDXSRV
  ''																		, ; //X3_ORTOGRA
  ''																		, ; //X3_TELA
  ''																		, ; //X3_POSLGT
  ''																		, ; //X3_IDXFLD
  ''																		, ; //X3_AGRUP
  ''																		, ; //X3_MODAL
  ''																		} ) //X3_PYME

  aAdd( aSX3, { ;
    'Z20'																	, ; //X3_ARQUIVO
  '14'																	, ; //X3_ORDEM
  'Z20_NUM7'																, ; //X3_CAMPO
  'C'																		, ; //X3_TIPO
  1																		, ; //X3_TAMANHO
  0																		, ; //X3_DECIMAL
  '7 Opcao'																, ; //X3_TITULO
  '7 Opcao'																, ; //X3_TITSPA
  '7 Opcao'																, ; //X3_TITENG
  '7 Opcao'																, ; //X3_DESCRIC
  '7 Opcao'																, ; //X3_DESCSPA
  '7 Opcao'																, ; //X3_DESCENG
  '@!'																	, ; //X3_PICTURE
  'Pertence( "12" )'														, ; //X3_VALID
  Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
    Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
    Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, ; //X3_USADO
  ''																		, ; //X3_RELACAO
  ''																		, ; //X3_F3
  0																		, ; //X3_NIVEL
  Chr(254) + Chr(192)														, ; //X3_RESERV
  ''																		, ; //X3_CHECK
  ''																		, ; //X3_TRIGGER
  'U'																		, ; //X3_PROPRI
  'N'																		, ; //X3_BROWSE
  'A'																		, ; //X3_VISUAL
  'R'																		, ; //X3_CONTEXT
  ''																		, ; //X3_OBRIGAT
  ''																		, ; //X3_VLDUSER
  '1=Sim;2=Nao'															, ; //X3_CBOX
  ''																		, ; //X3_CBOXSPA
  ''																		, ; //X3_CBOXENG
  ''																		, ; //X3_PICTVAR
  ''																		, ; //X3_WHEN
  ''																		, ; //X3_INIBRW
  ''																		, ; //X3_GRPSXG
  ''																		, ; //X3_FOLDER
  ''																		, ; //X3_CONDSQL
  ''																		, ; //X3_CHKSQL
  ''																		, ; //X3_IDXSRV
  ''																		, ; //X3_ORTOGRA
  ''																		, ; //X3_TELA
  ''																		, ; //X3_POSLGT
  ''																		, ; //X3_IDXFLD
  ''																		, ; //X3_AGRUP
  ''																		, ; //X3_MODAL
  ''																		} ) //X3_PYME

  aAdd( aSX3, { ;
    'Z20'																	, ; //X3_ARQUIVO
  '15'																	, ; //X3_ORDEM
  'Z20_NUM8'																, ; //X3_CAMPO
  'C'																		, ; //X3_TIPO
  1																		, ; //X3_TAMANHO
  0																		, ; //X3_DECIMAL
  '8 Opcao'																, ; //X3_TITULO
  '8 Opcao'																, ; //X3_TITSPA
  '8 Opcao'																, ; //X3_TITENG
  '8 Opcao'																, ; //X3_DESCRIC
  '8 Opcao'																, ; //X3_DESCSPA
  '8 Opcao'																, ; //X3_DESCENG
  '@!'																	, ; //X3_PICTURE
  'Pertence( "12" )'														, ; //X3_VALID
  Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
    Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
    Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, ; //X3_USADO
  ''																		, ; //X3_RELACAO
  ''																		, ; //X3_F3
  0																		, ; //X3_NIVEL
  Chr(254) + Chr(192)														, ; //X3_RESERV
  ''																		, ; //X3_CHECK
  ''																		, ; //X3_TRIGGER
  'U'																		, ; //X3_PROPRI
  'N'																		, ; //X3_BROWSE
  'A'																		, ; //X3_VISUAL
  'R'																		, ; //X3_CONTEXT
  ''																		, ; //X3_OBRIGAT
  ''																		, ; //X3_VLDUSER
  '1=Sim;2=Nao'															, ; //X3_CBOX
  ''																		, ; //X3_CBOXSPA
  ''																		, ; //X3_CBOXENG
  ''																		, ; //X3_PICTVAR
  ''																		, ; //X3_WHEN
  ''																		, ; //X3_INIBRW
  ''																		, ; //X3_GRPSXG
  ''																		, ; //X3_FOLDER
  ''																		, ; //X3_CONDSQL
  ''																		, ; //X3_CHKSQL
  ''																		, ; //X3_IDXSRV
  ''																		, ; //X3_ORTOGRA
  ''																		, ; //X3_TELA
  ''																		, ; //X3_POSLGT
  ''																		, ; //X3_IDXFLD
  ''																		, ; //X3_AGRUP
  ''																		, ; //X3_MODAL
  ''																		} ) //X3_PYME

  aAdd( aSX3, { ;
    'Z20'																	, ; //X3_ARQUIVO
  '16'																	, ; //X3_ORDEM
  'Z20_NUM9'																, ; //X3_CAMPO
  'C'																		, ; //X3_TIPO
  1																		, ; //X3_TAMANHO
  0																		, ; //X3_DECIMAL
  '9 Opcao'																, ; //X3_TITULO
  '9 Opcao'																, ; //X3_TITSPA
  '9 Opcao'																, ; //X3_TITENG
  '9 Opcao'																, ; //X3_DESCRIC
  '9 Opcao'																, ; //X3_DESCSPA
  '9 Opcao'																, ; //X3_DESCENG
  '@!'																	, ; //X3_PICTURE
  'Pertence( "12" )'														, ; //X3_VALID
  Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
    Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
    Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, ; //X3_USADO
  ''																		, ; //X3_RELACAO
  ''																		, ; //X3_F3
  0																		, ; //X3_NIVEL
  Chr(254) + Chr(192)														, ; //X3_RESERV
  ''																		, ; //X3_CHECK
  ''																		, ; //X3_TRIGGER
  'U'																		, ; //X3_PROPRI
  'N'																		, ; //X3_BROWSE
  'A'																		, ; //X3_VISUAL
  'R'																		, ; //X3_CONTEXT
  ''																		, ; //X3_OBRIGAT
  ''																		, ; //X3_VLDUSER
  '1=Sim;2=Nao'															, ; //X3_CBOX
  ''																		, ; //X3_CBOXSPA
  ''																		, ; //X3_CBOXENG
  ''																		, ; //X3_PICTVAR
  ''																		, ; //X3_WHEN
  ''																		, ; //X3_INIBRW
  ''																		, ; //X3_GRPSXG
  ''																		, ; //X3_FOLDER
  ''																		, ; //X3_CONDSQL
  ''																		, ; //X3_CHKSQL
  ''																		, ; //X3_IDXSRV
  ''																		, ; //X3_ORTOGRA
  ''																		, ; //X3_TELA
  ''																		, ; //X3_POSLGT
  ''																		, ; //X3_IDXFLD
  ''																		, ; //X3_AGRUP
  ''																		, ; //X3_MODAL
  ''																		} ) //X3_PYME

  aAdd( aSX3, { ;
    'Z20'																	, ; //X3_ARQUIVO
  '17'																	, ; //X3_ORDEM
  'Z20_NUM10'																, ; //X3_CAMPO
  'C'																		, ; //X3_TIPO
  1																		, ; //X3_TAMANHO
  0																		, ; //X3_DECIMAL
  '10 Opcao'																, ; //X3_TITULO
  '10 Opcao'																, ; //X3_TITSPA
  '10 Opcao'																, ; //X3_TITENG
  '10 Opcao'																, ; //X3_DESCRIC
  '10 Opcao'																, ; //X3_DESCSPA
  '10 Opcao'																, ; //X3_DESCENG
  '@!'																	, ; //X3_PICTURE
  'Pertence( "12" )'														, ; //X3_VALID
  Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
    Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
    Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, ; //X3_USADO
  ''																		, ; //X3_RELACAO
  ''																		, ; //X3_F3
  0																		, ; //X3_NIVEL
  Chr(254) + Chr(192)														, ; //X3_RESERV
  ''																		, ; //X3_CHECK
  ''																		, ; //X3_TRIGGER
  'U'																		, ; //X3_PROPRI
  'N'																		, ; //X3_BROWSE
  'A'																		, ; //X3_VISUAL
  'R'																		, ; //X3_CONTEXT
  ''																		, ; //X3_OBRIGAT
  ''																		, ; //X3_VLDUSER
  '1=Sim;2=Nao'															, ; //X3_CBOX
  ''																		, ; //X3_CBOXSPA
  ''																		, ; //X3_CBOXENG
  ''																		, ; //X3_PICTVAR
  ''																		, ; //X3_WHEN
  ''																		, ; //X3_INIBRW
  ''																		, ; //X3_GRPSXG
  ''																		, ; //X3_FOLDER
  ''																		, ; //X3_CONDSQL
  ''																		, ; //X3_CHKSQL
  ''																		, ; //X3_IDXSRV
  ''																		, ; //X3_ORTOGRA
  ''																		, ; //X3_TELA
  ''																		, ; //X3_POSLGT
  ''																		, ; //X3_IDXFLD
  ''																		, ; //X3_AGRUP
  ''																		, ; //X3_MODAL
  ''																		} ) //X3_PYME

  aAdd( aSX3, { ;
    'Z20'																	, ; //X3_ARQUIVO
  '18'																	, ; //X3_ORDEM
  'Z20_NUM11'																, ; //X3_CAMPO
  'C'																		, ; //X3_TIPO
  1																		, ; //X3_TAMANHO
  0																		, ; //X3_DECIMAL
  '11 Opcao'																, ; //X3_TITULO
  '11 Opcao'																, ; //X3_TITSPA
  '11 Opcao'																, ; //X3_TITENG
  '11 Opcao'																, ; //X3_DESCRIC
  '11 Opcao'																, ; //X3_DESCSPA
  '11 Opcao'																, ; //X3_DESCENG
  '@!'																	, ; //X3_PICTURE
  'Pertence( "12" )'														, ; //X3_VALID
  Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
    Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
    Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, ; //X3_USADO
  ''																		, ; //X3_RELACAO
  ''																		, ; //X3_F3
  0																		, ; //X3_NIVEL
  Chr(254) + Chr(192)														, ; //X3_RESERV
  ''																		, ; //X3_CHECK
  ''																		, ; //X3_TRIGGER
  'U'																		, ; //X3_PROPRI
  'N'																		, ; //X3_BROWSE
  'A'																		, ; //X3_VISUAL
  'R'																		, ; //X3_CONTEXT
  ''																		, ; //X3_OBRIGAT
  ''																		, ; //X3_VLDUSER
  '1=Sim;2=Nao'															, ; //X3_CBOX
  ''																		, ; //X3_CBOXSPA
  ''																		, ; //X3_CBOXENG
  ''																		, ; //X3_PICTVAR
  ''																		, ; //X3_WHEN
  ''																		, ; //X3_INIBRW
  ''																		, ; //X3_GRPSXG
  ''																		, ; //X3_FOLDER
  ''																		, ; //X3_CONDSQL
  ''																		, ; //X3_CHKSQL
  ''																		, ; //X3_IDXSRV
  ''																		, ; //X3_ORTOGRA
  ''																		, ; //X3_TELA
  ''																		, ; //X3_POSLGT
  ''																		, ; //X3_IDXFLD
  ''																		, ; //X3_AGRUP
  ''																		, ; //X3_MODAL
  ''																		} ) //X3_PYME

  aAdd( aSX3, { ;
    'Z20'																	, ; //X3_ARQUIVO
  '19'																	, ; //X3_ORDEM
  'Z20_NUM12'																, ; //X3_CAMPO
  'C'																		, ; //X3_TIPO
  1																		, ; //X3_TAMANHO
  0																		, ; //X3_DECIMAL
  '12 Opcao'																, ; //X3_TITULO
  '12 Opcao'																, ; //X3_TITSPA
  '12 Opcao'																, ; //X3_TITENG
  '12 Opcao'																, ; //X3_DESCRIC
  '12 Opcao'																, ; //X3_DESCSPA
  '12 Opcao'																, ; //X3_DESCENG
  '@!'																	, ; //X3_PICTURE
  'Pertence( "12" )'														, ; //X3_VALID
  Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
    Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
    Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, ; //X3_USADO
  ''																		, ; //X3_RELACAO
  ''																		, ; //X3_F3
  0																		, ; //X3_NIVEL
  Chr(254) + Chr(192)														, ; //X3_RESERV
  ''																		, ; //X3_CHECK
  ''																		, ; //X3_TRIGGER
  'U'																		, ; //X3_PROPRI
  'N'																		, ; //X3_BROWSE
  'A'																		, ; //X3_VISUAL
  'R'																		, ; //X3_CONTEXT
  ''																		, ; //X3_OBRIGAT
  ''																		, ; //X3_VLDUSER
  '1=Sim;2=Nao'															, ; //X3_CBOX
  ''																		, ; //X3_CBOXSPA
  ''																		, ; //X3_CBOXENG
  ''																		, ; //X3_PICTVAR
  ''																		, ; //X3_WHEN
  ''																		, ; //X3_INIBRW
  ''																		, ; //X3_GRPSXG
  ''																		, ; //X3_FOLDER
  ''																		, ; //X3_CONDSQL
  ''																		, ; //X3_CHKSQL
  ''																		, ; //X3_IDXSRV
  ''																		, ; //X3_ORTOGRA
  ''																		, ; //X3_TELA
  ''																		, ; //X3_POSLGT
  ''																		, ; //X3_IDXFLD
  ''																		, ; //X3_AGRUP
  ''																		, ; //X3_MODAL
  ''																		} ) //X3_PYME

  aAdd( aSX3, { ;
    'Z20'																	, ; //X3_ARQUIVO
  '20'																	, ; //X3_ORDEM
  'Z20_NUM13'																, ; //X3_CAMPO
  'C'																		, ; //X3_TIPO
  1																		, ; //X3_TAMANHO
  0																		, ; //X3_DECIMAL
  '13 Opcao'																, ; //X3_TITULO
  '13 Opcao'																, ; //X3_TITSPA
  '13 Opcao'																, ; //X3_TITENG
  '13 Opcao'																, ; //X3_DESCRIC
  '13 Opcao'																, ; //X3_DESCSPA
  '13 Opcao'																, ; //X3_DESCENG
  '@!'																	, ; //X3_PICTURE
  'Pertence( "12" )'														, ; //X3_VALID
  Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
    Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
    Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, ; //X3_USADO
  ''																		, ; //X3_RELACAO
  ''																		, ; //X3_F3
  0																		, ; //X3_NIVEL
  Chr(254) + Chr(192)														, ; //X3_RESERV
  ''																		, ; //X3_CHECK
  ''																		, ; //X3_TRIGGER
  'U'																		, ; //X3_PROPRI
  'N'																		, ; //X3_BROWSE
  'A'																		, ; //X3_VISUAL
  'R'																		, ; //X3_CONTEXT
  ''																		, ; //X3_OBRIGAT
  ''																		, ; //X3_VLDUSER
  '1=Sim;2=Nao'															, ; //X3_CBOX
  ''																		, ; //X3_CBOXSPA
  ''																		, ; //X3_CBOXENG
  ''																		, ; //X3_PICTVAR
  ''																		, ; //X3_WHEN
  ''																		, ; //X3_INIBRW
  ''																		, ; //X3_GRPSXG
  ''																		, ; //X3_FOLDER
  ''																		, ; //X3_CONDSQL
  ''																		, ; //X3_CHKSQL
  ''																		, ; //X3_IDXSRV
  ''																		, ; //X3_ORTOGRA
  ''																		, ; //X3_TELA
  ''																		, ; //X3_POSLGT
  ''																		, ; //X3_IDXFLD
  ''																		, ; //X3_AGRUP
  ''																		, ; //X3_MODAL
  ''																		} ) //X3_PYME

  aAdd( aSX3, { ;
    'Z20'																	, ; //X3_ARQUIVO
  '21'																	, ; //X3_ORDEM
  'Z20_NUM14'																, ; //X3_CAMPO
  'C'																		, ; //X3_TIPO
  1																		, ; //X3_TAMANHO
  0																		, ; //X3_DECIMAL
  '14 Opcao'																, ; //X3_TITULO
  '14 Opcao'																, ; //X3_TITSPA
  '14 Opcao'																, ; //X3_TITENG
  '14 Opcao'																, ; //X3_DESCRIC
  '14 Opcao'																, ; //X3_DESCSPA
  '14 Opcao'																, ; //X3_DESCENG
  '@!'																	, ; //X3_PICTURE
  'Pertence( "12" )'														, ; //X3_VALID
  Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
    Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
    Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, ; //X3_USADO
  ''																		, ; //X3_RELACAO
  ''																		, ; //X3_F3
  0																		, ; //X3_NIVEL
  Chr(254) + Chr(192)														, ; //X3_RESERV
  ''																		, ; //X3_CHECK
  ''																		, ; //X3_TRIGGER
  'U'																		, ; //X3_PROPRI
  'N'																		, ; //X3_BROWSE
  'A'																		, ; //X3_VISUAL
  'R'																		, ; //X3_CONTEXT
  ''																		, ; //X3_OBRIGAT
  ''																		, ; //X3_VLDUSER
  '1=Sim;2=Nao'															, ; //X3_CBOX
  ''																		, ; //X3_CBOXSPA
  ''																		, ; //X3_CBOXENG
  ''																		, ; //X3_PICTVAR
  ''																		, ; //X3_WHEN
  ''																		, ; //X3_INIBRW
  ''																		, ; //X3_GRPSXG
  ''																		, ; //X3_FOLDER
  ''																		, ; //X3_CONDSQL
  ''																		, ; //X3_CHKSQL
  ''																		, ; //X3_IDXSRV
  ''																		, ; //X3_ORTOGRA
  ''																		, ; //X3_TELA
  ''																		, ; //X3_POSLGT
  ''																		, ; //X3_IDXFLD
  ''																		, ; //X3_AGRUP
  ''																		, ; //X3_MODAL
  ''																		} ) //X3_PYME

  aAdd( aSX3, { ;
    'Z20'																	, ; //X3_ARQUIVO
  '22'																	, ; //X3_ORDEM
  'Z20_NUM15'																, ; //X3_CAMPO
  'C'																		, ; //X3_TIPO
  1																		, ; //X3_TAMANHO
  0																		, ; //X3_DECIMAL
  '15 Opcao'																, ; //X3_TITULO
  '15 Opcao'																, ; //X3_TITSPA
  '15 Opcao'																, ; //X3_TITENG
  '15 Opcao'																, ; //X3_DESCRIC
  '15 Opcao'																, ; //X3_DESCSPA
  '15 Opcao'																, ; //X3_DESCENG
  '@!'																	, ; //X3_PICTURE
  'Pertence( "12" )'														, ; //X3_VALID
  Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
    Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
    Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, ; //X3_USADO
  ''																		, ; //X3_RELACAO
  ''																		, ; //X3_F3
  0																		, ; //X3_NIVEL
  Chr(254) + Chr(192)														, ; //X3_RESERV
  ''																		, ; //X3_CHECK
  ''																		, ; //X3_TRIGGER
  'U'																		, ; //X3_PROPRI
  'N'																		, ; //X3_BROWSE
  'A'																		, ; //X3_VISUAL
  'R'																		, ; //X3_CONTEXT
  ''																		, ; //X3_OBRIGAT
  ''																		, ; //X3_VLDUSER
  '1=Sim;2=Nao'															, ; //X3_CBOX
  ''																		, ; //X3_CBOXSPA
  ''																		, ; //X3_CBOXENG
  ''																		, ; //X3_PICTVAR
  ''																		, ; //X3_WHEN
  ''																		, ; //X3_INIBRW
  ''																		, ; //X3_GRPSXG
  ''																		, ; //X3_FOLDER
  ''																		, ; //X3_CONDSQL
  ''																		, ; //X3_CHKSQL
  ''																		, ; //X3_IDXSRV
  ''																		, ; //X3_ORTOGRA
  ''																		, ; //X3_TELA
  ''																		, ; //X3_POSLGT
  ''																		, ; //X3_IDXFLD
  ''																		, ; //X3_AGRUP
  ''																		, ; //X3_MODAL
  ''																		} ) //X3_PYME

  aAdd( aSX3, { ;
    'Z20'																	, ; //X3_ARQUIVO
  '23'																	, ; //X3_ORDEM
  'Z20_USRINC'															, ; //X3_CAMPO
  'C'																		, ; //X3_TIPO
  40																		, ; //X3_TAMANHO
  0																		, ; //X3_DECIMAL
  'Inclusao'																, ; //X3_TITULO
  'Inclusao'																, ; //X3_TITSPA
  'Inclusao'																, ; //X3_TITENG
  'Inclusao'																, ; //X3_DESCRIC
  'Inclusao'																, ; //X3_DESCSPA
  'Inclusao'																, ; //X3_DESCENG
  '@!'																	, ; //X3_PICTURE
  ''																		, ; //X3_VALID
  Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
    Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
    Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, ; //X3_USADO
  ''																		, ; //X3_RELACAO
  ''																		, ; //X3_F3
  0																		, ; //X3_NIVEL
  Chr(254) + Chr(192)														, ; //X3_RESERV
  ''																		, ; //X3_CHECK
  ''																		, ; //X3_TRIGGER
  'U'																		, ; //X3_PROPRI
  'S'																		, ; //X3_BROWSE
  'A'																		, ; //X3_VISUAL
  'R'																		, ; //X3_CONTEXT
  ''																		, ; //X3_OBRIGAT
  ''																		, ; //X3_VLDUSER
  ''																		, ; //X3_CBOX
  ''																		, ; //X3_CBOXSPA
  ''																		, ; //X3_CBOXENG
  ''																		, ; //X3_PICTVAR
  ''																		, ; //X3_WHEN
  ''																		, ; //X3_INIBRW
  ''																		, ; //X3_GRPSXG
  ''																		, ; //X3_FOLDER
  ''																		, ; //X3_CONDSQL
  ''																		, ; //X3_CHKSQL
  ''																		, ; //X3_IDXSRV
  ''																		, ; //X3_ORTOGRA
  ''																		, ; //X3_TELA
  ''																		, ; //X3_POSLGT
  ''																		, ; //X3_IDXFLD
  ''																		, ; //X3_AGRUP
  ''																		, ; //X3_MODAL
  ''																		} ) //X3_PYME

  aAdd( aSX3, { ;
    'Z20'																	, ; //X3_ARQUIVO
  '24'																	, ; //X3_ORDEM
  'Z20_USRALT'															, ; //X3_CAMPO
  'C'																		, ; //X3_TIPO
  40																		, ; //X3_TAMANHO
  0																		, ; //X3_DECIMAL
  'Alteracao'																, ; //X3_TITULO
  'Alteracao'																, ; //X3_TITSPA
  'Alteracao'																, ; //X3_TITENG
  'Alteracao'																, ; //X3_DESCRIC
  'Alteracao'																, ; //X3_DESCSPA
  'Alteracao'																, ; //X3_DESCENG
  '@!'																	, ; //X3_PICTURE
  ''																		, ; //X3_VALID
  Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
    Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
    Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, ; //X3_USADO
  ''																		, ; //X3_RELACAO
  ''																		, ; //X3_F3
  0																		, ; //X3_NIVEL
  Chr(254) + Chr(192)														, ; //X3_RESERV
  ''																		, ; //X3_CHECK
  ''																		, ; //X3_TRIGGER
  'U'																		, ; //X3_PROPRI
  'S'																		, ; //X3_BROWSE
  'A'																		, ; //X3_VISUAL
  'R'																		, ; //X3_CONTEXT
  ''																		, ; //X3_OBRIGAT
  ''																		, ; //X3_VLDUSER
  ''																		, ; //X3_CBOX
  ''																		, ; //X3_CBOXSPA
  ''																		, ; //X3_CBOXENG
  ''																		, ; //X3_PICTVAR
  ''																		, ; //X3_WHEN
  ''																		, ; //X3_INIBRW
  ''																		, ; //X3_GRPSXG
  ''																		, ; //X3_FOLDER
  ''																		, ; //X3_CONDSQL
  ''																		, ; //X3_CHKSQL
  ''																		, ; //X3_IDXSRV
  ''																		, ; //X3_ORTOGRA
  ''																		, ; //X3_TELA
  ''																		, ; //X3_POSLGT
  ''																		, ; //X3_IDXFLD
  ''																		, ; //X3_AGRUP
  ''																		, ; //X3_MODAL
  ''																		} ) //X3_PYME

//
// Campos Tabela Z21
//
  aAdd( aSX3, { ;
    'Z21'																	, ; //X3_ARQUIVO
  '01'																	, ; //X3_ORDEM
  'Z21_FILIAL'															, ; //X3_CAMPO
  'C'																		, ; //X3_TIPO
  2																		, ; //X3_TAMANHO
  0																		, ; //X3_DECIMAL
  'Filial'																, ; //X3_TITULO
  'Sucursal'																, ; //X3_TITSPA
  'Branch'																, ; //X3_TITENG
  'Filial do Sistema'														, ; //X3_DESCRIC
  'Sucursal'																, ; //X3_DESCSPA
  'Branch of the System'													, ; //X3_DESCENG
  '@!'																	, ; //X3_PICTURE
  ''																		, ; //X3_VALID
  Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
    Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
    Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128)					, ; //X3_USADO
  ''																		, ; //X3_RELACAO
  ''																		, ; //X3_F3
  1																		, ; //X3_NIVEL
  Chr(254) + Chr(192)														, ; //X3_RESERV
  ''																		, ; //X3_CHECK
  ''																		, ; //X3_TRIGGER
  'U'																		, ; //X3_PROPRI
  'N'																		, ; //X3_BROWSE
  ''																		, ; //X3_VISUAL
  ''																		, ; //X3_CONTEXT
  ''																		, ; //X3_OBRIGAT
  ''																		, ; //X3_VLDUSER
  ''																		, ; //X3_CBOX
  ''																		, ; //X3_CBOXSPA
  ''																		, ; //X3_CBOXENG
  ''																		, ; //X3_PICTVAR
  ''																		, ; //X3_WHEN
  ''																		, ; //X3_INIBRW
  '033'																	, ; //X3_GRPSXG
  ''																		, ; //X3_FOLDER
  ''																		, ; //X3_CONDSQL
  ''																		, ; //X3_CHKSQL
  ''																		, ; //X3_IDXSRV
  ''																		, ; //X3_ORTOGRA
  ''																		, ; //X3_TELA
  ''																		, ; //X3_POSLGT
  ''																		, ; //X3_IDXFLD
  ''																		, ; //X3_AGRUP
  ''																		, ; //X3_MODAL
  ''																		} ) //X3_PYME

  aAdd( aSX3, { ;
    'Z21'																	, ; //X3_ARQUIVO
  '02'																	, ; //X3_ORDEM
  'Z21_TOKEN'																, ; //X3_CAMPO
  'C'																		, ; //X3_TIPO
  40																		, ; //X3_TAMANHO
  0																		, ; //X3_DECIMAL
  'Token'																	, ; //X3_TITULO
  'Token'																	, ; //X3_TITSPA
  'Token'																	, ; //X3_TITENG
  'Token de autenticacao'													, ; //X3_DESCRIC
  'Token de autenticacao'													, ; //X3_DESCSPA
  'Token de autenticacao'													, ; //X3_DESCENG
  '@!'																	, ; //X3_PICTURE
  ''																		, ; //X3_VALID
  Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
    Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
    Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, ; //X3_USADO
  ''																		, ; //X3_RELACAO
  ''																		, ; //X3_F3
  0																		, ; //X3_NIVEL
  Chr(254) + Chr(192)														, ; //X3_RESERV
  ''																		, ; //X3_CHECK
  ''																		, ; //X3_TRIGGER
  'U'																		, ; //X3_PROPRI
  'N'																		, ; //X3_BROWSE
  'V'																		, ; //X3_VISUAL
  'R'																		, ; //X3_CONTEXT
  ''																		, ; //X3_OBRIGAT
  ''																		, ; //X3_VLDUSER
  ''																		, ; //X3_CBOX
  ''																		, ; //X3_CBOXSPA
  ''																		, ; //X3_CBOXENG
  ''																		, ; //X3_PICTVAR
  ''																		, ; //X3_WHEN
  ''																		, ; //X3_INIBRW
  ''																		, ; //X3_GRPSXG
  ''																		, ; //X3_FOLDER
  ''																		, ; //X3_CONDSQL
  ''																		, ; //X3_CHKSQL
  ''																		, ; //X3_IDXSRV
  'N'																		, ; //X3_ORTOGRA
  ''																		, ; //X3_TELA
  ''																		, ; //X3_POSLGT
  'N'																		, ; //X3_IDXFLD
  ''																		, ; //X3_AGRUP
  ''																		, ; //X3_MODAL
  ''																		} ) //X3_PYME

  aAdd( aSX3, { ;
    'Z21'																	, ; //X3_ARQUIVO
  '03'																	, ; //X3_ORDEM
  'Z21_USUARI'															, ; //X3_CAMPO
  'C'																		, ; //X3_TIPO
  6																		, ; //X3_TAMANHO
  0																		, ; //X3_DECIMAL
  'Cod. Usuario'															, ; //X3_TITULO
  'Cod. Usuario'															, ; //X3_TITSPA
  'Cod. Usuario'															, ; //X3_TITENG
  'Codigo do Usuario'														, ; //X3_DESCRIC
  'Codigo do Usuario'														, ; //X3_DESCSPA
  'Codigo do Usuario'														, ; //X3_DESCENG
  '@!'																	, ; //X3_PICTURE
  ''																		, ; //X3_VALID
  Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
    Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
    Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, ; //X3_USADO
  ''																		, ; //X3_RELACAO
  ''																		, ; //X3_F3
  0																		, ; //X3_NIVEL
  Chr(254) + Chr(192)														, ; //X3_RESERV
  ''																		, ; //X3_CHECK
  ''																		, ; //X3_TRIGGER
  'U'																		, ; //X3_PROPRI
  'N'																		, ; //X3_BROWSE
  'V'																		, ; //X3_VISUAL
  'R'																		, ; //X3_CONTEXT
  ''																		, ; //X3_OBRIGAT
  ''																		, ; //X3_VLDUSER
  ''																		, ; //X3_CBOX
  ''																		, ; //X3_CBOXSPA
  ''																		, ; //X3_CBOXENG
  ''																		, ; //X3_PICTVAR
  ''																		, ; //X3_WHEN
  ''																		, ; //X3_INIBRW
  ''																		, ; //X3_GRPSXG
  ''																		, ; //X3_FOLDER
  ''																		, ; //X3_CONDSQL
  ''																		, ; //X3_CHKSQL
  ''																		, ; //X3_IDXSRV
  'N'																		, ; //X3_ORTOGRA
  ''																		, ; //X3_TELA
  ''																		, ; //X3_POSLGT
  'N'																		, ; //X3_IDXFLD
  ''																		, ; //X3_AGRUP
  ''																		, ; //X3_MODAL
  ''																		} ) //X3_PYME

  aAdd( aSX3, { ;
    'Z21'																	, ; //X3_ARQUIVO
  '04'																	, ; //X3_ORDEM
  'Z21_VALIDA'															, ; //X3_CAMPO
  'D'																		, ; //X3_TIPO
  8																		, ; //X3_TAMANHO
  0																		, ; //X3_DECIMAL
  'Dt. Validade'															, ; //X3_TITULO
  'Dt. Validade'															, ; //X3_TITSPA
  'Dt. Validade'															, ; //X3_TITENG
  'Data de Validade'														, ; //X3_DESCRIC
  'Data de Validade'														, ; //X3_DESCSPA
  'Data de Validade'														, ; //X3_DESCENG
  ''																		, ; //X3_PICTURE
  ''																		, ; //X3_VALID
  Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
    Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(128) + ;
    Chr(128) + Chr(128) + Chr(128) + Chr(128) + Chr(160)					, ; //X3_USADO
  ''																		, ; //X3_RELACAO
  ''																		, ; //X3_F3
  0																		, ; //X3_NIVEL
  Chr(254) + Chr(192)														, ; //X3_RESERV
  ''																		, ; //X3_CHECK
  ''																		, ; //X3_TRIGGER
  'U'																		, ; //X3_PROPRI
  'N'																		, ; //X3_BROWSE
  'V'																		, ; //X3_VISUAL
  'R'																		, ; //X3_CONTEXT
  ''																		, ; //X3_OBRIGAT
  ''																		, ; //X3_VLDUSER
  ''																		, ; //X3_CBOX
  ''																		, ; //X3_CBOXSPA
  ''																		, ; //X3_CBOXENG
  ''																		, ; //X3_PICTVAR
  ''																		, ; //X3_WHEN
  ''																		, ; //X3_INIBRW
  ''																		, ; //X3_GRPSXG
  ''																		, ; //X3_FOLDER
  ''																		, ; //X3_CONDSQL
  ''																		, ; //X3_CHKSQL
  ''																		, ; //X3_IDXSRV
  'N'																		, ; //X3_ORTOGRA
  ''																		, ; //X3_TELA
  ''																		, ; //X3_POSLGT
  'N'																		, ; //X3_IDXFLD
  ''																		, ; //X3_AGRUP
  ''																		, ; //X3_MODAL
  ''																		} ) //X3_PYME


//
// Atualizando dicionário
//
  nPosArq := aScan( aEstrut, { |x| AllTrim( x[1] ) == "X3_ARQUIVO" } )
  nPosOrd := aScan( aEstrut, { |x| AllTrim( x[1] ) == "X3_ORDEM"   } )
  nPosCpo := aScan( aEstrut, { |x| AllTrim( x[1] ) == "X3_CAMPO"   } )
  nPosTam := aScan( aEstrut, { |x| AllTrim( x[1] ) == "X3_TAMANHO" } )
  nPosSXG := aScan( aEstrut, { |x| AllTrim( x[1] ) == "X3_GRPSXG"  } )
  nPosVld := aScan( aEstrut, { |x| AllTrim( x[1] ) == "X3_VALID"   } )

  aSort( aSX3,,, { |x,y| x[nPosArq]+x[nPosOrd]+x[nPosCpo] < y[nPosArq]+y[nPosOrd]+y[nPosCpo] } )

  oProcess:SetRegua2( Len( aSX3 ) )

  dbSelectArea( "SX3" )
  dbSetOrder( 2 )
  cAliasAtu := ""

  For nI := 1 To Len( aSX3 )

    //
    // Verifica se o campo faz parte de um grupo e ajusta tamanho
    //
    If !Empty( aSX3[nI][nPosSXG] )
      SXG->( dbSetOrder( 1 ) )
      If SXG->( MSSeek( aSX3[nI][nPosSXG] ) )
        If aSX3[nI][nPosTam] <> SXG->XG_SIZE
          aSX3[nI][nPosTam] := SXG->XG_SIZE
          AutoGrLog( "O tamanho do campo " + aSX3[nI][nPosCpo] + " NÃO atualizado e foi mantido em [" + ;
            AllTrim( Str( SXG->XG_SIZE ) ) + "]" + CRLF + ;
            " por pertencer ao grupo de campos [" + SXG->XG_GRUPO + "]" + CRLF )
        EndIf
      EndIf
    EndIf

    SX3->( dbSetOrder( 2 ) )

    If !( aSX3[nI][nPosArq] $ cAlias )
      cAlias += aSX3[nI][nPosArq] + "/"
      aAdd( aArqUpd, aSX3[nI][nPosArq] )
    EndIf

    If !SX3->( dbSeek( PadR( aSX3[nI][nPosCpo], nTamSeek ) ) )

      //
      // Busca ultima ocorrencia do alias
      //
      If ( aSX3[nI][nPosArq] <> cAliasAtu )
        cSeqAtu   := "00"
        cAliasAtu := aSX3[nI][nPosArq]

        dbSetOrder( 1 )
        SX3->( dbSeek( cAliasAtu + "ZZ", .T. ) )
        dbSkip( -1 )

        If ( SX3->X3_ARQUIVO == cAliasAtu )
          cSeqAtu := SX3->X3_ORDEM
        EndIf

        nSeqAtu := Val( RetAsc( cSeqAtu, 3, .F. ) )
      EndIf

      nSeqAtu++
      cSeqAtu := RetAsc( Str( nSeqAtu ), 2, .T. )

      RecLock( "SX3", .T. )
      For nJ := 1 To Len( aSX3[nI] )
        If     nJ == nPosOrd  // Ordem
          SX3->( FieldPut( FieldPos( aEstrut[nJ][1] ), cSeqAtu ) )

        ElseIf aEstrut[nJ][2] > 0
          SX3->( FieldPut( FieldPos( aEstrut[nJ][1] ), aSX3[nI][nJ] ) )

        EndIf
      Next nJ

      dbCommit()
      MsUnLock()

      AutoGrLog( "Criado campo " + aSX3[nI][nPosCpo] )

    EndIf

    oProcess:IncRegua2( "Atualizando Campos de Tabelas (SX3)..." )

  Next nI

  AutoGrLog( CRLF + "Final da Atualização" + " SX3" + CRLF + Replicate( "-", 128 ) + CRLF )

Return NIL


//--------------------------------------------------------------------
/*/{Protheus.doc} FSAtuSIX
Função de processamento da gravação do SIX - Indices

@author TOTVS Protheus
@since  06/04/2020
@obs    Gerado por EXPORDIC - V.6.3.0.1 EFS / Upd. V.5.0.0 EFS
@version 1.0
/*/
//--------------------------------------------------------------------
Static Function FSAtuSIX()
  Local aEstrut   := {}
  Local aSIX      := {}
  Local lAlt      := .F.
  Local lDelInd   := .F.
  Local nI        := 0
  Local nJ        := 0

  AutoGrLog( "Ínicio da Atualização" + " SIX" + CRLF )

  aEstrut := { "INDICE" , "ORDEM" , "CHAVE", "DESCRICAO", "DESCSPA"  , ;
    "DESCENG", "PROPRI", "F3"   , "NICKNAME" , "SHOWPESQ" }

//
// Tabela Z20
//
  aAdd( aSIX, { ;
    'Z20'																	, ; //INDICE
  '1'																		, ; //ORDEM
  'Z20_FILIAL+Z20_CODROT+Z20_IDUSR'										, ; //CHAVE
  'Cod Rotina+Id Usuario'													, ; //DESCRICAO
  'Cod Rotina+Id Usuario'													, ; //DESCSPA
  'Cod Rotina+Id Usuario'													, ; //DESCENG
  'U'																		, ; //PROPRI
  ''																		, ; //F3
  ''																		, ; //NICKNAME
  'S'																		} ) //SHOWPESQ

  aAdd( aSIX, { ;
    'Z20'																	, ; //INDICE
  '2'																		, ; //ORDEM
  'Z20_FILIAL+Z20_IDUSR+Z20_CODROT'										, ; //CHAVE
  'Id Usuario+Cod Rotina'													, ; //DESCRICAO
  'Id Usuario+Cod Rotina'													, ; //DESCSPA
  'Id Usuario+Cod Rotina'													, ; //DESCENG
  'U'																		, ; //PROPRI
  ''																		, ; //F3
  ''																		, ; //NICKNAME
  'S'																		} ) //SHOWPESQ

  aAdd( aSIX, { ;
    'Z20'																	, ; //INDICE
  '3'																		, ; //ORDEM
  'Z20_ROTINA+Z20_IDUSR'													, ; //CHAVE
  'Rotina+Id Usuario'														, ; //DESCRICAO
  'Rotina+Id Usuario'														, ; //DESCSPA
  'Rotina+Id Usuario'														, ; //DESCENG
  'U'																		, ; //PROPRI
  ''																		, ; //F3
  ''																		, ; //NICKNAME
  'S'																		} ) //SHOWPESQ

//
// Tabela Z21
//
  aAdd( aSIX, { ;
    'Z21'																	, ; //INDICE
  '1'																		, ; //ORDEM
  'Z21_FILIAL+Z21_TOKEN'													, ; //CHAVE
  'Token'																	, ; //DESCRICAO
  'Token'																	, ; //DESCSPA
  'Token'																	, ; //DESCENG
  'U'																		, ; //PROPRI
  ''																		, ; //F3
  ''																		, ; //NICKNAME
  'S'																		} ) //SHOWPESQ

//
// Atualizando dicionário
//
  oProcess:SetRegua2( Len( aSIX ) )

  dbSelectArea( "SIX" )
  SIX->( dbSetOrder( 1 ) )

  For nI := 1 To Len( aSIX )

    lAlt    := .F.
    lDelInd := .F.

    If !SIX->( dbSeek( aSIX[nI][1] + aSIX[nI][2] ) )
      AutoGrLog( "Índice criado " + aSIX[nI][1] + "/" + aSIX[nI][2] + " - " + aSIX[nI][3] )
    Else
      lAlt := .T.
      aAdd( aArqUpd, aSIX[nI][1] )
      If !StrTran( Upper( AllTrim( CHAVE )       ), " ", "" ) == ;
          StrTran( Upper( AllTrim( aSIX[nI][3] ) ), " ", "" )
        AutoGrLog( "Chave do índice alterado " + aSIX[nI][1] + "/" + aSIX[nI][2] + " - " + aSIX[nI][3] )
        lDelInd := .T. // Se for alteração precisa apagar o indice do banco
      EndIf
    EndIf

    RecLock( "SIX", !lAlt )
    For nJ := 1 To Len( aSIX[nI] )
      If FieldPos( aEstrut[nJ] ) > 0
        FieldPut( FieldPos( aEstrut[nJ] ), aSIX[nI][nJ] )
      EndIf
    Next nJ
    MsUnLock()

    dbCommit()

    If lDelInd
      TcInternal( 60, RetSqlName( aSIX[nI][1] ) + "|" + RetSqlName( aSIX[nI][1] ) + aSIX[nI][2] )
    EndIf

    oProcess:IncRegua2( "Atualizando índices..." )

  Next nI

  AutoGrLog( CRLF + "Final da Atualização" + " SIX" + CRLF + Replicate( "-", 128 ) + CRLF )

Return NIL


//--------------------------------------------------------------------
/*/{Protheus.doc} EscEmpresa
Função genérica para escolha de Empresa, montada pelo SM0

@return aRet Vetor contendo as seleções feitas.
             Se não for marcada nenhuma o vetor volta vazio

@author Ernani Forastieri
@since  27/09/2004
@version 1.0
/*/
//--------------------------------------------------------------------
Static Function EscEmpresa()

//---------------------------------------------
// Parâmetro  nTipo
// 1 - Monta com Todas Empresas/Filiais
// 2 - Monta só com Empresas
// 3 - Monta só com Filiais de uma Empresa
//
// Parâmetro  aMarcadas
// Vetor com Empresas/Filiais pré marcadas
//
// Parâmetro  cEmpSel
// Empresa que será usada para montar seleção
//---------------------------------------------
  Local   aRet      := {}
  Local   aSalvAmb  := GetArea()
  Local   aSalvSM0  := {}
  Local   aVetor    := {}
  Local   cMascEmp  := "??"
  Local   cVar      := ""
  Local   lChk      := .F.
  Local   lOk       := .F.
  Local   lTeveMarc := .F.
  Local   oNo       := LoadBitmap( GetResources(), "LBNO" )
  Local   oOk       := LoadBitmap( GetResources(), "LBOK" )
  Local   oDlg, oChkMar, oLbx, oMascEmp, oSay
  Local   oButDMar, oButInv, oButMarc, oButOk, oButCanc

  Local   aMarcadas := {}


  If !MyOpenSm0(.F.)
    Return aRet
  EndIf


  dbSelectArea( "SM0" )
  aSalvSM0 := SM0->( GetArea() )
  dbSetOrder( 1 )
  dbGoTop()

  While !SM0->( EOF() )

    If aScan( aVetor, {|x| x[2] == SM0->M0_CODIGO} ) == 0
      aAdd(  aVetor, { aScan( aMarcadas, {|x| x[1] == SM0->M0_CODIGO .and. x[2] == SM0->M0_CODFIL} ) > 0, SM0->M0_CODIGO, SM0->M0_CODFIL, SM0->M0_NOME, SM0->M0_FILIAL } )
    EndIf

    dbSkip()
  End

  RestArea( aSalvSM0 )

  Define MSDialog  oDlg Title "" From 0, 0 To 280, 395 Pixel

  oDlg:cToolTip := "Tela para Múltiplas Seleções de Empresas/Filiais"

  oDlg:cTitle   := "Selecione a(s) Empresa(s) para Atualização"

  @ 10, 10 Listbox  oLbx Var  cVar Fields Header " ", " ", "Empresa" Size 178, 095 Of oDlg Pixel
  oLbx:SetArray(  aVetor )
  oLbx:bLine := {|| {IIf( aVetor[oLbx:nAt, 1], oOk, oNo ), ;
    aVetor[oLbx:nAt, 2], ;
    aVetor[oLbx:nAt, 4]}}
  oLbx:BlDblClick := { || aVetor[oLbx:nAt, 1] := !aVetor[oLbx:nAt, 1], VerTodos( aVetor, @lChk, oChkMar ), oChkMar:Refresh(), oLbx:Refresh()}
  oLbx:cToolTip   :=  oDlg:cTitle
  oLbx:lHScroll   := .F. // NoScroll

  @ 112, 10 CheckBox oChkMar Var  lChk Prompt "Todos" Message "Marca / Desmarca"+ CRLF + "Todos" Size 40, 007 Pixel Of oDlg;
    on Click MarcaTodos( lChk, @aVetor, oLbx )

// Marca/Desmarca por mascara
  @ 113, 51 Say   oSay Prompt "Empresa" Size  40, 08 Of oDlg Pixel
  @ 112, 80 MSGet oMascEmp Var  cMascEmp Size  05, 05 Pixel Picture "@!"  Valid (  cMascEmp := StrTran( cMascEmp, " ", "?" ), oMascEmp:Refresh(), .T. ) ;
    Message "Máscara Empresa ( ?? )"  Of oDlg
  oSay:cToolTip := oMascEmp:cToolTip

  @ 128, 10 Button oButInv    Prompt "&Inverter"  Size 32, 12 Pixel Action ( InvSelecao( @aVetor, oLbx, @lChk, oChkMar ), VerTodos( aVetor, @lChk, oChkMar ) ) ;
    Message "Inverter Seleção" Of oDlg
  oButInv:SetCss( CSSBOTAO )
  @ 128, 50 Button oButMarc   Prompt "&Marcar"    Size 32, 12 Pixel Action ( MarcaMas( oLbx, aVetor, cMascEmp, .T. ), VerTodos( aVetor, @lChk, oChkMar ) ) ;
    Message "Marcar usando" + CRLF + "máscara ( ?? )"    Of oDlg
  oButMarc:SetCss( CSSBOTAO )
  @ 128, 80 Button oButDMar   Prompt "&Desmarcar" Size 32, 12 Pixel Action ( MarcaMas( oLbx, aVetor, cMascEmp, .F. ), VerTodos( aVetor, @lChk, oChkMar ) ) ;
    Message "Desmarcar usando" + CRLF + "máscara ( ?? )" Of oDlg
  oButDMar:SetCss( CSSBOTAO )
  @ 112, 157  Button oButOk   Prompt "Processar"  Size 32, 12 Pixel Action (  RetSelecao( @aRet, aVetor ), IIf( Len( aRet ) > 0, oDlg:End(), MsgStop( "Ao menos um grupo deve ser selecionado", "PTNUPD01" ) ) ) ;
    Message "Confirma a seleção e efetua" + CRLF + "o processamento" Of oDlg
  oButOk:SetCss( CSSBOTAO )
  @ 128, 157  Button oButCanc Prompt "Cancelar"   Size 32, 12 Pixel Action ( IIf( lTeveMarc, aRet :=  aMarcadas, .T. ), oDlg:End() ) ;
    Message "Cancela o processamento" + CRLF + "e abandona a aplicação" Of oDlg
  oButCanc:SetCss( CSSBOTAO )

  Activate MSDialog  oDlg Center

  RestArea( aSalvAmb )
  dbSelectArea( "SM0" )
  dbCloseArea()

Return  aRet


//--------------------------------------------------------------------
/*/{Protheus.doc} MarcaTodos
Função auxiliar para marcar/desmarcar todos os ítens do ListBox ativo

@param lMarca  Contéudo para marca .T./.F.
@param aVetor  Vetor do ListBox
@param oLbx    Objeto do ListBox

@author Ernani Forastieri
@since  27/09/2004
@version 1.0
/*/
//--------------------------------------------------------------------
Static Function MarcaTodos( lMarca, aVetor, oLbx )
  Local  nI := 0

  For nI := 1 To Len( aVetor )
    aVetor[nI][1] := lMarca
  Next nI

  oLbx:Refresh()

Return NIL


//--------------------------------------------------------------------
/*/{Protheus.doc} InvSelecao
Função auxiliar para inverter a seleção do ListBox ativo

@param aVetor  Vetor do ListBox
@param oLbx    Objeto do ListBox

@author Ernani Forastieri
@since  27/09/2004
@version 1.0
/*/
//--------------------------------------------------------------------
Static Function InvSelecao( aVetor, oLbx )
  Local  nI := 0

  For nI := 1 To Len( aVetor )
    aVetor[nI][1] := !aVetor[nI][1]
  Next nI

  oLbx:Refresh()

Return NIL


//--------------------------------------------------------------------
/*/{Protheus.doc} RetSelecao
Função auxiliar que monta o retorno com as seleções

@param aRet    Array que terá o retorno das seleções (é alterado internamente)
@param aVetor  Vetor do ListBox

@author Ernani Forastieri
@since  27/09/2004
@version 1.0
/*/
//--------------------------------------------------------------------
Static Function RetSelecao( aRet, aVetor )
  Local  nI    := 0

  aRet := {}
  For nI := 1 To Len( aVetor )
    If aVetor[nI][1]
      aAdd( aRet, { aVetor[nI][2] , aVetor[nI][3], aVetor[nI][2] +  aVetor[nI][3] } )
    EndIf
  Next nI

Return NIL


//--------------------------------------------------------------------
/*/{Protheus.doc} MarcaMas
Função para marcar/desmarcar usando máscaras

@param oLbx     Objeto do ListBox
@param aVetor   Vetor do ListBox
@param cMascEmp Campo com a máscara (???)
@param lMarDes  Marca a ser atribuída .T./.F.

@author Ernani Forastieri
@since  27/09/2004
@version 1.0
/*/
//--------------------------------------------------------------------
Static Function MarcaMas( oLbx, aVetor, cMascEmp, lMarDes )
  Local cPos1 := SubStr( cMascEmp, 1, 1 )
  Local cPos2 := SubStr( cMascEmp, 2, 1 )
  Local nPos  := oLbx:nAt
  Local nZ    := 0

  For nZ := 1 To Len( aVetor )
    If cPos1 == "?" .or. SubStr( aVetor[nZ][2], 1, 1 ) == cPos1
      If cPos2 == "?" .or. SubStr( aVetor[nZ][2], 2, 1 ) == cPos2
        aVetor[nZ][1] := lMarDes
      EndIf
    EndIf
  Next

  oLbx:nAt := nPos
  oLbx:Refresh()

Return NIL


//--------------------------------------------------------------------
/*/{Protheus.doc} VerTodos
Função auxiliar para verificar se estão todos marcados ou não

@param aVetor   Vetor do ListBox
@param lChk     Marca do CheckBox do marca todos (referncia)
@param oChkMar  Objeto de CheckBox do marca todos

@author Ernani Forastieri
@since  27/09/2004
@version 1.0
/*/
//--------------------------------------------------------------------
Static Function VerTodos( aVetor, lChk, oChkMar )
  Local lTTrue := .T.
  Local nI     := 0

  For nI := 1 To Len( aVetor )
    lTTrue := IIf( !aVetor[nI][1], .F., lTTrue )
  Next nI

  lChk := IIf( lTTrue, .T., .F. )
  oChkMar:Refresh()

Return NIL


//--------------------------------------------------------------------
/*/{Protheus.doc} MyOpenSM0
Função de processamento abertura do SM0 modo exclusivo

@author TOTVS Protheus
@since  06/04/2020
@obs    Gerado por EXPORDIC - V.6.3.0.1 EFS / Upd. V.5.0.0 EFS
@version 1.0
/*/
//--------------------------------------------------------------------
Static Function MyOpenSM0(lShared)
  Local lOpen := .F.
  Local nLoop := 0

  If FindFunction( "OpenSM0Excl" )
    For nLoop := 1 To 20
      If OpenSM0Excl(,.F.)
        lOpen := .T.
        Exit
      EndIf
      Sleep( 500 )
    Next nLoop
  Else
    For nLoop := 1 To 20
      dbUseArea( .T., , "SIGAMAT.EMP", "SM0", lShared, .F. )

      If !Empty( Select( "SM0" ) )
        lOpen := .T.
        dbSetIndex( "SIGAMAT.IND" )
        Exit
      EndIf
      Sleep( 500 )
    Next nLoop
  EndIf

  If !lOpen
    MsgStop( "Não foi possível a abertura da tabela " + ;
      IIf( lShared, "de empresas (SM0).", "de empresas (SM0) de forma exclusiva." ), "ATENÇÃO" )
  EndIf

Return lOpen


//--------------------------------------------------------------------
/*/{Protheus.doc} LeLog
Função de leitura do LOG gerado com limitacao de string

@author TOTVS Protheus
@since  06/04/2020
@obs    Gerado por EXPORDIC - V.6.3.0.1 EFS / Upd. V.5.0.0 EFS
@version 1.0
/*/
//--------------------------------------------------------------------
Static Function LeLog()
  Local cRet  := ""
  Local cFile := NomeAutoLog()
  Local cAux  := ""

  FT_FUSE( cFile )
  FT_FGOTOP()

  While !FT_FEOF()

    cAux := FT_FREADLN()

    If Len( cRet ) + Len( cAux ) < 1048000
      cRet += cAux + CRLF
    Else
      cRet += CRLF
      cRet += Replicate( "=" , 128 ) + CRLF
      cRet += "Tamanho de exibição maxima do LOG alcançado." + CRLF
      cRet += "LOG Completo no arquivo " + cFile + CRLF
      cRet += Replicate( "=" , 128 ) + CRLF
      Exit
    EndIf

    FT_FSKIP()
  End

  FT_FUSE()

Return cRet


/////////////////////////////////////////////////////////////////////////////
