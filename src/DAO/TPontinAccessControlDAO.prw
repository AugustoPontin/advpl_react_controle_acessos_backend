#include 'totvs.ch'


//|Responsavel por acesso ao banco de dados |
Class TPontinAccessControlDAO From LongClassName

  Data oModel

  Method New() Constructor
  Method ListarZ20()
  Method CriarZ20()
  Method RemoverZ20()
  Method AlterarZ20()

EndClass


Method New() Class TPontinAccessControlDAO

  ::oModel  := TPontinAccessControlModel():New()

Return self


Method ListarZ20() Class TPontinAccessControlDAO

  Local oObjRet     := Nil
  Local oDados      := Nil
  Local aArea       := GetArea()
  Local aAreaZ20    := Z20->( GetArea() )
  Local aCampos     := {}
  Local aPermissao  := {}
  Local nPos        := 0
  Local nZ          := 0
  Local nCont       := 0

  dbSelectArea("Z20")
  Z20->( dbSetOrder(1) )
  Z20->( dbGoTop() )

  oObjRet   := JsonObject():New()

  //|Busca todos os campos do model |
  aCampos   := ::oModel:oObjZ20:GetNames()

  While !Z20->( EoF() )

    oDados  := TPontinAccessControlModel():New()

    aAdd( aPermissao, oDados:oObjZ20 )
    nPos  := Len(aPermissao)

    For nZ := 1 To Len(aCampos)

      If aCampos[nZ] == 'RECNO'
        aPermissao[ nPos, 'RECNO' ] := Z20->( Recno() )
      Else
        aPermissao[ nPos, aCampos[nZ] ]  := AlLTrim( &( 'Z20->' + aCampos[nZ] ) )
      EndIf

    Next nZ

    nCont++

    Z20->( dbSkip() )

  EndDO

  oObjRet['registros']  := nCont
  oOBjRet['result']     := JSonObject():New()
  oObjRet['result']     := aPermissao

  RestArea(aAreaZ20)
  RestArea(aArea)

Return oObjRet


Method CriarZ20(cDados) Class TPontinAccessControlDAO

  Local oResponse   := JsonObject():New()
  Local oBody       := JsonObject():New()
  Local aZ20Struct  := {}
  Local cErro       := ""
  Local cCampo      := ""
  Local nI          := 0

  //|Monto o objeto Json |
  oBody:FromJson(cDados)

  //|Valida o body enviado |
  If ValType(oBody) != "U" .And. ValType(cDados) != "U"

    //|Valida campos obrigatórios |
    If ValType( oBody['Z20_ROTINA'] ) == "U" .Or. Empty( oBody['Z20_ROTINA'] )
      cErro := "Z20_ROTINA obrigatorio \n "
    EndIf

    If ValType( oBody['Z20_IDUSR'] ) == "U" .Or. Empty( oBody['Z20_IDUSR'] )
      cErro += "Z20_IDUSR obrigatorio \n "
    EndIf

    //|Valida os campos de permissão |
    For nI := 1 To 15

      cCampo      := "Z20_NUM" + cValToChar(nI)

      If ValType( oBody[cCampo] ) == "U" .Or. Empty( oBody[cCampo] )
        cErro += cCampo + " obrigatorio \n "
      EndIf

    Next nI

  Else

    cErro := "Body invalido ou inexistente \n "

  EndIf

  //|Valida se já existe permissão para o usuario nessa rotina |
  dbSelectArea("Z20")
  Z20->( dbSetOrder(1) )
  If Z20->( dbSeek( xFilial("Z20") + oBody['Z20_CODROT'] + oBody['Z20_IDUSR'] ) )

    cErro := "Usuario informado ja possui permissoes nessa rotina \n "

  EndIf


  //|Realizo a inclusão do registro |
  If Empty(cErro)

    //|Para evitar erros, vamos nos basear no dicionario de dados |
    aZ20Struct  := Z20->( dbStruct() )

    RecLock("Z20", .T.)

    //|Monto o objeto JSON com a estrutura da Z20 |
    For nI := 1 To Len(aZ20Struct)

      cCampo      := aZ20Struct[nI,1]

      //|Valida se o campo existe e está com o tipo certo |
      If ValType( oBody[cCampo] ) == aZ20Struct[nI,2]
        Z20->&(  cCampo )   := oBody[cCampo]
      EndIf

    Next nI

    Z20->( MsUnLock() )

    oResponse['CodRet']   := 201
    oResponse['result']   := 'Registro incluido com sucesso'
    oResponse['RECNO']    := Z20->( Recno() )

  Else

    //|Retorna erros de validação |
    oResponse['CodRet']   := 400
    oResponse['error']    := JsonObject():new()
    oResponse['error']    := cErro

  EndIf

