Type template
	Field bits$[]
	Field vars$[]
	
	Function Create:template(temp$)
		t:template=New template
		Local splits$[]=temp.split("$")
		t.bits=New String[Len(splits)/2+1]
		t.vars=New String[Len(splits)/2]
		Local dest$[]=t.bits,odest$[]=t.vars,bdest$[]
		For i=0 To Len(splits)-1
			dest[i/2]=splits[i]
			bdest=dest
			dest=odest
			odest=bdest
		Next
		Return t
	End Function
	
	Rem
	Function fromfile:template(fname$)
		f:TStream=ReadFile(fname)
		s$=""
		While Not Eof(f)
			s:+f.ReadString(1000)
		Wend
		CloseFile f
		Return template.Create(s)
	End Function
	EndRem
	
	Method fill$()
		i=0
		s$=""
		For bit$=EachIn bits
			s:+bit
			If i<Len(vars)
				s:+game.getinfo(vars[i])
				i:+1
			EndIf
		Next
		Return s
	End Method
End Type
