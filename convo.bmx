Type convo Extends gamemode
	Field success#
	Field g:grammar
	Field gi:ginput
	Field box:textbox
	Field agreeability#
	
	Method New()
		changegrammar "hero question"
		agreeability=Rnd(0,1)
		debugo "agreeability: "+agreeability
		box=textbox.Create(0,0,gfxwidth,gfxheight/2)
	End Method
	
	Method update()
		gi.update
		If gi.out
			say gi.out
		EndIf
		
		box.update
		
		'debug
		If gi.txt="quit" status=1
	End Method
	
	Method changegrammar(name$)
		g=grammar.find(name)
		gi=ginput.Create(g,0,gfxheight/2,gfxwidth,gfxheight/2)
	End Method
		
	Method say(s:sentence)
		Rem	
		If Not s
			debugo "not valid sentence"
			For op$=EachIn g.options(in)
				Print op
			Next
			respond "what"
			Return
		EndIf
		EndRem
		Print s.repr()
		
		box.addtext s.value(),.5
		
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
		box.addtext "^ align right ^"+response,.5
		
		Select kind
		Case "anecdote"
			changegrammar "hero response"
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
		box.draw
		gi.draw
	End Method
End Type

