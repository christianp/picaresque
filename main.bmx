Include "jsondecoder.bmx"
Include "grammar.bmx"
Include "template.bmx"
Include "helpers.bmx"
Include "things.bmx"
Include "db.bmx"
Include "debate.bmx"
Include "logic.bmx"
Include "convo.bmx"
Include "gfx.bmx"
Include "typeset.bmx"
Include "text.bmx"

Global world:db,templates:db
Global game:tgame
Type tgame
	Field wins,attempts,progress
	Field hero:character,darling:character,nemesis:character
	Field home:location,curlo:location,prvlo:location
	Field opponent:character
	
	Field curmode:gamemode
	
	
	'INIT GAME STUFF
	
	Method New()
		SeedRnd MilliSecs()

		'graphics
		AppTitle="Picaresque!"
		initgfx 960,600
		loadfonts
		
		'world
		grammar.loadall
		world=db.dirload("world")
		templates=db.dirload("templates",1)
	End Method
	
	Method init()
		makeheroes
		narrate "intro"
	End Method
		
	Method makeheroes()
		country$=world.pick("country")
		home=location.Create(country)
		curlo=home
		hero=character.Create("male","country="+country)
		darling=character.Create("female","country="+country)
		nemesis=character.Create("male","country="+country)
	End Method
	
	Method makenextlo()
		prvlo=curlo
		country$=world.pick("country")
		curlo=location.Create(country)
	End Method
		
	Method getinfo$(p$)
		'debugo "GETINFO "+p
		Local bits$[]=p.split(".")
		Local t:thing
		Select bits[0]
		Case "hero"
			t=hero
		Case "darling"
			t=darling
		Case "nemesis"
			t=nemesis
		Case "opponent"
			t=opponent
		Case "home"
			t=home
		Case "curlo"
			t=curlo
		Case "prvlo"
			t=prvlo
		Case "chapter"
			Print "CHAPTER"
			Return romannumeral(progress)
		Default
			Return ""
		End Select
		If t
			If Len(bits)>1
				Return t.getinfo(bits[1])
			Else
				Return t.getinfo("name")
			EndIf
		EndIf
	End Method
	
	'MAIN LOOP STUFF
	
	Method update()
		curmode.update
		
		If curmode.status 'this mode is finished
			Select TTypeId.ForObject(curmode).name()
			Case "narration"
				debugo narration(curmode).kind+" finished"
				Select narration(curmode).kind
				Case "intro"  'finished intro, now move to first location
					journey
				Case "journey"
					encounter
				Case "encounter"
					curmode=New convo
				Case "setback"
					encounter
				Case "finish"
					End
				End Select
			Case "convo"
				Select curmode.status
				Case 1	'debate
					debatehim
				Case 2	'fight
					fighthim
				End Select
			Case "fight"
				Select curmode.status
				Case 1	'won
					win
				Case 2
					lose
				End Select
			Case "debate"
				Select curmode.status
				Case 1	'won
					win
				Case 2
					lose
				End Select
			End Select
		EndIf
	End Method
	
	Method draw()
		curmode.draw
		
		Flip
		Cls
	End Method
	
	
	'GAME MECHANICS STUFF
	
	Method narrate(kind$)
		curmode=narration.Create(kind)
	End Method
	
	Method journey()
		progress:+1
		If progress=3	'finished the game!
			finish
		Else
			makenextlo
			narrate "journey"
		EndIf
	End Method
	
	Method encounter()
		attempts:+1
		opponent=character.Create("male","country="+curlo.country)
		narrate "encounter"
	End Method
	
	Method debatehim()
		curmode=New debate
	End Method
	
	Method fighthim()
		curmode=New fight
	End Method
	
	Method win()
		debugo "win!"
		wins:+1
		journey
	End Method
	
	Method lose()
		debugo "lose!"
		narrate "setback"
	End Method
	
	Method finish()
		narrate "finish"
	End Method
End Type

Type gamemode
	Field status
	
	Method update() Abstract
	Method draw() Abstract
End Type

Type narration Extends gamemode
	Field text$
	Field kind$
	Field tb:textblock
	
	Function Create:narration(kind$)
		n:narration=New narration
		n.kind=kind

		temp$=templates.pick(kind)
		n.text=template.Create(temp).fill()
		n.tb=textblock.Create(n.text,gfxwidth-60,.5)
		Return n
	End Function
	
	Method update()
		If GetChar() Or MouseHit(1) Or MouseHit(2)
			status=1
		EndIf
		SetClsColor 248,236,194
	End Method
	
	Method draw()
		y=0
'		For line$=EachIn fittext(text,gfxwidth-100)
'			DrawText line,50,y
'			y:+TextHeight(line)
'		Next
		tb.draw 30,(gfxheight-tb.y)/2
	End Method
End Type

Type fight Extends gamemode

	Method update()
		in$=Input("Win fight? y/n~n")
		If in="y"
			win
		Else
			lose
		EndIf
	End Method
	
	Method win()
		status=1
	End Method
	Method lose()
		status=2
	End Method
	
	Method draw()
	End Method
End Type


'COMMENCE THE GAMES!
game=New tgame
game.init

'While 1
'debateme
'Wend

Repeat
	game.update
	game.draw
	If AppTerminate() Or KeyHit(KEY_ESCAPE) End
Forever