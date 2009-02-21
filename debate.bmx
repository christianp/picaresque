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

Function debateme()
	
	done=0
	End
End Function