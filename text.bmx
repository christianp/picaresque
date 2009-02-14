Type ginput
	Field g:grammar
	Field options:TList
	Field txt$
	Field out:sentence
	Field font:wfont
	
	Method New()
		options=New TList
		font=wfont(dfonts.valueforkey("handwriting"))
	End Method
	
	Function Create:ginput(g:grammar)
		gi:ginput=New ginput
		gi.g=g
		Return gi
	End Function
	
	Method update()
		options:TList=g.options(txt)
		
		If Not options.count()
			'out=g.match(txt)
		EndIf
		
		c=GetChar()
		Select c
		Case 8	'backspace
			If Len(txt)
				txt$=txt[..Len(txt)-1]
			EndIf
		Case 9	'tab
			While options.count()=1
				txt:+String(options.first())
				options=g.options(txt)
			Wend
		Case 13	'return
			Print "return!"
			out=g.match(txt)
		Case 0
		Default
			txt:+Chr(c)
		End Select
	End Method
	
	Method draw()
		size#=30
		
		x=font.width(txt,size)
		y=font.height(size)

		font.draw txt,0,y,size

		For option$=EachIn options
			y:+font.height(size)*1.2
			font.draw option,x,y,size
		Next
		SetScale 1,1
	End Method
End Type


Type textbox
	Field x#,y#,w#,h#
	Field lines:TList
	Field length#,scroll#
	Field scrolling,lastscroll

	Method New()
		lines=New TList
	End Method
	
	Function Create:textbox(x#,y#,w#,h#)
		b:textbox=New textbox
		b.x=x
		b.y=y
		b.w=w
		b.h=h
		Return b
	End Function

	Method addtext$(txt$,scale#=1,width#=1)
		Print "ADDTEXT| "+txt
		tb:textblock=textblock.Create(txt,width*w,scale)
		tb.render length
		For tl:typeline=EachIn tb.typelines
			If tl.elements.count()
				lines.addlast tl
			EndIf
		Next
		length=tb.y+10
	End Method
	
	Method update()
		ms=MilliSecs()
		If scroll>0	
			If KeyDown(KEY_UP) 
				scroll:- 8
				If scroll<0 Then scroll=0
				scrolling = 0
				lastscroll=ms
			EndIf
		EndIf
		If length-scroll>h
			If scrolling
				scroll:+ 2
			EndIf
			If KeyDown(KEY_DOWN) 
				scroll:+ 8
				scrolling = 0
				lastscroll=ms
			EndIf
		Else
			scrolling=1
		EndIf
		If ms > lastscroll + 3000
			scrolling = 1
		EndIf

	End Method

	Method draw()
		DrawText length+" , "+scroll,x,y
		For tl:typeline=EachIn lines
			If tl.y+tl.height-scroll>0 Or tl.y-scroll<h
				tl.draw x,y-scroll
			EndIf
		Next
	End Method
End Type
