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

Rem
Function cleversplit$[](in$,m$)
	c=0
	l:TList=New TList
	While c<Len(in)
		Select in[c]
		Case m[0]
			If in[c..c+Len(m)]=m
				l.addlast in[..c]
				in=in[c+Len(m)..]
				c=-1
			EndIf
		Case 92	'backslash
			c:+1
		End Select
		c:+1
	Wend
	l.addlast in
	Local bits$[l.count()]
	c=0
	For bit$=EachIn l
		bits[c]=bit
		c:+1
	Next
	Return bits
End Function
endrem