'Include "fonttest.bmx"
'Include "gfx.bmx"
'Include "grammar.bmx"
'Include "helpers.bmx"

'lettermaker

Rem
Global handwritingfonts:timagefont[]
Global printfonts:timagefont[]
Global headlinefonts:timagefont[]
Global textheights:tmap
Global textstarts:tmap
Global allfonts:tmap
Global typetemplates:tmap
Global dfonts:tmap
EndRem




Rem
Function loadfonts()
	textheights=New tmap
	textstarts=New tmap
	allfonts=New tmap
	jd:jsondecoder=jsondecoder.Create(loadtxt("fonts/fonts.txt"))
	jd.parse()
	j:jsonobject=jsonobject(jd.things.first())
	handwritingfonts=loadfontset(j,"handwriting")
	printfonts=loadfontset(j,"print")
	headlinefonts=loadfontset(j,"headline")

	dfonts:tmap=New tmap
	dfonts.insert "handwriting",handwritingfonts[0]
	dfonts.insert "print",printfonts[0]
	dfonts.insert "headline",headlinefonts[0]
End Function

Function loadfontset:timagefont[](j:jsonobject,kind$,setheights=0)
	l:TList=New TList
	For fo:jsonobject=EachIn j.getarrayvalue(kind).values
		jp:jsonpair=jsonpair(fo.pairs.first())
		fname$=jp.name
		tif:timagefont=LoadImageFont("fonts/"+fname,50)
		allfonts.insert fname,tif
		l.addlast tif
		
		If setheights
			SetImageFont tif
			SetScale 3,3
			height=-1
			starty=-1
			While height=-1
				DrawText "Hello there, my young boy",0,0
				my=MouseY()
				DrawLine 0,my,800,my
				Flip
				Cls
				If MouseHit(1)
					If starty>=0
						height=my/3
					Else
						starty=my/3
					EndIf
				EndIf
			Wend
			Print "~t{ ~q"+fname+"~q  : ["+String(starty)+" , "+String(height)+"] },"
		Else
			ja:jsonarray=jsonarray(jp.value)
			Local arr:Object[]
			arr=ja.values.toarray()
			starty=jsonnumbervalue(arr[0]).number
			height=jsonnumbervalue(arr[1]).number
		EndIf
		textheights.insert tif,String(height)
		textstarts.insert tif,String(starty)
		
	Next
	Return timagefont[](l.toarray())
End Function

EndRem


