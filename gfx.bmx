Global gfxwidth,gfxheight

Function initgfx(w=0,h=0)
	If w
		gfxwidth=w
		gfxheight=h
	EndIf
	Graphics gfxwidth,gfxheight,0
End Function

Function fittext2:TList(in$,width)
	lines:TList=New TList
	For line$=EachIn in.split("~n")
		s$=""
		c=0
		Local words$[]=line.split(" ")
		While c<Len(words)
			If TextWidth(s+" "+words[c])>=width
				lines.addlast s
				s=""
				words=words[c..]
				c=0
			Else
				s:+" "+words[c]
				c:+1
			EndIf
		Wend
		If s
			lines.addlast s
		EndIf
	Next
	Return lines
End Function
