Type clickabletext
	Field x#,y#,w#,h#
	Field txt$
	
	Function Create:clickabletext(txt$,x#,y#,w#,h#)
		c:clickabletext=New clickabletext
		c.x=x
		c.y=y
		c.w=w
		c.h=h
		c.txt=txt
		Return c
	End Function
	
	Method contains(dx#,dy#)
		If dx>=x And dx<=x+w And dy>=y And dy<=y+h
			Return 1
		EndIf
	End Method
End Type

Type ginput
	Field g:grammar
	Field options:TList
	Field txt$
	Field out:sentence
	Field font:wfont
	Field x#,y#,w#,h#
	Field clickables:TList
	
	Method New()
		options=New TList
		clickables=New TList
		font=wfont(dfonts.valueforkey("handwriting"))
	End Method
	
	Function Create:ginput(g:grammar,x#,y#,w#,h#)
		gi:ginput=New ginput
		gi.g=g
		gi.x=x
		gi.y=y
		gi.w=w
		gi.h=h
		Return gi
	End Function
	
	Method reset()
		txt=""
		out=Null
	End Method
	
	Method update()
		options:TList=g.options(txt)

		makeclickables
		
		checkclickables

				
		c=GetChar()
		Select c
		Case 8	'backspace
			If Len(txt)
				txt$=txt[..Len(txt)-1]
			EndIf
		Case 9	'tab
			autocomplete
		Case 13	'return
			'Print "return!"
			out=g.match(txt)
		Case 0
		Default
			txt:+Chr(c)
		End Select
	End Method
	
	Method makeclickables()
		clickables=New TList
		
		size#=30
		
		dx=x+font.width(txt,size)
		dy=y+font.height(size)

		bigwidth=0
		oy#=dy
		For option$=EachIn options
			th#=font.height(size)
			tw#=font.width(option,size)
			dy:+th*1.2
			If dy>y+h
				dy=oy+th*1.2
				dx:+bigwidth+5
				bigwidth=0
			EndIf
			
			addclickable option,dx,dy-th,tw,th
			
			If tw>bigwidth
				bigwidth=tw
			EndIf
		Next
	End Method
		
	Method addclickable(txt$,x#,y#,w#,h#)
		c:clickabletext=clickabletext.Create(txt,x,y,w,h)
		clickables.addlast c
	End Method
	
	Method checkclickables()
		If Not MouseHit(1) Return
		mx=MouseX()
		my=MouseY()
		
		For c:clickabletext=EachIn clickables
			If c.contains(mx,my)
				txt:+c.txt
				autocomplete
			EndIf
		Next
	End Method
	
	Method autocomplete()
		options=g.options(txt)
		While options.count()=1
			txt:+String(options.first())
			options=g.options(txt)
		Wend
		'Print options.count()
		If options.count()=0
			out=g.match(txt)
		EndIf
	End Method		

	Method draw()
		oldmode=GetBlend()
		SetBlend ALPHABLEND
		Local r,g,b
		GetClsColor r,g,b
		SetColor r,g,b
		DrawRect x,y,w,h
		SetColor 0,0,0
		
		size#=30
		
		dx=x+font.width(txt,size)
		dy=y+font.height(size)

		font.draw txt,x,dy,size
		
		For c:clickabletext=EachIn clickables
			SetScale 1,1
			SetAlpha .2
			SetColor 0,0,255
			DrawRect c.x,c.y,c.w,c.h
			SetColor 0,0,0
			SetAlpha 1
			font.draw c.txt,c.x,c.y+c.h,size
		Next

		Rem
		bigwidth=0
		oy#=dy
		For option$=EachIn options
			If dy>y+h
				dy=oy
				dx:+bigwidth+5
				bigwidth=0
			EndIf
			dy:+font.height(size)*1.2
			tw#=font.width(option,size)
			If tw>bigwidth
				bigwidth=tw
			EndIf
			font.draw option,dx,dy,size
		Next
		EndRem
		SetScale 1,1
		DrawText options.count(),0,0
		SetBlend oldmode
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
				scroll:- 1
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
				scroll:+ 1
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
		For tl:typeline=EachIn lines
			If tl.y+tl.height-scroll>=0 And tl.y-scroll<=h
				tl.draw x,y-scroll
			EndIf
		Next
	End Method
End Type
