Type lterm

	Function parse:lterm(expr$)
		expr=Trim(expr)
		Local bits$[]
		bits=cleversplit(expr,"->")
		If Len(bits)>1	'implication
			'Print "imply"
			t2:lterm=lterm.parse(bits[Len(bits)-1])
			While Len(bits)>1
				t2=limplies.Create(lterm.parse(bits[Len(bits)-2]),t2)
				bits=bits[..Len(bits)-1]
			Wend
			Return t2
		EndIf
		bits=cleversplit(expr,"V")
		If Len(bits)>1
			'Print "or"
			t2:lterm=lterm.parse(bits[Len(bits)-1])
			While Len(bits)>1
				t2=lor.Create(lterm.parse(bits[Len(bits)-2]),t2)
				bits=bits[..Len(bits)-1]
			Wend
			Return t2
		EndIf
		bits=cleversplit(expr,"&")
		If Len(bits)>1
			'Print "and"
			t2:lterm=lterm.parse(bits[Len(bits)-1])
			While Len(bits)>1
				t2=land.Create(lterm.parse(bits[Len(bits)-2]),t2)
				bits=bits[..Len(bits)-1]
			Wend
			Return t2
		EndIf
		
		If Chr(expr[0])="!"
			'Print "and"
			Return lnot.Create(lterm.parse(expr[1..]))
		EndIf
		
		If Chr(expr[0])="("
			Return lterm.parse(expr[1..Len(expr)-1])
		EndIf
		
		Return lconstant.Create(expr)
	End Function

	Method truth(assumptions:TList) Abstract
	
	Method repr$() Abstract
End Type

Type lpredicate Extends lterm
	Field t1:lterm
End Type

Type lnot Extends lpredicate
	
	Function Create:lnot(t1:lterm)
		n:lnot=New lnot
		n.t1=t1
		Return n
	End Function

	Method truth(assumptions:TList)
		If lconstant(t1)
			For t:lterm=EachIn assumptions
				If lnot(t) And lconstant(lnot(t).t1) And lconstant(lnot(t).t1).name=lconstant(t1).name
					Return True
				EndIf
			Next
		EndIf
		
		assumptions.addlast Self
		
		Select TTypeId.ForObject(t1).name()
		Case "lnot"
			debugo "not not"
			Return lnot(t1).t1.truth(assumptions)
		Case "lor"
			debugo "not or"
			o:lor=lor(t1)
			If lnot.Create(o.t1).truth(assumptions) Return True	'relies on side-effect of !t1 being added to assumptions
			Return lnot.Create(o.t2).truth(assumptions)
		Case "limplies"
			debugo "not ->"
			i:limplies=limplies(t1)
			If i.t1.truth(assumptions) Return True	'relies on side-effect again
			Return lnot.Create(i.t2).truth(assumptions)
		Case "land"
			debugo "not and"
			a:land=land(t1)
			If lnot.Create(a.t1).truth(assumptions.copy()) And lnot.Create(a.t2).truth(assumptions.copy())
				Return True
			Else
				Return False
			EndIf
		Case "lconstant"
			debugo "not constant"
			For n:lnot=EachIn assumptions
				If lconstant(n.t1) And lconstant(t1).name=lconstant(n.t1).name And n<>Self Return True
			Next
			Return False
		End Select
	End Method
	
	Method repr$()
		Return "! ( "+t1.repr()+" )"
	End Method
End Type

Type land Extends lpredicate
	Field t2:lterm
	
	Function Create:land(t1:lterm,t2:lterm)
		a:land=New land
		a.t1=t1
		a.t2=t2
		Return a
	End Function

	Method truth(assumptions:TList)
		debugo "and"
		If t1.truth(assumptions) Return True	'relies on side-effect
		Return t2.truth(assumptions)
	End Method
	
	Method repr$()
		Return "( "+t1.repr()+" ) & ( "+t2.repr()+" )"
	End Method
End Type

Type lor Extends lpredicate
	Field t2:lterm
	
	Function Create:lor(t1:lterm,t2:lterm)
		o:lor=New lor
		o.t1=t1
		o.t2=t2
		Return o
	End Function

	Method truth(assumptions:TList)
		debugo "or"
		If t1.truth(assumptions.copy()) And t2.truth(assumptions.copy())
			Return True
		Else
			Return False
		EndIf
	End Method

	Method repr$()
		Return "( "+t1.repr()+" ) V ( "+t2.repr()+")"
	End Method
End Type

Type limplies Extends lpredicate
	Field t2:lterm
	
	Function Create:limplies(t1:lterm,t2:lterm)
		i:limplies=New limplies
		i.t1=t1
		i.t2=t2
		Return i
	End Function

	Method truth(assumptions:TList)
		debugo "->"
		If lnot.Create(t1).truth(assumptions.copy()) And t2.truth(assumptions.copy())
			Return True
		Else
			Return False
		EndIf
	End Method

	Method repr$()
		Return "( "+t1.repr()+" ) -> ( "+t2.repr()+" )"
	End Method
End Type

Type lconstant Extends lterm
	Field name$
	
	Function Create:lconstant(name$)
		c:lconstant=New lconstant
		c.name=name
		Return c
	End Function 

	Method truth(assumptions:TList)
		debugo "constant"
		Return True
	End Method

	Method repr$()
		Return name
	End Method
End Type


Function cleversplit$[](in$,m$,lb$="(",rb$=")")
	instring=0
	l:TList=New TList
	i=0
	While i<Len(in)
		c$=Chr(in[i])
		Select c
		Case lb
			instring:+1
		Case rb
			instring:-1
		Default
			If Not instring
				If in[i..i+Len(m)]=m
					l.addlast in[..i]
					in=in[i+Len(m)..]
					i=-1
				EndIf
			EndIf
		End Select
		i:+1
	Wend
	l.addlast in
	Local o$[l.count()]
	i=0
	For p$=EachIn l
		o[i]=p
		i:+1
	Next
	Return o
End Function

Function debugo(txt$)
	Print "  "+txt
End Function

While 1
	in$=Input(">")
	l:TList=New TList
	Print lterm.parse(in).repr()
	Print lterm.parse(in).truth(l)
Wend