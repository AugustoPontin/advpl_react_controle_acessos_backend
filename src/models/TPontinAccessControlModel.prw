#include 'totvs.ch'


//|Responsavel por montar o modelo de dados da Z20 |
Class TPontinAccessControlModel From LongClassName

  Data oObjZ20

  Method New() Constructor

EndClass


Method New() Class TPontinAccessControlModel

  Local aZ20Struct  := {}
  Local nI          := 0

  dbSelectArea("Z20")
  Z20->( dbSetOrder(1) )

  aZ20Struct  := Z20->( dbStruct() )

  ::oObjZ20 := JsonObject():New()

  ::oObjZ20['RECNO'] := 0

  For nI := 1 To Len(aZ20Struct)

    ::oObjZ20[ aZ20Struct[nI,1] ] := CriaVar( aZ20Struct[nI,1], .T. )

  Next nI

Return self