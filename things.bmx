Global genders$[]=["male","female"]

Type character
	Field name$,firstname$,lastname$
	Field agree#
	Field gender$

	Function Create:character(gender$,conditions$="")
		c:character=New character
		names:db=world.filter("gender="+gender+" & "+conditions)
		Print names.filter("type=firstname").count()
		c.firstname$=names.filter("type=firstname").pick()
		c.lastname="Bloggs"
		c.name=c.firstname+" "+c.lastname
		Return c
	End Function
End Type

Type location
	Field name$
	Field country$

	Function Create:location(country$,conditions$="")
		lo:location=New location
		lo.country=country
		lo.name=world.filter("type=locationname & country="+lo.country+" & "+conditions).pick()
		Return lo
	End Function
End Type