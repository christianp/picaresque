'Include "logic.bmx"


Global terms:TList=New TList
Type tterm
	Field name$,rsingle$,rplural$
	Field txts$[]
	Field many
	
	Method New()
		terms.addlast Self
	End Method
	
	Function Create:tterm(name$,rsingle$,rplural$,many,txts$[])
		t:tterm=New tterm
		t.name=name
		t.rsingle=rsingle
		t.rplural=rplural
		t.many=many
		t.txts=txts
		Return t
	End Function
	
	Rem
	Function Create:tterm(name$,+plural=1)
		t:tterm=New tterm
		t.name=name
		t.txts=txts
		t.plural=plural
		t.tags=tags
		For tag$=EachIn tags
			t.addtag tag
		Next
		Return t
	End Function
	EndRem

End Type


Global premises:TList=New TList
Type premise
	Field kind
	Field t1:tterm,t2:tterm
	
	Function Create:premise(kind,t1:tterm,t2:tterm)
		p:premise=New premise
		p.kind=kind
		p.t1=t1
		p.t2=t2
		Return p
	End Function
	
	
	Function addpremise:premise(p:premise)
	
		'can always add first premise
		If premises.count()=0
			premises.addlast p
			Return Null
		EndIf
	
		'check exact premise doesn't already exist, or negation
		For p2:premise=EachIn premises	
			If p2.t1=p.t1 And p2.t2=p.t2 And (p2.kind=p.kind Or p.kind+p2.kind=1 Or (p.kind=2 And p2.kind=0) Or (p.kind=3 And p2.kind=1))
				Return Null
			EndIf
		Next
		
		'see if any derivations can be made
		l:TList=New TList
		For p2:premise=EachIn premises
			p3:premise=premise.combine(p,p2)
			If p3
				l.addlast p3
				Print "   "+p.repr()
				Print "   "+p2.repr()
				Print "   "+p3.repr()
				Print "~n"
			EndIf
			p3=premise.combine(p2,p)
			If p3
				l.addlast p3
				Print "   "+p2.repr()
				Print "   "+p.repr()
				Print "   "+p3.repr()
				Print "~n"
			EndIf
		Next
		If l.count()	'have made some new derivations
			premises.addlast p
			Return premise(picklist(l))
		EndIf
	End Function
	
	Method blankform$()
		Return t2.txts[kind+4*t1.many]
	End Method
	
	Method firstthing$()
		Return t1.name
	End Method
	
	Method secondthing$()
		If t1.many
			Return t2.rplural
		Else
			Return t2.rsingle
		EndIf
	End Method
	
	Method repr$()
		Local bits$[]=blankform().split(":")
		txt$=bits[0]+firstthing()+bits[1]+secondthing()
		Return txt
	End Method
	
	Function generate:premise()
		kind=Rand(0,3)
		t1:tterm=tterm(picklist(terms))
		l:TList=terms.copy()
		l.remove t1
		t2:tterm=tterm(picklist(l))
		Return premise.Create(kind,t1,t2)
	End Function
	
	Method distributed(t:tterm)
		Select kind
		Case 0	'a
			If t=t1 Return True
		Case 1	'e
			Return True
		Case 2	'i
			Return False
		Case 3	'o
			If t=t2 Return True
		End Select
	End Method
	
	Function combine:premise(p1:premise,p2:premise)
		'Print p1.repr()
		'Print p2.repr()
	
		If p1.t1=p2.t1 Or p1.t1=p2.t2	'figure 1 or 3
			m:tterm=p1.t1
			p:tterm=p1.t2
		ElseIf p1.t2=p2.t1 Or p1.t2=p2.t2	'figure 2 or 4
			m:tterm=p1.t2
			p:tterm=p1.t1
		Else
			'Print "no middle term"
			Return Null
		EndIf
		If m=p2.t1
			s:tterm=p2.t2
			If m=p1.t1
				figure=3
			Else
				figure=4
			EndIf
		Else
			s:tterm=p2.t1
			If m=p1.t1
				figure=1
			Else
				figure=2
			EndIf
		EndIf
		If s=p
			'print "major and minor terms the same"
			Return Null
		EndIf
		If Not (p1.distributed(m) Or p2.distributed(m))
			'Print "excluded middle"
			Return Null
		EndIf
		If (p1.kind=1 Or p1.kind=3) And (p2.kind=1 Or p2.kind=3)
			'Print "exclusive premises"
			Return Null
		EndIf
		
		code=4*p1.kind+p2.kind
		kind=-1
		Select figure
		Case 1
			Select code
			Case 0
				kind=0
			Case 2
				kind=2
			Case 4
				kind=1
			Case 6
				kind=3
			End Select
		Case 2
			Select code
			Case 1
				kind=1
			Case 3
				kind=3
			Case 4
				kind=1
			Case 6
				kind=3
			End Select
		Case 3
			Select code
			Case 0
				kind=2
			Case 2
				kind=2
			Case 4
				kind=3
			Case 6
				kind=3
			Case 8
				kind=2
			Case 12
				kind=3
			End Select
		Case 4
			Select code
			Case 0
				kind=2
			Case 1
				kind=1
			Case 4
				kind=3
			Case 6
				kind=3
			Case 8
				kind=2
			End Select
		End Select
		If kind=-1
			'Print "some other logical error"
			Return Null
		EndIf
		
		If Not p.many
			'print "P can't be plural"
			Return Null
		EndIf

		'Print "F: "+figure
		'Print "S: "+s.name
		'Print "P: "+p.name
		'Print "M: "+m.name
		p3:premise=premise.Create(kind,s,p)
		'Print p3.repr()
		Return p3
	End Function
