Rem
Type argument
	Field statement:lterm
	Field philosophy:lterm
	
	Method New()
	End Method
	
	Method interpret:lterm(s:sentence)
		If Not s Return Null
		Select s.category
		Case "assume"
			thingname$=s.nextparam("thing")
			t:lterm=makeconstant(thingname,s)
			addstatement t
		Case "oneor"
			thingname$=s.nextparam("thing")
			t1:lterm=makeconstant(thingname,s)
			t2:lterm=makeconstant(thingname,s)
			o:lor=lor.Create(t1,t2)
			addstatement o
		Case "twoor"
			thingname1$=s.nextparam("thing")
			t1:lterm=makeconstant(thingname1,s)
			thingname2$=s.nextparam("thing")
			t2:lterm=makeconstant(thingname2,s)
			o:lor=lor.Create(t1,t2)
			addstatement o
		Case "implies"
			thingname1$=s.nextparam("thing")
			t1:lterm=makeconstant(thingname1,s)
			thingname2$=s.nextparam("thing")
			t2:lterm=makeconstant(thingname2,s)
			i:limplies=limplies.Create(t1,t2)
			addstatement i
		Case "conclusion"
			thingname$=s.nextparam("thing")
			t:lterm=makeconstant(thingname,s)
			n:lnot=lnot.Create(t)
			addstatement n
			'Print statement.repr()
			If philosophy
				test:lterm=land.Create(philosophy,statement)
			Else
				test:lterm=statement
			EndIf
			Return test
		End Select
	End Method
	
	Method makeconstant:lterm(thingname$,s:sentence)
		p$=s.nextparam("property")
		If p="not"
			Return lnot.Create(makeconstant(thingname,s))
		Else
			Return lconstant.Create(Lower(thingname)+"::"+Lower(p))
		EndIf
	End Method
	
	Method addstatement(t2:lterm)
		If statement
			statement=land.Create(statement,t2)
		Else
			statement=t2
		EndIf
	End Method
	
	Method addphilosophy(t2:lterm)
		If philosophy
			philosophy=land.Create(philosophy,t2)
		Else
			philosophy=t2
		EndIf
	End Method
End Type
	
Type debate Extends gamemode
	Field a:argument
	
	Field gi:ginput
	Field box:textbox
	
	Method New()
		g:grammar=grammar.find("debate")
		
		gi=ginput.Create(g,0,gfxheight/2,gfxwidth,gfxheight/2)
		box=textbox.Create(0,0,gfxwidth,gfxheight/2)
		
		a:argument=New argument
	
		tenets=0
		While tenets<5
			dogma$=g.fill()
			a.statement=Null
			a.interpret(g.match(dogma))
			If a.philosophy
				positive=truth(land.Create(a.philosophy,a.statement))
				contrapositive=truth(land.Create(a.philosophy,lnot.Create(a.statement)))
			Else
				positive=truth(a.statement)
				contrapositive=truth(lnot.Create(a.statement))
			EndIf
			If Not (positive Or contrapositive)
				box.addtext a.statement.repr()
				Print "eureka!"
				Print dogma
				tenets:+1
				a.addphilosophy a.statement
			Else
				Print "oh no"
			EndIf
		Wend
		Print "THE PHILOSOPHY"
		Print a.philosophy.repr()
	End Method
			
	Method update()
		gi.update
		If gi.out
			say gi.out
		EndIf
		
		box.update

	End Method
	
	Method say(s:sentence)
		Print s.repr()
		test:lterm=a.interpret(s)
		If test
			result=truth(test)
			box.addtext test.repr()
			If result
				box.addtext "That's true!"
				win
			Else
				box.addtext "That's false."
				lose
			EndIf
		Else
			gi.reset
		EndIf
	End Method
	
	Method win()
		status=1
	End Method
	Method lose()
		status=2
	End Method
	
	Method draw()
		box.draw
		gi.draw
	End Method
End Type
EndRem

