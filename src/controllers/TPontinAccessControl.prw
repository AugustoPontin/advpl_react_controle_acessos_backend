#include 'totvs.ch'
#include 'restful.ch'


WSRESTFUL TPontinAccessControl DESCRIPTION "Serviço REST para controle de acesso dos usuarios"

  WSMETHOD GET DESCRIPTION "Retorna o cadastro de controle de acessos" ;
    WSSYNTAX "/TPontinAccessControl"

  WSMETHOD POST DESCRIPTION "Realiza o cadastro de controle de acessos" ;
    WSSYNTAX "/TPontinAccessControl"

  WSMETHOD DELETE DESCRIPTION "Deleta um cadastro de controle de acessos" ;
    WSSYNTAX "/TPontinAccessControl/{recno}"

  WSMETHOD PUT DESCRIPTION "Altera um cadastro de controle de acessos" ;
    WSSYNTAX "/TPontinAccessControl/{recno}"

END WSRESTFUL


WSMETHOD GET WSRECEIVE WSSERVICE TPontinAccessControl

  Local oDAO      := NIL
  Local oDados    := NIL

  ::SetContentType("application/json")

  oDados  := JsonObject():New()

  oDAO    := TPontinAccessControlDAO():New()
  oDados  := oDAO:ListarZ20()

  ::SetStatus(200)
  ::SetResponse( oDados:ToJson() )


Return .T.


WSMETHOD POST WSRECEIVE WSSERVICE TPontinAccessControl

  Local cBody     := ""
  Local oDAO      := Nil
  Local oRetorno  := Nil

  //|Recupera os dados do body |
  cBody := ::GetContent()

  //|Realiza a inclusão do registro |
  oDAO      := TPontinAccessControlDAO():New()
  oRetorno  := oDAO:CriarZ20(cBody)

  //|Defino que o retorno sera em JSON |
  ::SetContentType("application/json")

  ::SetStatus( oRetorno['CodRet'] )
  ::SetResponse( oRetorno:ToJson() )

Return .T.


WSMETHOD DELETE WSRECEIVE WSSERVICE TPontinAccessControl

  Local nRecno    := 0
  Local oDAO      := Nil
  Local oRetorno  := Nil

  //|Recupera o recno a ser deletado |
  If Len(::aURLParms) > 0

    nRecno  := Val(::aURLParms[1])

  EndIf

  //|Realiza a inclusão do registro |
  oDAO      := TPontinAccessControlDAO():New()
  oRetorno  := oDAO:RemoverZ20(nRecno)

  //|Defino que o retorno sera em JSON |
  ::SetContentType("application/json")

  ::SetStatus( oRetorno['CodRet'] )
  ::SetResponse( oRetorno:ToJson() )

Return .T.


WSMETHOD PUT WSRECEIVE WSSERVICE TPontinAccessControl

  Local nRecno    := 0
  Local cBody     := ""
  Local oDAO      := Nil
  Local oRetorno  := Nil

  //|Recupera o recno a ser deletado |
  If Len(::aURLParms) > 0

    nRecno  := Val(::aURLParms[1])

  EndIf

  //|Recupera os dados do body |
  cBody := ::GetContent()

  //|Realiza a inclusão do registro |
  oDAO      := TPontinAccessControlDAO():New()
  oRetorno  := oDAO:AlterarZ20(nRecno, cBody)

  //|Defino que o retorno sera em JSON |
  ::SetContentType("application/json")

  ::SetStatus( oRetorno['CodRet'] )
  ::SetResponse( oRetorno:ToJson() )

Return .T.