End Type


Rem
t1:tterm=tterm.Create(	"a horse",..
						["animal","thing"],..
						[": is a horse",..
						": is not a horse",..
						": might be a horse",..
						": might not be a horse",..
						"all : are horses",..
						"no : are horses",..
						"some : are horses",..
						"some : are not horses"],..
						0..
					 )
					
t2:tterm=tterm.Create(	"hooved animals",..
						["animal","thing"],..
						[": has hooves",..
						": does not have hooves",..
						": might have hooves",..
						": might not have hooves",..
						"all : have hooves",..
						"no : have hooves",..
						"some : have hooves",..
						"some : do not have hooves"],..
						1..
					 )
t3:tterm=tterm.Create(	"cool things",..
						["thing"],..
						[": is cool",..
						": is not cool",..
						": might be cool",..
						": might not be cool",..
						"all : are cool",..
						"no : are cool",..
						"some : are cool",..
						"some : are not cool"],..
						1..
					)

t4:tterm=tterm.Create(	"Jim",..
						["thing","person"],..
						[": is Jim",..
						": is not Jim",..
						": might be Jim",..
						": might not be Jim",..
						"all : are Jim",..
						"no : are Jim",..
						"some : are Jim",..
						"some : are not Jim"],..
						0..
					)
EndRem
Function initsyllogism()
	Local nountxt$[]=[	": is ",..
						": is not ",..
						": might be ",..
						": might not be ",..
						"all : are ",..
						"no : are ",..
						"some : are ",..
						"some : are not "]
	Local adjtxt$[]=[	": is ",..
						": is not ",..
						": is sometimes ",..
						": is sometimes not ",..
						"all : are ",..
						"no : are ",..
						"some : are ",..
						"some : are not "]
	
	Local bits$[]
	For line$=EachIn world.filter("type=syllogism&kind=noun").values()
		line=Trim(line)
		bits=line.split(",")
		cname$=Trim(bits[0])
		If "aeiou".contains(Chr(cname[0]))
			name$="an "+cname
		Else
			name$="a "+cname
		EndIf
		If Len(bits)>1
			plural$=Trim(bits[1])
		Else
			plural=cname+"s"
		EndIf
		tterm.Create(plural,name,plural,1,nountxt)
	Next
	
	For line$=EachIn world.filter("type=syllogism&kind=adjective").values()
		name$=Trim(line)
		tterm.Create(name+" things",name,name,1,adjtxt)
	Next
	
	For line$=EachIn world.filter("type=syllogism&kind=thing").values()
		name$=Trim(line)
		tterm.Create(name,name,name,0,nountxt)
	Next
End Function

Rem
initsyllogism

p:premise=premise.generate()
For c=1 To 4
	tick=0
	While Not premise.addpremise(p)
		p=premise.generate()
		tick:+1
		If tick>50
			premises.removelast
			tick=0
		EndIf
	Wend
Next

For p:premise=EachIn premises
	Print p.repr()
Next
EndRem