Type blankline
	Field texts$[]
	Field blanks:blank[2]
	Field font:wfont
	
	Function Create:blankline(p:premise,font:wfont)
		bl:blankline=New blankline
		line$=p.blankform()
		bl.texts=line.split(":")
		bl.blanks[0]=blank.Create(p.t1,font)
		bl.blanks[1]=blank.Create(p.t2,font)
		bl.font=font
		Return bl
	End Function
	
	Method complete()
		For b:blank=EachIn blanks
			If Not b.complete()
				Return False
			EndIf
		Next
		Return True
	End Method
	
	Method draw(x#,y#)
		x:-width()/2
		n=0
		For t$=EachIn texts
			SetColor 0,0,0
			font.draw t,x,y,30
			x:+font.width(t,30)
			Select n
			Case 0
				blanks[0].draw x,y
				x:+blanks[0].width()
			Case 1
				'If blanks[0].hold
					If blanks[0].t.many
						part=2
					Else
						part=1
					EndIf
				'Else
				'	part=0
				'EndIf
				blanks[1].draw x,y,part
				x:+blanks[1].width()
			End Select
			n:+1
		Next
		
		'For b:blank=EachIn l
		'	b.draw x,y
		'	x:+b.width()
		'Next
	End Method
	
	Method width#()
		w#=0
		For t$=EachIn texts
			w:+font.width(t,30)
		Next
		For b:blank=EachIn blanks
			w:+b.width()
		Next
		Return w
	End Method
End Type

Type blank
	Field t:tterm,value$
	Field hold:magpoetry
	Field font:wfont
	Field x#,y#
	
	Function Create:blank(t:tterm,font:wfont)
		b:blank=New blank
		b.t=t
		b.font=font
		Return b
	End Function
	
	Method complete()
		If hold And hold.t.name=t.name Return True Else Return False
	End Method
	
	Method draw(dx#,dy#,part=0)
		x=dx
		y=dy
		If complete()
			SetColor 0,100,0
		Else
			SetColor 0,0,0
		EndIf
		DrawRect x,y-font.height(30),width(),font.height(30)
		If hold
			Select part
			Case 0
				value$=hold.t.name
			Case 1
				value$=hold.t.rsingle
			Case 2
				value$=hold.t.rplural
			End Select
			SetColor 255,255,255
			font.draw value,x,y,30
		EndIf
	End Method
	
	Method width()
		If hold
			Return font.width(value,30)
		Else
			Return font.width("xxxxxxx",30)
		EndIf
	End Method
	
End Type

Type magpoetry
	Field t:tterm
	Field x#,y#
	Field font:wfont
	Field b:blank
	
	Function Create:magpoetry(t:tterm,font:wfont)
		m:magpoetry=New magpoetry
		m.t=t
		m.x=Rnd(.2,.8)*gfxwidth
		m.y=Rnd(.7,.9)*gfxheight
		m.font=font
		Return m
	End Function
	
	Method draw()
		If b
			x=b.x
			y=b.y
			Return
		EndIf
		SetColor 0,0,0
		DrawRect x,y-font.height(30),width(),font.height(30)
		SetColor 255,255,255
		font.draw t.repr(),x,y,30
	End Method
	
	Method width()
		Return font.width(t.repr(),30)
	End Method
	
End Type


Type debate Extends gamemode
	Field blanklines:TList
	Field words:TList,blanks:TList
	Field mstate
	Field hold:magpoetry,offx#,offy#
	Field font:wfont
	
	
	Method New()
		font=wfont(dfonts.valueforkey("print"))
		makesyllogism
	End Method
	
	
	Method makesyllogism()
		
		Local ps:premise[3]
		
		premises=New TList
		ps[0]=premise.generate()
		premise.addpremise(ps[0])
		While Not ps[2]
			tick:+1
			If tick>50
				tick=0
				premises=New TList
				ps[0]=premise.generate()
			EndIf
			ps[1]=premise.generate()
			ps[2]=premise.combine(ps[0],ps[1])
		Wend
		
		blanklines=New TList
		words=New TList
		For p:premise=EachIn ps
			Print p.repr()
			blanklines.addlast blankline.Create(p,font)
			words.addlast magpoetry.Create(p.t1,font)
			words.addlast magpoetry.Create(p.t2,font)
		Next
		bl:blankline=blankline(blanklines.last())
		bl.texts[0]="Therefore, "+bl.texts[0]
		blanks=New TList
		For bl:blankline=EachIn blanklines
			For b:blank=EachIn bl.blanks
				blanks.addlast b
			Next
		Next
		l1:TList=words.copy()
		l2:TList=blanks.copy()
		For c=1 To 3
			b:blank=blank(picklist(l2))
			l2.remove b
			For m:magpoetry=EachIn l1
				If m.t=b.t
					l1.remove m
					b.hold=m
					m.b=b
					m.x=b.x
					m.y=b.y
					Exit
				EndIf
			Next
		Next
	End Method
	
	Method update()
		mx=MouseX()
		my=MouseY()
		Select mstate
		Case 0
			If MouseDown(1)
				If pickword(mx,my)
					mstate=1
				Else
					mstate=2
				EndIf
			EndIf
		Case 1
			If hold.b
				dx#=mx-hold.b.x
				dy#=my-hold.b.y
				d#=Sqr(dx*dx+dy*dy)
				If mx<hold.b.x Or mx>hold.b.x+hold.b.width() Or my<hold.b.y-font.height(30) Or my>hold.b.y
					hold.b.hold=Null
					hold.b=Null
				EndIf
			Else
				hold.x=mx+offx
				hold.y=my+offy
			EndIf
			If Not MouseDown(1)
				dropword
				mstate=0
				If complete()
					status=1
				EndIf
			EndIf
		Case 2
			If Not MouseDown(1)
				mstate=0
			EndIf
		End Select
	End Method
	
	Method complete()
		For b:blank=EachIn blanks
			If Not b.complete() Return False
		Next
		Return True
	End Method
	
	Method pickword(x,y)
		hold=Null
		h#=font.height(30)
		For m:magpoetry=EachIn words
			'SetColor 0,0,0
			'DrawLine x,y,m.x,m.y
			If x>=m.x And x<=m.x+font.width(m.t.name,30) And y>=m.y-h And y<=m.y
				hold=m
				offx=m.x-x
				offy=m.y-y
			EndIf
		Next
		'If hold DrawRect 0,0,50,50
		Return hold<>Null
	End Method
	
	Method dropword()
		For b:blank=EachIn blanks
			If Not b.hold
				If (hold.x<b.x+b.width() And hold.x+font.width(hold.t.name,30)>b.x) And (hold.y<b.y+font.height(30) And hold.y+font.height(30)>b.y)
					b.hold=hold
					hold.x=b.x
					hold.y=b.y
					hold.b=b
					Return True
				EndIf
			EndIf
		Next
		Return False
				
	End Method
	
	Method draw()
		interval#=font.height(30)*1.5
		y#=gfxheight/2-interval*2
		For bl:blankline=EachIn blanklines
			bl.draw gfxwidth/2,y
			y:+interval
		Next
		
		For m:magpoetry=EachIn words
			m.draw
		Next
	End Method
End Type