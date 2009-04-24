Global directiongrammar:grammar

Type taglist
	Field tagmap:tmap
	
	Method New()
		tagmap=New tmap
	End Method
	
	Function Create:taglist(lines$[])
		tl:taglist=New taglist
		For line$=EachIn lines
			sn:sentence=directiongrammar.match(Trim(line),"addtag")
			name$=sn.nextvalue("name")
			r:ref=ref.Create(sn.getsymbol("ref"))
			tl.tagmap.insert name,r
		Next
		Return tl
	End Function
	
	Method tags:TList()
		l:TList=New TList
		For key$=EachIn tagmap.keys()
			l.addlast([key,value(key)])
		Next
		Return l
	End Method
	
	Method value$(key$)
		If tagmap.contains(key)
			r:ref=ref(tagmap.valueforkey(key))
			Return r.value()
		Else
			Return ""
		EndIf
	End Method
End Type

Type ref
	Function Create:ref(sn:sentence)
		val$=sn.value()
		Select sn.category
		Case "string"
			rs:rstring=New rstring
			rs.s=val[1..Len(val)-1]
			Return rs
		Case "info"
			ri:rinfo=New rinfo
			ri.key=val
			Return ri
		End Select
	End Function
	
	Method value$() Abstract
End Type

Type rstring Extends ref	'constant string
	Field s$
	
	Method value$()
		Return s
	End Method
End Type

Type rinfo Extends ref 	'lookup game info
	Field key$
	
	Method value$()
		'Return "<"+key+">"
		Return game.getinfo(key)
	End Method
End Type

Type tscript
	Field line$
	Field params$[]
	Function Create:tscript(line$,params$[])
		s:tscript=New tscript
		s.line=Trim(line)
		s.params=params
		Return s
	End Function
End Type

Type direction
	Method do() Abstract
End Type

Type dmake Extends direction
	Field name$
	Field kind$
	Field tl:taglist
	
	Function Create:dmake(name$,kind$,lines$[])
		Print "  make "+kind+" called "+name
		dm:dmake=New dmake
		dm.name=name
		dm.kind=kind
		dm.tl=taglist.Create(lines)
		Return dm			
	End Function
	
	Method do()
		Print "make "+kind+" "+name
		Local pair$[]
		conditions$=""
		For pair=EachIn tl.tags()
			Print "tag: "+pair[0]+" => "+pair[1]
			If pair[0]<>"gender"
				If conditions conditions:+"&"
				conditions:+pair[0]+"="+pair[1]
			EndIf
		Next
		Select kind
		Case "character"
			t:thing=character.Create(tl.value("gender"),conditions)
		Case "location"
			t:thing=location.Create(tl.value("country"),conditions)
		End Select
		Print "made "+t.getinfo("name")
		things.insert t.getinfo("name"),t
		game.variables.insert name,t.getinfo("name")
	End Method
End Type

Type dnarrate Extends direction
	Field name$
	Function Create:dnarrate(name$)
		Print "  narrate "+name
		dn:dnarrate=New dnarrate
		dn.name=name
		Return dn
	End Function
	
	Method do()
		game.narrate name
	End Method
End Type

Type dfight Extends direction
	Field name$
	Function Create:dfight(name$)
		Print "  fight "+name
		df:dfight=New dfight
		df.name=name
		Return df
	End Function
	
	Method do()
		game.curmode=New fight
	End Method
End Type

Type ddebate Extends direction
	Field name$
	Function Create:ddebate(name$)
		Print "  debate "+name
		dd:ddebate=New ddebate
		dd.name=name
		Return dd
	End Function
	
	Method do()
		game.curmode=New debate
	End Method
End Type

Type dconvo Extends direction
	Field name$
	Function Create:dconvo(name$)
		Print "  convo "+name
		dc:dconvo=New dconvo
		dc.name=name
		Return dc
	End Function
	
	Method do()
		game.curmode=New convo
	End Method
End Type

Type dassign Extends direction
	Field name$
	Field r:ref
	
	Function Create:dassign(name$,r:ref)
		Print "  assign "+name
		da:dassign=New dassign
		da.name=name
		da.r=r
		Return da
	End Function
	
	Method do()
		game.setinfo name,r.value()
	End Method
End Type

Type dyield Extends direction
	Field conditions:TList
	Method New()
		conditions=New TList
	End Method
	
	Function Create:dyield(conditions:TList)
		Print "  yield"
		dy:dyield=New dyield
		dy.conditions=conditions
		Return dy
	End Function
	
	Method do()
		game.yield conditions
	End Method
End Type

Type tcondition
	
	Function Create:tcondition(sn:sentence)
		Select sn.category
		Case "equals"
			ce:ceq=New ceq
			ce.name=sn.nextvalue("info")
			ce.r=ref.Create(sn.nextsymbol("ref"))
			Return ce
		End Select
	End Function
	
	Method met() Abstract
End Type

Type ceq Extends tcondition
	Field name$
	Field r:ref

	Method met()
		If game.getinfo(name)=r.value()
			Return True
		Else
			Return False
		EndIf
	End Method
