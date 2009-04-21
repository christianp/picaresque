Function picklist:Object(l:TList,f!(min_value!,max_value!)=Rnd)
	n=f(0,1)*l.count()
	If n=l.count() n:-1
	Return l.valueatindex(n)
End Function

Function pickarr:Object(arr:Object[])
	Return arr[Rand(0,Len(arr)-1)]
End Function


Function crawldir:TList(path$,l:TList=Null)
	If Not l
		l:TList=New TList
	EndIf
	For t$=EachIn LoadDir(path)
		If Not (t="." Or t="..")
			fpath$=path+"/"+t
			Select FileType(fpath)
			Case 1
				l.addlast fpath
			Case 2
				crawldir fpath,l
			End Select
		EndIf
	Next
	Return l
End Function

Function filename$(path$)
	Local bits$[]=path.split("/")
	name$=bits[Len(bits)-1]
	c=Len(name)-1
	While c>=0 And name[c]<>46
		c:-1
	Wend
	If c=-1 Return name
	Return name[..c]
End Function

Function debugo(txt$)
	Print "  >> "+txt
End Function

Function loadtxt$(filename$)
	f:TStream=ReadFile(filename)
	txt$=f.ReadString(StreamSize(f))
	CloseFile(f)
	Return txt
End Function


Global romandecs[]=[1000,900,500,400,100,90,50,40,10,9,5,4,1]
Global romannums$[]=["M","CM","D","CD","C","XC","L","XL","X","IX","V","IV","I"]
Function romannumeral$(n)
	i=0
	s$=""
	While n
		If n>=romandecs[i]
			n:-romandecs[i]
			s:+romannums[i]
		Else
			i:+1
		EndIf
	Wend
	Return s
End Function

Function tabcount(in$)
	If Not in Return 0
	c=0
	While in[c]=9
		c:+1
	Wend
	Return c
End Function


Function poisson(lambda!)
	If lambda>500 Return poisson(lambda/2)+poisson(lambda/2)
	k=0
	u!=Rnd(0,1)
	fact=1
	p!=Exp(-lambda)
	u:-p
	While u>0
		k:+1
		fact:*k
		p:*lambda/k
		u:-p
	Wend
	Return k
End Function

Rem
Function cleversplit$[](in$,m$)
	c=0
	l:TList=New TList
	While c<Len(in)
		Select in[c]
		Case m[0]
			If in[c..c+Len(m)]=m
				l.addlast in[..c]
				in=in[c+Len(m)..]
				c=-1
			EndIf
		Case 92	'backslash
			c:+1
		End Select
		c:+1
	Wend
	l.addlast in
	Local bits$[l.count()]
	c=0
	For bit$=EachIn l
		bits[c]=bit
		c:+1
	Next
	Return bits
End Function
endrem