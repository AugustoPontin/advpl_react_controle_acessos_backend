#include 'totvs.ch'
#include 'restful.ch'


WSRESTFUL TPontinAccessControl DESCRIPTION "Serviço REST para controle de acesso dos usuarios"

  WSMETHOD GET DESCRIPTION "Retorna o cadastro de controle de acessos" ;
    WSSYNTAX "/TPontinAccessControl"

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