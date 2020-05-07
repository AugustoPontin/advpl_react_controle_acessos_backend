#include 'totvs.ch'


//|Responsavel por acesso ao banco de dados |
Class TPontinAccessControlDAO From LongClassName

  Data oModel

  Method New() Constructor
  Method ListarZ20()

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
