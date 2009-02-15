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
		DrawText txt,x,y-height(size)-jiggle*size
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
