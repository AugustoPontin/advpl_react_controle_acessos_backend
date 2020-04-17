#INCLUDE "TOTVS.CH"
#INCLUDE "RESTFUL.CH"

WSRESTFUL helloworld DESCRIPTION "REST para hello world!"

  WSDATA name      AS STRING

  WSMETHOD GET DESCRIPTION "Exemplo de retorno de entidade(s)" ;
    WSSYNTAX "/helloworld || /helloworld/{name}"

END WSRESTFUL


WSMETHOD GET WSRECEIVE name WSSERVICE helloworld

  Local oJson     := Nil
  Local cRetorno  := "Hello World"

  //|Defino que o retorno ser em JSON |
  ::SetContentType("application/json")

  oJson := JsonObject():new()

  //|Caso exista, utilizo o parametro enviado |
  If Len(::aURLParms) > 0

    cRetorno  += ", " + ::aURLParms[1]

  EndIf

  cRetorno  += "!"

  oJson['result']   := cRetorno

  ::SetStatus(200)
  ::SetResponse(oJson:ToJson())

Return .T.

