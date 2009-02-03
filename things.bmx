Global genders$[]=["male","female"]

Global things:tmap
Type thing
	Method getinfo$(p$) Abstract
End Type

Type character Extends thing
	Field name$,firstname$,lastname$
	Field agree#
	Field gender$

	Function Create:character(gender$,conditions$="")
		c:character=New character
		names:db=world.filter(conditions)
		c.firstname$=names.filter("gender="+gender).pick("firstname")
		c.lastname=names.pick("lastname")
		c.name=c.firstname+" "+c.lastname
		Return c
	End Function
	
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
End Type

Type location Extends thing
	Field name$
	Field country$

	Function Create:location(country$,conditions$="")
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
End Type