Type typecolumn
	Field width#
	Field height#
	Field x#,y#
	Field maxy#
	
	Function Create:typecolumn(x#,y#,width#,height#=-1)
		tc:typecolumn=New typecolumn
		tc.x=x
		tc.y=y
		tc.width=width
		tc.height=height
		Return tc
	End Function
End Type


Type textblock
	Field txt$
	Field curcolumn:typecolumn,columnstack:TList
	Field width#
	Field i,x#,y#
	Field curchr$
	Field fonts:tmap
	Field curfont:wfont
	Field scale#,ascale#
	Field curtl:typeline
	Field justify
	Field typelines:TList
	
	Function Create:textblock(txt$,width#,ascale#=1,fonts:tmap=Null)
		tb:textblock=New textblock
		tb.txt=txt
		If Not fonts fonts=dfonts
		tb.fonts=fonts
		tb.ascale=ascale
		tb.width=width
		tb.render
		Return tb
	End Function
	
	Method getnext(tokens$[],onlywhitespace=0)
		oldi=i
		While i<Len(txt)
			c$=Chr(txt[i])
			i:+1
			For token$=EachIn tokens
				If c=token 
					curchr=c
					Return 1
				EndIf
			Next
			If onlywhitespace And (Not (c=" " Or c="~t" Or c="~n" Or c="~r"))
				i:-1
				Return 0
			EndIf
		Wend
		i=oldi
		Return 0
	End Method
	
	Method popcolumn()
		If curcolumn
			owidth#=curcolumn.width
			oheight#=curcolumn.height
		Else
			owidth#=0
			oheight#=1
		EndIf
		curcolumn=typecolumn(columnstack.removelast())
		If oheight=-1 And owidth<>curcolumn.width
			curcolumn.y=y
		EndIf
		If curtl And curcolumn.width<=owidth
			typelines.addlast curtl
			curtl=Null
		EndIf
		y=curcolumn.y
		newline
		If curcolumn.width<=owidth
			y=curcolumn.y
		EndIf
		'Print "("+String(curcolumn.x)+","+String(curcolumn.y)+","+String(curcolumn.width)+","+String(curcolumn.height)+")"
	End Method

	Method render(starty=0)
		typelines=New TList
		x=0
		y=starty
		in$=""
		i=0
		setfont "print"
		scale=ascale
		justify=-1
		columnstack=New TList
		columnstack.addlast typecolumn.Create(x,y,width)
		popcolumn
		While c<Len(txt)
			oldi=i
			If getnext(["^"])
				in=txt[oldi..i-1]
				rendertxt in
				oldi=i
				getnext(["^"])
				domarkup txt[oldi..i-1]
			Else
				rendertxt txt[i..]
				c=Len(txt)
			EndIf
		Wend
		newline
		While columnstack.count()
			popcolumn
		Wend
	End Method

	Rem
	Method rendertxt(in$)
		'Print in
		SetImageFont curfont


		Local txtlines$[]
		txtlines=in.split("~n")
		oline$=""

		lastline$=""
		For li=0 To Len(txtlines)-1
			line$=txtlines[li]
			'Print "---"+line+"----~q"+lastline+"~q"
			If Trim(line)="" And li>0 'And lastline="" 
				newline
				curtl.height=10*ascale
				newline
				'y:+clevertextheight("",curfont)*scale
			EndIf
			Local words$[]
			words=line.split(" ")
			For word$=EachIn words
				If word.Trim()<>""
					word=Replace(word,"~t","    ")
					word:+" "
					twidth#=TextWidth(word)*scale
					If x+twidth>curcolumn.width+curcolumn.x
						newline
					EndIf
					curtl.addelement(typetxt.Create(word,curfont,scale,x))
					If curtl.height+curtl.y>curcolumn.y+curcolumn.height And curcolumn.height>0
						columnwrap
					EndIf
					x:+twidth
				EndIf
			Next
			If li<Len(txtlines)-1
				'newline
			EndIf
			lastline$=line
		Next
		'newline
	End Method
	EndRem

	Method rendertxt(in$)
		'Print in
		Local txtlines$[]
		txtlines=in.split("~n")
		oline$=""

		lastline$=""
		For li=0 To Len(txtlines)-1
			line$=txtlines[li]
			'Print "---"+line+"----~q"+lastline+"~q"
			If Trim(line)="" And li>0 'And lastline="" 
				newline
				curtl.height=10*ascale
				newline
				'y:+clevertextheight("",curfont)*scale
			EndIf
			Local words$[]
			words=line.split(" ")
			For word$=EachIn words
				If word.Trim()<>""
					word=Replace(word,"~t","    ")
					word:+" "
					twidth#=curfont.width(word,scale*50)
					If x+twidth>curcolumn.width+curcolumn.x
						newline
					EndIf
					curtl.addelement(typetxt.Create(word,curfont,scale,x))
					If curtl.height+curtl.y>curcolumn.y+curcolumn.height And curcolumn.height>0
						columnwrap
					EndIf
					x:+twidth
				EndIf
			Next
			If li<Len(txtlines)-1
				'newline
			EndIf
			lastline$=line
		Next
		'newline
	End Method
	
	Method columnwrap()
		ocurtl:typeline=curtl
		curtl=Null
		popcolumn
		curtl=ocurtl
		ocurtl.move(x,y)
	End Method
	
	Method newline()
		If curtl
			'curtl.draw
			typelines.addlast curtl
			y:+curtl.height*1.5
			If y>curcolumn.maxy
				curcolumn.maxy=y
				'Print "~t~t~t"+String(y)
			EndIf
			If y>curcolumn.height+curcolumn.y And curcolumn.height>0
				popcolumn
			EndIf
		EndIf
		x=curcolumn.x
		curtl=typeline.Create(x,y,justify,curcolumn.width)
	End Method
		
	Method setfont(fname$)
		If fonts.contains(fname)
			curfont=wfont(fonts.valueforkey(fname))
		ElseIf allfonts.contains(fname)
			curfont=wfont(allfonts.valueforkey(fname))
		EndIf
	End Method
	
	Method domarkup(in$)
		'Print in
		Global g:grammar=grammar.fromfile("testgrammar.txt")
		For cmd$=EachIn in.split(",")
			sn:sentence=g.match(Trim(cmd))
			Select sn.category
			Case "rule"
				size#=Float(sn.nextparam("number"))
				newrule size
			Case "font"
				fname$=sn.nextparam("fonttype")
				setfont fname
			Case "size"
				size#=Float(sn.nextparam("number"))
				setsize size
			Case "align"
				align$=sn.nextparam("aligntype")
				alignto align
			Case "column"
				number=Int(sn.nextparam("number"))
				height#=Float(sn.nextparam("number"))
				If sn.getparam("number")
					width#=Float(sn.nextparam("number"))
				Else
					width#=0
				EndIf
				
				newcolumn number, width, height
			Case "endcolumn"
				number=Int(sn.nextparam("number"))
				endcolumn number
			End Select
		Next
	End Method
	
	Method newrule(size#)
		'Print "rule "+size
		twidth#=curcolumn.width
		length#=twidth*size*.01
		newline
		curtl.justify=0
		rx=curcolumn.x+twidth/2-length/2
		tr:typerule=typerule.Create(curcolumn.x,length,2*ascale,20*ascale)
		curtl.addelement tr
		newline
	End Method
	
	Method setsize(size#)
		'Print "size "+size
		scale=ascale*size/100.0
	End Method
	
	Method alignto(align$)
		'Print "align "+align
		Select align
		Case "left"
			justify=-1
		Case "centre"
			justify=0
		Case "right"
			justify=1
		End Select
		curtl.justify=justify
	End Method	
	
	Method newcolumn(number,width#,height#)
		'Print "column "+number+" "+width+" "+height
		If width
			twidth#=curcolumn.width*width*.01
		Else
			twidth#=curcolumn.width
		EndIf
		If height>0
			height:*ascale
		EndIf
		cwidth#=twidth/number
		x=curcolumn.x+curcolumn.width/2+twidth/2
		'If height>0
			columnstack.addlast typecolumn.Create(curcolumn.x,y+height,curcolumn.width,curcolumn.height-y-height)
		'EndIf
		For c=1 To number
			x:-cwidth
			columnstack.addlast typecolumn.Create(x,y,cwidth-10*ascale,height)
		Next
		popcolumn
	End Method
	
	Method endcolumn(number)
		'Print "endcolumn "+number
		If number=0
			owidth#=curcolumn.width
			'Print owidth
			oy=y+curtl.height*1.5
			While curcolumn.width=owidth And columnstack.count()
				y=curcolumn.maxy
				popcolumn
				'Print String(curcolumn.width)+"  "+String(columnstack.count())
			Wend
		Else
			'Print "OMAXY "+String(curcolumn.maxy)
			owidth#=curcolumn.width
			ocolumn:typecolumn=curcolumn
			For c=1 To number
				If columnstack.count()
					popcolumn
					'If curcolumn.width=ocolumn.width
						curcolumn.maxy=ocolumn.maxy
					'EndIf
				EndIf
			Next
		EndIf
		If curcolumn.y<curcolumn.maxy And curcolumn.width<>owidth
			curcolumn.y=curcolumn.maxy
			y=curcolumn.maxy
			curtl.y=y
			curtl.x=curcolumn.x
		EndIf
	End Method
	
	Method draw(offx=0,offy=0)
		SetBlend ALPHABLEND
		For tl:typeline=EachIn typelines
			tl.draw offx,offy
		Next
	End Method
	
End Type

Rem
Function fittext:TList(txt$,width#)
	width:-50
	flines:TList=New TList
	
	While TextWidth(txt)>width
		Local words$[]
		words=txt.split(" ")
		ltxt$=words[0]+" "
		c=1
		If Len(words)>1
			While TextWidth(ltxt+words[c])<width
				ltxt:+words[c]+" "
				c:+1
			Wend
		EndIf
		flines.addlast ltxt
		txt=txt[Len(ltxt)..]
	Wend
	flines.addlast txt
	
	Return flines
End Function
EndRem

Type typeelement
	Field x#
	Field r,g,b
	
	Method draw(dx#,dy#)
	
	End Method
	
	Method height#()
	End Method
	Method width#()
	End Method
End Type

Type typetxt Extends typeelement
	Field txt$
	Field font:wfont
	Field size#
	Field jiggle#
	
	Function Create:typetxt(txt$,font:wfont,scale#,x#,r=0,g=0,b=0)
		tt:typetxt=New typetxt
		tt.txt=txt
		tt.font=font
		tt.size=scale*50
		tt.x=x
		tt.r=r
		tt.g=g
		tt.b=b
		
		Return tt
	End Function
	
	Rem
	Method draw(dx#,dy#)
		SetImageFont font
		SetScale scale,scale
		SetColor r,g,b
		theight#=height()
		twidth#=width()
		ox#=dx+x
		oy#=dy-theight-jiggle*scale
		DrawText txt,ox,oy
	End Method
	
	Method drawzoom(dx#,dy#)
		SetImageFont font
		SetColor r,g,b
		theight#=height()
		twidth#=width()
		ox#=dx+x
		oy#=dy-theight-jiggle*scale
		SetScale scale,scale
		DrawText txt,ox,oy
	End Method
	EndRem
	
	Method draw(dx#,dy#)
		SetColor r,g,b
		font.draw(txt,dx+x,dy,size)
		'SetColor 255,255,255
		'SetScale 1,1
		'DrawLine dx+x,dy,dx+x+width(),dy
		'DrawLine 0,0,dx,dy
		'DrawText width(),dx,dy
	End Method
	
	Rem
	Method height#()
		SetImageFont font
		theight#=clevertextheight(txt)*scale-jiggle*scale
		Return theight
	End Method
	
	Method width#()
		SetImageFont font
		twidth#=TextWidth(txt)*scale
		Return twidth
	End Method
	EndRem
	
	Method height#()
		Return font.height(size)
	End Method
	Method width#()
		Return font.width(txt,size)
	End Method
End Type

Type typerule Extends typeelement
	Field length#,size#
	Field myheight#
	
	Function Create:typerule(x#,length#,size#,height#,r=0,g=0,b=0)
		tr:typerule=New typerule
		tr.x=x
		tr.length=length
		tr.size=size
		tr.myheight=height
		tr.r=r
		tr.g=g
		tr.b=b
		'Print "rule at "+String(x)+", "+String(length)+" long, "+String(tr.myheight)+" high"
		Return tr
	End Function
	
	Method draw(dx#,dy#)
		SetLineWidth size
		SetScale 1,1
		SetColor r,g,b
		DrawLine dx+x,dy-myheight,dx+x+length,dy-myheight
	End Method
	
	Rem
	Method drawzoom(dx#,dy#)
		SetLineWidth size*zoom
		SetScale 1,1
		SetColor r,g,b
		DrawLine dx+x,dy-myheight,dx+x+length,dy-myheight
	End Method
	EndRem
	
	Method height#()
		Return myheight
	End Method
	
	Method width#()
		Return length
	End Method
End Type

Type typeline
	Field elements:TList
	Field x#,y#,startx#
	Field height#,width#
	Field maxwidth#
	Field justify
	
	Method New()
		elements=New TList
	End Method
	
	Function Create:typeline(startx#,y#,justify,maxwidth#)
		tl:typeline=New typeline
		tl.startx=startx
		tl.y=y
		tl.justify=justify
		tl.maxwidth=maxwidth
		Return tl
	End Function
	
	Method addelement(te:typeelement)
		theight#=te.height()
		twidth#=te.width()
		If theight>height
			height=theight
		EndIf
		width:+twidth
		elements.addlast te
	End Method
	
	Method move(newx#,newy#)
		For tt:typetxt=EachIn elements
			tt.x:+newx-startx
		Next
		x:+newx-startx
		y=newy
	End Method
	
	
	Method draw(xoff#=0,yoff#=0)
		Select justify
		Case -1 'left justify
			x#=0
		Case 0 'centre
			x#=maxwidth/2-width/2
		Case 1 'right
			x#=maxwidth-width
		End Select

		For te:typeelement=EachIn elements
			te.draw(xoff+x,yoff+y+height)
		Next
	End Method
	
	Rem
	Method drawzoom(xoff#=0,yoff#=0)
		Select justify
		Case -1 'left justify
			x#=0
		Case 0 'centre
			x#=maxwidth/2-width/2
		Case 1 'right
			x#=maxwidth-width
		End Select
		For te:typeelement=EachIn elements
			te.drawzoom(xoff+x,yoff+y+height)
		Next
	End Method
	EndRem
End Type


Rem
Function clevertextheight(txt$,tif:timagefont=Null)
	If Not tif
		tif:timagefont=GetImageFont()
	EndIf
	Return Int(String(textheights.valueforkey(tif)))
End Function
EndRem

Rem
grammars=New tmap
Graphics 800,800,0
SetBlend ALPHABLEND
SetClsColor 248,236,194
SetColor 0,0,0
SeedRnd MilliSecs()
Cls

loadfonts

While 1
fonts:tmap=New tmap
fonts.insert "handwriting",handwritingfonts[Rand(0,Len(handwritingfonts)-1)]
fonts.insert "print",printfonts[Rand(0,Len(printfonts)-1)]
fonts.insert "headline",headlinefonts[Rand(0,Len(headlinefonts)-1)]
txt$=loadtxt("test.txt")
scale#=Rnd(.5,1)
tb:textblock=textblock.Create(txt,800,scale,fonts)
While Not KeyHit(KEY_SPACE)
	DrawLine 0,tb.y,800,tb.y
	xoff=Rand(-50,50)
	yoff=Rand(100)
	tb.draw
	Flip
	Cls
	If AppTerminate() End
Wend
Wend
EndRem