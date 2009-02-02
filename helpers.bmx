Function picklist:Object(l:TList)
	Return l.valueatindex(Rand(0,l.count()-1))
End Function

Function pickarr:Object(arr:Object[])
	Return arr[Rand(0,Len(arr)-1)]
End Function
