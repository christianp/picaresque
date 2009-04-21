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
	Method Load(fname$,mode=0)
		f:TStream=ReadFile(fname)
		Print fname
		
		l$=f.ReadLine()
		Local words$[]
		properties:tmap=New tmap
		While l<>""
			words=l.split(" ")
			properties.insert words[0]," ".join(words[1..])
			l=f.ReadLine()
		Wend
		If mode=1 'entire file is one datum
			t$=""
			'While Not Eof(f)
			'CloseFile f
			't$=LoadText(fname)
			Print StreamSize(f)
			t=f.ReadString(f.size()-f.pos())
			'Wend
			addlast datum.Create( t,properties )
		Else 'each line is a separate datum
			While Not Eof(f)
				l=f.ReadLine()
				If l
					addlast datum.Create( l,properties)
				EndIf
			Wend
		EndIf
		
		CloseFile f
	End Method
	
	Function dirload:db(dname$,mode=0)
		d:db=New db
		For fname$=EachIn crawldir(dname)
			d.Load fname,mode
		Next
		Return d
	End Function
	
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
	
	Method pick$(kind$="")
		d:datum=pickdatum(kind)
		If d Return d.value Else Return ""
	End Method
	
	Method pickdatum:datum(kind$="")
		If kind Return filter("type="+kind).pickdatum()
		If Not count() Return Null
		Return datum(picklist(Self))
	End Method		
	
	Method values$[]()
		Local s$[count()]
		i=0
		For d:datum=EachIn Self
			s[i]=d.value
			i:+1
		Next
		Return s
	End Method
End Type