Return oResponse


Method RemoverZ20(nRecno) Class TPontinAccessControlDAO

  Local oResponse   := JsonObject():New()

  dbSelectArea("Z20")
  Z20->( dbSetOrder(1) )
  Z20->( dbGoTo(nRecno) )

  If !Z20->( EoF() )

    RecLock("Z20", .F.)
    Z20->( dbDelete() )
    Z20->( MsUnLock() )

    oResponse['CodRet']   := 200
    oResponse['result']   := 'Registro excluido com sucesso'

  Else

    //|Retorna erros de validação |
    oResponse['CodRet']   := 400
    oResponse['error']    := JsonObject():new()
    oResponse['error']    := 'Recno informado nao existe na base de dados'

  EndIf

Return oResponse


Method AlterarZ20(nRecno, cDados) Class TPontinAccessControlDAO

  Local oResponse   := JsonObject():New()
  Local oBody       := JsonObject():New()
  Local aZ20Struct  := {}
  Local cErro       := ""
  Local cCampo      := ""
  Local nI          := 0

  dbSelectArea("Z20")
  Z20->( dbSetOrder(1) )
  Z20->( dbGoTo(nRecno) )

  //|Valida se é um recno valido |
  If !Z20->( EoF() )

    //|Monto o objeto Json |
    oBody:FromJson(cDados)

    //|Valida o body enviado |
    If ValType(oBody) != "U" .And. ValType(cDados) != "U"

      //|Valida campos obrigatórios |
      If ValType( oBody['Z20_ROTINA'] ) != "U" .And. Empty( oBody['Z20_ROTINA'] )
        cErro := "Z20_ROTINA nao pode ser vazio \n "
      EndIf

      If ValType( oBody['Z20_IDUSR'] ) != "U" .And. Empty( oBody['Z20_IDUSR'] )
        cErro += "Z20_IDUSR nao pode ser vazio \n "
      EndIf

      //|Valida os campos de permissão |
      For nI := 1 To 15

        cCampo      := "Z20_NUM" + cValToChar(nI)

        If ValType( oBody[cCampo] ) != "U" .And. Empty( oBody[cCampo] )
          cErro += cCampo + " nao pode ser vazio \n "
        EndIf

      Next nI

    Else

      cErro := "Body invalido ou inexistente \n "

    EndIf

    //|Realiza a alteração do registro |
    If Empty(cErro)

      //|Para evitar erros, vamos nos basear no dicionario de dados |
      aZ20Struct  := Z20->( dbStruct() )

      RecLock("Z20", .F.)

      //|Monto o objeto JSON com a estrutura da Z20 |
      For nI := 1 To Len(aZ20Struct)

        cCampo      := aZ20Struct[nI,1]

        //|Valida se o campo existe e está com o tipo certo |
        If ValType( oBody[cCampo] ) == aZ20Struct[nI,2]
          Z20->&(  cCampo )   := oBody[cCampo]
        EndIf

      Next nI

      Z20->( MsUnLock() )

      oResponse['CodRet']   := 200
      oResponse['result']   := 'Registro alterado com sucesso'
      oResponse['RECNO']    := Z20->( Recno() )

    EndIf

  Else

    //|Retorna erros de validação |
    cErro := 'Recno informado nao existe na base de dados'

  EndIf

  If !Empty(cErro)

    //|Retorna erros de validação |
    oResponse['CodRet']   := 400
    oResponse['error']    := JsonObject():new()
    oResponse['error']    := cErro

  EndIf

Return oResponse