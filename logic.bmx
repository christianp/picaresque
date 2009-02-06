Type lterm

	Function parse:lterm(expr$)
		expr=Trim(expr)
		Local bits$[]
		bits=cleversplit(expr,"->")
		If Len(bits)>1	'implication
			''print "imply"
			t2:lterm=lterm.parse(bits[Len(bits)-1])
			While Len(bits)>1
				t2=limplies.Create(lterm.parse(bits[Len(bits)-2]),t2)
				bits=bits[..Len(bits)-1]
			Wend
			Return t2
		EndIf
		bits=cleversplit(expr,"V")
		If Len(bits)>1
			''print "or"
			t2:lterm=lterm.parse(bits[Len(bits)-1])
			While Len(bits)>1
				t2=lor.Create(lterm.parse(bits[Len(bits)-2]),t2)
				bits=bits[..Len(bits)-1]
			Wend
			Return t2
		EndIf
		bits=cleversplit(expr,"&")
		If Len(bits)>1
			''print "and"
			t2:lterm=lterm.parse(bits[Len(bits)-1])
			While Len(bits)>1
				t2=land.Create(lterm.parse(bits[Len(bits)-2]),t2)
				bits=bits[..Len(bits)-1]
			Wend
			Return t2
		EndIf
		
		If Chr(expr[0])="!"
			''print "and"
			Return lnot.Create(lterm.parse(expr[1..]))
		EndIf
		
		If Chr(expr[0])="("
			Return lterm.parse(expr[1..Len(expr)-1])
		EndIf
		
		Return lconstant.Create(expr)
	End Function

	Method oldtruth(assumptions:TList) Abstract
	
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

	Method oldtruth(assumptions:TList)
		debugo "not: "+repr()
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
			Return lnot(t1).t1.oldtruth(assumptions)
		Case "lor"
			debugo "not or"
			o:lor=lor(t1)
			If lnot.Create(o.t1).oldtruth(assumptions) Return True	'relies on side-effect of !t1 being added to assumptions
			Return lnot.Create(o.t2).oldtruth(assumptions)
		Case "limplies"
			debugo "not ->"
			i:limplies=limplies(t1)
			If i.t1.oldtruth(assumptions) Return True	'relies on side-effect again
			Return lnot.Create(i.t2).oldtruth(assumptions)
		Case "land"
			debugo "not and"
			a:land=land(t1)
			If lnot.Create(a.t1).oldtruth(assumptions.copy()) And lnot.Create(a.t2).oldtruth(assumptions.copy())
				'print "true"
				Return True
			Else
				'print "false"
				Return False
			EndIf
		Case "lconstant"
			debugo "not constant"
			For c:lconstant=EachIn assumptions
				If lconstant(t1).name=c.name 
					'print "true"
					Return True
				EndIf
			Next
			'print "false"
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

	Method oldtruth(assumptions:TList)
		debugo "and: "+repr()
		If t1.oldtruth(assumptions) 
			'print "true"
			Return True	'relies on side-effect
		EndIf
		Return t2.oldtruth(assumptions)
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

	Method oldtruth(assumptions:TList)
		debugo "or: "+repr()
		If t1.oldtruth(assumptions.copy()) And t2.oldtruth(assumptions.copy())
			'print "true"
			Return True
		Else
			'print "false"
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

	Method oldtruth(assumptions:TList)
		debugo "implies: "+repr()
		If lnot.Create(t1).oldtruth(assumptions.copy()) And t2.oldtruth(assumptions.copy())
			'print "true"
			Return True
		Else
			'print "false"
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

	Method oldtruth(assumptions:TList)
		debugo "constant: "+repr()
		For n:lnot=EachIn assumptions
			If lconstant(n.t1) And lconstant(n.t1).name=name
				'print "true"
				Return True
			EndIf
		Next
		'print "false"
		Return False
	End Method

	Method repr$()
		Return name
	End Method
End Type

Function truth(t:lterm)
	l:TList=New TList
	l.addlast t
	Return truthof(l)
End Function

Function truthof(unchecked:TList,assumptions:TList=Null)
	If Not assumptions
		assumptions=New TList
	EndIf
	While unchecked.count()
		t:lterm=lterm(unchecked.removefirst())
		'print "   "+t.repr()
		assumptions.addlast t
		Select TTypeId.ForObject(t).name()
		Case "lnot"
			t1:lterm=lnot(t).t1
			Select TTypeId.ForObject(t1).name()
			Case "lnot"
				'print "not not A - assume A"
				unchecked.addlast lnot(t1).t1
			Case "land"
				'print "not (A and B) - check not A and not B separately"
				a:land=land(t1)
				u2:TList=unchecked.copy()
				u2.addlast lnot.Create(a.t1)
				u3:TList=unchecked.copy()
				u3.addlast lnot.Create(a.t2)
				If truthof(u2,assumptions.copy()) And truthof(u3,assumptions.copy())
					'print "--True"
					Return True
				EndIf
			Case "lor"
				'print "not (A or B) - assume not A and not B"
				o:lor=lor(t1)
				unchecked.addlast lnot.Create(o.t1)
				unchecked.addlast lnot.Create(o.t2)
			Case "limplies"
				'print "not (A implies B) - assume A and not B"
				i:limplies=limplies(t1)
				unchecked.addlast i.t1
				unchecked.addlast lnot.Create(i.t2)
			Case "lconstant"
				'print "not A - if we already have A, done"
				c:lconstant=lconstant(t1)
				For c2:lconstant=EachIn assumptions
					If c2.name=c.name
						'print "--True"
						Return True
					EndIf
				Next
			End Select
		Case "land"
			'print "A and B - assume A and B"
			a:land=land(t)
			unchecked.addlast a.t1
			unchecked.addlast a.t2
		Case "lor"
			'print "A or B - check A and B separately"
			o:lor=lor(t)
			u2:TList=unchecked.copy()
			u2.addlast o.t1
			u3:TList=unchecked.copy()
			u3.addlast o.t2
			If truthof(u2,assumptions.copy()) And truthof(u3,assumptions.copy())
				'print "--True"
				Return True
			EndIf
		Case "limplies"
			'print "A implies B - check not A and B separately"
			i:limplies=limplies(t)
			u2:TList=unchecked.copy()
			u2.addlast lnot.Create(i.t1)
			u3:TList=unchecked.copy()
			u3.addlast i.t2
			If truthof(u2,assumptions.copy()) And truthof(u3,assumptions.copy())
				'print "--True"
				Return True
			EndIf
		Case "lconstant"
			'print "A - if we have not A, done"
			c:lconstant=lconstant(t)
			For n:lnot=EachIn assumptions
				If lconstant(n.t1) And lconstant(n.t1).name=c.name
					'print "--True"
					Return True
				EndIf
			Next
		End Select
	Wend
	'print "--False"
	Return False
End Function


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

Rem
While 1
	in$=Input(">")
	l:TList=New TList
	'print lterm.parse(in).repr()
	'print lterm.parse(in).truth(l)
Wend
endrem