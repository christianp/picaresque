Include "jsondecoder.bmx"
Include "grammar.bmx"
Include "helpers.bmx"
Include "things.bmx"
Include "db.bmx"


Global world:db
Global game:tgame
Type tgame
	Field progress
	Field failures
	Field hero:character,love:character,nemesis:character
	
	Method New()
		SeedRnd MilliSecs()
		grammar.loadall
		world=New db
		world.dirload "world"
	End Method
End Type

game=New tgame

For i=1 To 10
	country$=world.filter("type=country").pick()
	c:character=character.Create("male","country="+country)
	lo:location=location.Create(country)
	Print c.name+" of "+lo.name+", "+country
Next