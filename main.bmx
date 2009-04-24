Include "grammar.bmx"
Include "template.bmx"
Include "helpers.bmx"
Include "things.bmx"
Include "db.bmx"
Include "gfx.bmx"
Include "typeset.bmx"
Include "text.bmx"
Include "font.bmx"
Include "texpoly.bmx"

Include "mise en scene.bmx"

Include "convo.bmx"
Include "debate.bmx"
	Include "syllogisms.bmx"
	Include "logic.bmx"
Include "duel.bmx"
	Include "thoughts.bmx"
Include "narration.bmx"

Global world:db,templates:db,plotdb:db
Global game:tgame



game=New tgame
game.init

Repeat
	game.update
	game.draw
	If AppTerminate() Or KeyHit(KEY_ESCAPE) End
Forever

Type tgame
	Field subplots:TList
	Field plotstack:TList
	Field variables:tmap
	Field curmode:gamemode
	Field curdatum:datum

	Method New()
		SeedRnd MilliSecs()

		'graphics
		AppTitle="Picaresque!"
		initgfx 960,600
		loadfonts
		SetClsColor 248,236,194
		
		'world
		grammar.loadall
		directiongrammar=grammar.find("direction")
		world=db.dirload("world")
		templates=db.dirload("templates",1)
		initsyllogism
		
	End Method

	Method init()
		subplots=New TList
		plotstack=New TList
		variables=New tmap
		things=New tmap
		tplot.loadall
		addplot "beginning"
	End Method
	
	
	'get/set info
	Method getstyle$(kind$)
		Return templates.filter("type=style & kind="+kind).pick()
	End Method
	
	Method findthing:thing(name$)
		t:thing=thing.find(name)
		If t Return(t)
		
		If variables.contains(name)
			name=String(variables.valueforkey(name))
			t:thing=thing.find(name)
			If t
				Return t
			EndIf
		EndIf
	End Method

	Method getinfo$(key$)
		Print "GETINFO "+key
		Local bits$[]=key.split(".")
		Select bits[0]
		Case "chapter"
			Print "CHAPTER"
			Return romannumeral(progress)
		Case "template"	'fill in info from template
			Return curdatum.property(bits[1])
		Case "style"
			Return getstyle(bits[1])
		Case "world"
			Return world.getinfo(".".join(bits[1..]))
		Default
			t:thing=findthing(bits[0])
			If t
				If Len(bits)>1
					Return t.getinfo(".".join(bits[1..]))
				Else
					Return t.getinfo("name")
				EndIf
			ElseIf variables.contains(bits[0])
				Return String(variables.valueforkey(bits[0]))
			Else
				Return ""
			EndIf
		End Select
	End Method
	
	
	'plot stuff
	Method setinfo(key$,value$)
		Local bits$[]=key.split(".")
		Select bits[0]
		Case "chapter"
			progress=Int(value)
		Default
			If Len(bits)>1
				t:thing=thing.find(bits[0])
				key=".".join(bits[1..])
				t.setinfo key,value
			Else
				Print "add variable "+key+": "+value
				variables.insert key,value
			EndIf
		End Select
	End Method
	
	Method adddirection(d:direction)
		plotstack.addlast d
	End Method
	
	Method addplot(kind$="",conditions$="")
		p:tplot=tplot.pick(kind,conditions)
		Print "add plot "+p.name
		For d:direction=EachIn p.directions
			adddirection d
			Print TTypeId.ForObject(d).name()
		Next
	End Method
	
	Method pickplot()
		progress:+1
		'see if any subplots can be picked up
		For s:suspense=EachIn subplots
			If s.met()
				For d:direction=EachIn s.directions
					adddirection d
				Next
				Return
			EndIf
		Next
		
		'generate a new plot line
		addplot
	End Method
	
	Method runplot()
		While Not curmode
			While Not plotstack.count()
				pickplot
			Wend
			d:direction=direction(plotstack.removefirst())
			d.do
		Wend
	End Method
	
	Method yield(conditions:TList)
		s:suspense=suspense.Create(conditions,directions)
		subplots.addlast s
		plotstack=New TList
	End Method
	


	'game mode constructors
	Method narrate(kind$)
		curmode=narration.Create(kind)
	End Method


	'update/draw
	Method update()
		If curmode
			curmode.update
			If curmode.status
				curmode=Null
			EndIf
		Else
			runplot
		EndIf
	End Method
	
	Method draw()
		If curmode
			curmode.draw
			Flip
			Cls
		EndIf
	End Method
End Type

Type gamemode
	Field status
	
	Method New()
		FlushKeys
		FlushMouse
	End Method
	
	Method update() Abstract
	Method draw() Abstract
End Type


Rem
Type tgame
	Field wins,attempts,progress
	Field hero:character,darling:character,nemesis:character
	Field home:location,curlo:location,prvlo:location
	Field opponent:character
	
	Field curmode:gamemode
	Field curdatum:datum
	
	
	'INIT GAME STUFF
	
	Method New()
		SeedRnd MilliSecs()

		'graphics
		AppTitle="Picaresque!"
		initgfx 960,600
		loadfonts
		SetClsColor 248,236,194
		
		'world
		grammar.loadall
		world=db.dirload("world")
		templates=db.dirload("templates",1)
		initsyllogism
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
		Case "template"	'fill in info from template
			Return curdatum.property(bits[1])
		Case "style"
			Return getstyle(bits[1])
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
	
	Method getstyle$(kind$)
		Return templates.filter("type=style & kind="+kind).pick()
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
				Case "win fight","win debate"
					win
				Case "lose fight","lose debate"
					lose
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
					narrate "win fight"
				Case 2
					narrate "lose fight"
				End Select
			Case "debate"
				Select curmode.status
				Case 1	'won
					narrate "win debate"
				Case 2
					narrate "lose fight"
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
		If progress=5	'finished the game!
			finish
		Else
			makenextlo
			narrate "journey"
		EndIf
	End Method
	
	Method encounter()
		attempts:+1
		opponent=character.Create("gender=male&country="+curlo.country)
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






'COMMENCE THE GAMES!
game=New tgame
game.init


Repeat
	game.update
	game.draw
	If AppTerminate() Or KeyHit(KEY_ESCAPE) End
Forever
endrem