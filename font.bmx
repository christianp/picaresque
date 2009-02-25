Global handwritingfonts:wfont[]
Global printfonts:wfont[]
Global headlinefonts:wfont[]
Global allfonts:tmap
Global dfonts:tmap


Function loadfonts()
	allfonts=New tmap
	printfonts=loadfontset("print")
	handwritingfonts=loadfontset("handwriting")
	headlinefonts=loadfontset("headline")

	dfonts:tmap=New tmap
	dfonts.insert "handwriting",handwritingfonts[0]
	dfonts.insert "print",printfonts[0]
	dfonts.insert "headline",headlinefonts[0]
	
	dfonts=pickfonts()
End Function

Function loadfontset:wfont[](kind$)
	Local lines$[]=loadtxt("fonts/"+kind+" fonts.txt").split("~n")
	Local wfonts:wfont[Len(lines)/3]
	i=0
	m:tmap=New tmap
	While i<Len(lines)
		fname$=Trim(lines[i])
		h#=Float(lines[i+1])
		jiggle#=Float(lines[i+2])
		wf:wfont=wfont.Create("fonts/"+fname,h,jiggle)
		allfonts.insert fname,wf
		wfonts[i/3]=wf
		i:+3
	Wend
	Return wfonts
End Function

Function pickfonts:tmap()
	fonts:tmap=New tmap
	fonts.insert "handwriting",handwritingfonts[Rand(Len(handwritingfonts)-1)]
	fonts.insert "print",printfonts[Rand(Len(printfonts)-1)]
	fonts.insert "headline",headlinefonts[Rand(Len(headlinefonts)-1)]
	Return fonts
End Function



Rem
Function testfont(fname$)
	h#=1
	jiggle#=0
	style=SMOOTHFONT
	wf:wfont=wfont.Create(fname,h,jiggle,style)
	While Not KeyHit(KEY_ENTER)
		wf.h=h
		wf.jiggle=jiggle
		
		y#=0
		txt$="hello there, you"
		For c=1 To 10
			size#=c*(1+10.0*MouseX()/600.0)
			y:+wf.height(size)
			wf.draw txt,0,y,size
			DrawLine 0,y,wf.width(txt,size),y
		Next
		Flip
		Cls
		
		h:+(KeyDown(KEY_UP)-KeyDown(KEY_DOWN))*.001
		jiggle:+(KeyDown(KEY_RIGHT)-KeyDown(KEY_LEFT))*.001
		
		
		If MouseHit(1)
			style=SMOOTHFONT-style
			wf:wfont=wfont.Create(fname,.94,.1,style)
		EndIf
		
		If AppTerminate() Or KeyHit(KEY_ESCAPE)
			End
		EndIf
	Wend
	Print fname
	Print "  "+h
	Print "  "+jiggle
End Function
EndRem

Const wfontinc#=2
Type wfont
	Field h#
	Field jiggle#
	Field images:timagefont[]
	Field scale#
	
	Function Create:wfont(fname$,height#,jiggle#,style=SMOOTHFONT)
		wf:wfont=New wfont
		wf.h=height
		wf.jiggle=jiggle
		wf.makesizes fname,style
		Return wf
	End Function
	
	Method makesizes(fname$,style)
		images=New timagefont[10]
		For x=1 To 10
			images[x-1]=LoadImageFont(fname,x*5,style)
		Next
	End Method
	
	Method setfont(size#)
		'i=Int((Log(size)/Log(wfontinc))-2)
		i=size/5-1
		If i>Len(images)-1 i=Len(images)-1
		If i<0 i=0
		SetImageFont images[i]
		scale#=size/((i+1)*5)
		'scale=1
		SetScale scale,scale
	End Method
	
	Method draw(txt$,x,y,size#)
		setfont size
		For line$=EachIn txt.split("~n")
			lh#=height(size)
			DrawText line,x,y-lh-jiggle*size
			y:+lh
		Next
		SetScale 1,1
	End Method
	
	Method height#(size#)
		Return h*size
	End Method
	
	Method width#(txt$,size#)
		setfont size
		w#=TextWidth(txt)*scale
		SetScale 1,1
		Return w
	End Method
	
	Method fittext$(txt$,size#,w#)
		line$=""
		out$=""
		For word$=EachIn txt.split(" ")
			ww#=width(word,size)
			If ww>w
				If line
					out:+line+"~n"
				EndIf
				out:+word+"~n"
				line=""
			ElseIf width(line,size)+ww>w
				out:+line+"~n"
				line=word+" "
			Else
				line:+word+" "
			EndIf
		Next
		out:+line
		Return out
	End Method
End Type


Rem
Graphics 600,600,0
SetBlend ALPHABLEND

For t$=EachIn LoadDir("fonts/")
	If Lower(t[Len(t)-3..])="ttf"
		testfont "fonts/"+t
	EndIf
Next
EndRem