End Type

Type drepeat
	Field times
	Field directions:TList
	
	Function Create:drepeat(times,directions:TList)
		Print "  repeat"
		dr:drepeat=New drepeat
		dr.times=times
		dr.directions=directions
		Return dr
	End Function
	
	Method do()
		If times>0
			times:-1
		EndIf
		For d:direction=EachIn directions
			game.adddirection d
		Next
		If times<>0
			'game.adddirection self
		EndIf
	End Method
End Type

Function getscripts:TList(lines$[])
	l:TList=New TList
	While Len(lines)
		If lines[0]
			n=tabcount(lines[0])
			i=1
			While i<Len(lines) And (tabcount(lines[i])>n Or Trim(lines[i])="")
				i:+1
			Wend
			l.addlast tscript.Create(lines[0],lines[1..i])
			If i<Len(lines)
				lines=lines[i..]
			Else
				lines=New String[0]
			EndIf
		Else
			lines=lines[1..]
		EndIf
	Wend	
	Return l
End Function

Function getdirections:TList(lines$[])
	directions:TList=New TList
	l:TList=getscripts(lines)
	For s:tscript=EachIn l
		sn:sentence=directiongrammar.match(s.line)
		'Print sn.repr()+"~n--"
		'For line$=EachIn s.params
		'	Print line
		'Next
		'Print "--"
		
		Select sn.category
		Case "make"
			sname$=sn.nextvalue("name")
			kind$=sn.nextvalue("kind")
			directions.addlast dmake.Create(sname,kind,s.params)
		Case "narrate"
			sname$=sn.nextvalue("name")
			directions.addlast dnarrate.Create(sname)
		Case "fight"
			sname$=sn.nextvalue("name")
			directions.addlast dfight.Create(sname)
		Case "debate"
			sname$=sn.nextvalue("name")
			directions.addlast ddebate.Create(sname)
		Case "convo"
			sname$=sn.nextvalue("name")
			directions.addlast dconvo.Create(sname)
		Case "assign"
			info$=sn.nextvalue("info")
			sn2:sentence=sn.getsymbol("ref")
			r:ref=ref.Create(sn2)
			directions.addlast dassign.Create(info,r)
		Case "yield"
			conditions:TList=New TList
			conditions.addlast tcondition.Create(sn.nextsymbol("condition"))
			While sn.getsymbol("and")
				sn2:sentence=sn.nextsymbol("and")
				conditions.addlast tcondition.Create(sn2.nextsymbol("condition"))
			Wend
			directions.addlast dyield.Create(conditions)
		Case "repeat"
			Select sn.getparam("times")
			Case "number"
				times=Int(sn.getvalue("times"))
			Case "forever"
				times=-1
			End Select
			directions.addlast drepeat.Create(times,getdirections(s.params))
		End Select
	Next
	Return directions
End Function


Global plots:tmap=New tmap
Type tplot
	Field name$
	Field directions:TList
	
	Method New()
		directions=New TList
	End Method
	
	Function loadall()
		plots=New tmap
		plotdb=New db
		For fname$=EachIn crawldir("plots")
			tplot.Load fname
		Next
	End Function
	
	Function Load:tplot(fname$)
		f:TStream=ReadFile(fname)
		
		l$=f.ReadLine()
		Local words$[]
		properties:tmap=New tmap
		While l<>""
			words=l.split(" ")
			properties.insert words[0]," ".join(words[1..])
			l=f.ReadLine()
		Wend
		rest$=f.ReadString(f.size()-f.pos())
		name$=filename(fname)
		p:tplot=tplot.Create(name,rest.split("~n"))
		plotdb.addlast datum.Create(name,properties)
		Print name
	End Function
	
	Function pick:tplot(kind$="",conditions$="")
		d:datum=plotdb.filter(conditions).pickdatum(kind)
		name$=d.value
		If d.property("happens")="once"
			plotdb.remove d
			Print "remove "+name
		EndIf
		Return tplot(plots.valueforkey(name))
	End Function

	
	Function Create:tplot(name$,lines$[])
		Print "Make plot "+name
		p:tplot=New tplot
		p.name=name
		plots.insert p.name,p
		p.directions=getdirections(lines)
		Return p
	End Function
		
End Type

Type suspense
	Field conditions:TList
	Field directions:TList
	
	Function Create:suspense(conditions:TList,directions:TList)
		s:suspense=New suspense
		s.conditions=conditions
		s.directions=directions
		Return s
	End Function
	
	Method met()
		For c:tcondition=EachIn conditions
			If Not c.met() Return False
		Next
		Return True
	End Method
End Type

Rem
'gdebugging=1
grammars=New tmap

Global directiongrammar:grammar=grammar.fromfile("grammars/direction.txt")

Local lines$[]=loadtxt("plots/nemesis.txt").split("~n")
i=0
While Trim(lines[i])
	i:+1
Wend
lines=lines[i+1..]
tplot.Create "nemesis",lines
EndRem



