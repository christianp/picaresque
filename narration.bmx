Type narration Extends gamemode
	Field text$
	Field kind$
	Field tb:textblock
	
	Function Create:narration(kind$)
		n:narration=New narration
		n.kind=kind

		d:datum=templates.pickdatum(kind)
		game.curdatum=d
		temp$=d.value
		skind$=d.property("style")
		If skind
			kind=skind
		endif
		style$=game.getstyle(kind)
		n.text=filltemplate(style+temp)'template.Create(style+temp).fill()
		n.tb=textblock.Create(n.text,gfxwidth-60,.5)
		Return n
	End Function
	
	Method update()
		If GetChar() Or MouseHit(1) Or MouseHit(2)
			status=1
		EndIf
	End Method
	
	Method draw()
		tb.draw 30,(gfxheight-tb.y)/2
	End Method
End Type
