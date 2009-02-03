Function picklist:Object(l:TList)
	Return l.valueatindex(Rand(0,l.count()-1))
End Function

Function pickarr:Object(arr:Object[])
	Return arr[Rand(0,Len(arr)-1)]
End Function


Function crawldir:TList(path$,l:TList=Null)
	If Not l
		l:TList=New TList
	EndIf
	For t$=EachIn LoadDir(path)
		If Not (t="." Or t="..")
			fpath$=path+"/"+t
			Select FileType(fpath)
			Case 1
				l.addlast fpath
			Case 2
				crawldir fpath,l
			End Select
		EndIf
	Next
	Return l
End Function

Function filename$(path$)
	Local bits$[]=path.split("/")
	name$=bits[Len(bits)-1]
	c=Len(name)-1
	While c>=0 And name[c]<>46
		c:-1
	Wend
	If c=-1 Return name
	Return name[..c]
End Function

Function debugo(txt$)
	Print "  >> "+txt
End Function