Global gfxwidth,gfxheight

Function initgfx(w=0,h=0)
	If w
		gfxwidth=w
		gfxheight=h
	EndIf
	Graphics gfxwidth,gfxheight,0
	AutoMidHandle true
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

Function DrawZoomCircle(x#,y#,r#)
	r:*zoom
	DrawOval zoomx(x-r),zoomy(y-r),r*2,r*2
End Function

Function DrawZoomImage(img:timage,x#,y#)
	Local sx#,sy#
	GetScale sx,sy
	SetScale sx*zoom,sy*zoom
	DrawImage img,zoomx(x),zoomy(y)
End Function

Function DrawZoomLine(x1#,y1#,x2#,y2#)
	DrawLine zoomx(x1),zoomy(y1),zoomx(x2),zoomy(y2)
End Function

Function ZoomX#(x#)
	Return (x - panx) * zoom + gwidth / 2
End Function
Function ZoomY#(y#)
	Return (y - pany) * zoom + gheight / 2
End Function

Function UnzoomX#(x#)
	Return (x - gwidth / 2) / zoom + panx
End Function
Function UnzoomY#(y#)
	Return (y - gheight / 2) / zoom + pany
End Function