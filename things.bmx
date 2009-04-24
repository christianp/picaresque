Global things:tmap
Type thing
	Method getinfo$(p$) Abstract
	Method setinfo(p$,v$) Abstract
	
	Function find:thing(name$)
		If things.contains(name)
			Return thing(things.valueforkey(name))
		EndIf
	End Function
End Type

Type character Extends thing
	Field name$,firstname$,lastname$
	Field agree#
	Field gender$

	Function Create:character(gender$,conditions$="")
		Print "make "+gender+" character ("+conditions+")"
		c:character=New character
		names:db=world.filter(conditions)
		c.gender=gender
		firstname$=names.filter("gender="+c.gender).pick("firstname")
		lastname$=names.pick("lastname")
		c.setname firstname,lastname
		Return c
	End Function
	
	Method setname(f$="",l$="")
		If f firstname=f
		If l lastname=l
		name=firstname+" "+lastname
	End Method
	
	Method getinfo$(p$)
		Select p
		Case "fullname"
			Return name
		Case "name"
			Return firstname
		Case "lastname"
			Return lastname
		Case "gender"
			Return gender
		End Select
	End Method
	
	Method setinfo(p$,v$)
		Select p
		Case "fullname"
			Local bits$[]=v.split(" ")
			setname bits[0],bits[1]
		Case "name"
			setname v,""
		Case "lastname"
			setname "",v
		Case "gender"
			gender=v
		End Select
	End Method
End Type

Type location Extends thing
	Field name$
	Field country$

	Function Create:location(country$,conditions$="")
		Print "make location ("+conditions+") in "+country
		lo:location=New location
		lo.country=country
		lo.name=world.filter("country="+lo.country+" & "+conditions).pick("locationname")
		Return lo
	End Function
	
	Method getinfo$(p$)
		Select p
		Case "name"
			Return name
		Case "country"
			Return country
		End Select
	End Method
	
	Method setinfo(p$,v$)
		Select p
		Case "name"
			name=v
		Case "country"
			country=v
		End Select
	End Method
End Type