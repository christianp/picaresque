Type datum
	Field value$
	Field properties:tmap

	Method New()
	End Method
	
	Function Create:datum(value$,properties:tmap)
		d:datum=New datum
		d.value=value
		d.properties=properties
		Return d
	End Function
	
	Method property$(name$)
		If Not properties.contains(name) Return ""
		Return String(properties.valueforkey(name))
	End Method
	
	Method match(want:tmap)
		For key$=EachIn want.keys()
			key=Lower(key)
			If Lower(property(key))<>Lower(String(want.valueforkey(key))) Return 0
		Next
		Return 1
	End Method
End Type

Type db Extends TList
	Method Load(fname$)
		f:TStream=ReadFile(fname)
		l$=f.ReadLine()
		Local words$[]
		properties:tmap=New tmap
		While l<>""
			words=l.split(" ")
			properties.insert words[0],words[1]
			l=f.ReadLine()
		Wend
		While Not Eof(f)
			l=f.ReadLine()
			If l
				addlast datum.Create( l,properties)
			EndIf
		Wend
		CloseFile f
	End Method
	
	Method DirLoad(dname$)
		For fname$=EachIn LoadDir(dname)
			If Not (fname="." Or fname="..")
				path$=dname+"/"+fname
				Select FileType(path)
				Case 1 'file
					Load path
					Print path
				Case 2
					DirLoad path
				End Select
			EndIf
		Next
	End Method
	
	Method filter:db(expr$)
		Local conditions$[]=expr.split("&")
		properties:tmap=New tmap
		For condition$=EachIn conditions
			If Trim(condition)
				Local bits$[]=condition.split("=")
				properties.insert Trim(bits[0]),Trim(bits[1])
			EndIf
		Next
		db2:db=New db
		For d:datum=EachIn Self
			If d.match(properties)
				db2.addlast d
			EndIf
		Next
		Return db2
	End Method
	
	Method pick$()
		Return datum(picklist(Self)).value
	End Method
End Type

