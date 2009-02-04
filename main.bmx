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
	Field opponent:character
	
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
		
	Method getinfo$(p$)
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
				End Select
			Case "convo"
				End
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
	
	Method encounter()
		opponent=character.Create("male","country="+curlo.country)
		curmode=narration.Create("encounter")
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

Type convo Extends gamemode
	Field success#
	Field g:grammar
	Field agreeability#
	
	Method New()
		g=grammar.find("hero question")
		agreeability=Rnd(0,1)
		debugo "agreeability: "+agreeability
	End Method
	
	Method update()
		in$=Input(">")
		say in
		If in="quit" status=1
	End Method
	
	Method say(in$)	
		debugo g.name
		g.init
		For word$=EachIn in.split(" ")
			g.in=word
			g.parse()
			
			g.addword word
		Next
		s:sentence=g.out()
		'Print s.repr()
		Select s.getparam("$") 'what kind of thing did the player say?
		Case "darling" 'question about darling
			respond "darling"
		Case "opinion" 'player gave opinion
			score#=rateadverb(s.getparam("adverb"))*rateadjective(s.getparam("opinion"))
			react score
		Case "description"
			score#=rateadverb(s.getparam("adverb"))*rateadjective(s.getparam("adjective"))
			react score
		Case "comparison"
			If s.getparam("adjective")=s.getparam("comparison")
				score#=2*rateadjective(s.getparam("adjective"))
			Else
				'score=-2*rateadjective(s.getparam("adjective"))
				score#=0
			EndIf
			react score
		End Select
	End Method
	
	Method rateadverb#(adverb$)
		Select adverb
		Case "big"
			Return 1
		Case "small"
			Return .3
		Default
			Return .3
		End Select
		Return score
	End Method
	
	Method rateadjective#(adjective$)
		Select adjective
		Case "good","sharp","clever","beauty","unique"
			Return 1
		Case "bad","stupid","ugly","common"
			Return -1
		End Select
	End Method
	
	Method react(score#)
		debugo "react to "+score
		If score>0	'compliment
			p#=agreeability
		Else	'insult
			p=1-agreeability
		EndIf
		If Rnd(0,1)<=p	'success - got a reaction
			If score>0
				respond "compliment"
			Else
				respond "insult"
			EndIf
			succeed score
		Else
			respond "laugh"
		EndIf
	End Method
	
	Method respond(kind$)
		rg:grammar=grammar.find("opponent "+kind)
		'DebugStop
		s:sentence=rg.fill()
		Print s.txt
		
		If kind="anecdote"
			g=grammar.find("hero response")
		Else
			respond "anecdote"
		EndIf
	End Method
	
	Method succeed(score#)
		debugo "score: "+score
		success:+score
		debugo "success: "+success
		If success>5	'do debate now
			status=1
		ElseIf success<-5 'do fight now
			status=2
		EndIf
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