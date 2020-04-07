#INCLUDE "TOTVS.CH"
#INCLUDE "RESTFUL.CH"

WSRESTFUL helloworld DESCRIPTION "REST para hello world!"

  WSDATA name      AS STRING

  WSMETHOD GET DESCRIPTION "Exemplo de retorno de entidade(s)" WSSYNTAX "/hello || /hello/{name}"

END WSRESTFUL

WSMETHOD GET WSRECEIVE name WSSERVICE helloworld

  Local cRetorno  := "Hello World"

  //|Defino que o retorno ser em JSON |
  ::SetContentType("application/json")

  //|Caso exista, utilizo o parametro enviado |
  If Len(::aURLParms) > 0

    cRetorno  += ", " + ::aURLParms[1]

  EndIf

  cRetorno  += "!"

  ::SetStatus(200)
  ::SetResponse('{"result": "' + cRetorno + '"}')

Return .T.