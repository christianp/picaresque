Include "jsondecoder.bmx"
Include "grammar.bmx"
Include "template.bmx"
Include "helpers.bmx"
Include "things.bmx"
Include "db.bmx"


Global world:db,templates:db
Global game:tgame
Type tgame
	Field progress
	Field failures
	Field hero:character,darling:character,nemesis:character
	Field home:location,curlo:location,prvlo:location
	
	Field curmode:gamemode
	
	
	'INIT GAME STUFF
	
	Method New()
		SeedRnd MilliSecs()
		grammar.loadall
		world=db.dirload("world")
		templates=db.dirload("templates",1)
	End Method
	
	Method init()
		makeheroes
		curmode=narration.Create("intro")

		makenextlo
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
		
	Method gettemplateinfo$(p$)
		Local bits$[]=p.split(".")
		Local t:thing
		Select bits[0]
		Case "hero"
			t=hero
		Case "darling"
			t=darling
		Case "nemesis"
			t=nemesis
		Case "home"
			t=home
		Case "curlo"
			t=curlo
		Case "prvlo"
			t=prvlo
		Default
			Return p
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
		
		If curmode.status=1 'this mode is finished
			Select TTypeId.ForObject(curmode).name()
			Case "narration"
				debugo narration(curmode).kind+" finished"
				Select narration(curmode).kind
				Case "intro"  'finished intro, now move to first location
					journey
				Case "journey"
					End
				End Select
			End Select
		EndIf
	End Method
	
	Method draw()
		curmode.draw
	End Method
	
	
	'GAME MECHANICS STUFF
	
	Method journey()
		curmode=narration.Create("journey")
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
	
	Function Create:narration(kind$)
		n:narration=New narration
		n.kind=kind

		temp$=templates.pick(kind)
		n.text=template.Create(temp).fill()
		Return n
	End Function
	
	Method update()
		Print text
		status=1
	End Method
	
	Method draw()
	End Method
End Type



'COMMENCE THE GAMES!
game=New tgame
game.init
Repeat
	game.update
	game.draw
Forever