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
		'g.init
		'For word$=EachIn in.split(" ")
		'	g.in=word
		'	g.parse()
		'	
		'	g.addword word
		'Next
		's:sentence=g.out()
		'Print s.repr()
		s:sentence=g.match(in)
		If Not s
			debugo "not valid sentence"
			For op$=EachIn g.options(in)
				Print op
			Next
			respond "what"
			Return
		EndIf
		Select s.category 'what kind of thing did the player say?
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
		Case "debate"
			react 5
		Case "fight"
			react -5
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
		response$=rg.fill()
		Print response
		
		Select kind
		Case "anecdote"
			g=grammar.find("hero response")
		Case "fight"
			status=2
		Case "debate"
			status=1
		Default
			respond "anecdote"
		End Select
	End Method
	
	Method succeed(score#)
		debugo "score: "+score
		success:+score
		debugo "success: "+success
		If success>=5	'do debate now
			respond "debate"
		ElseIf success<=-5 'do fight now
			respond "fight"
		EndIf
	End Method	
	
	Method draw()
	End Method
End Type

