'Include "grammar.bmx"
'Include "helpers.bmx"

Type thought
	Field x#,y#,ox#,oy#
	Field px#,py#
	Field cloud:thoughtcloud
	Field neighbours:TList
	Field av
	Field score[3]
	Field active#
	Field value#
	
	Field image:timage

	Method New()
		neighbours=New TList
		av=maxneighbours
	End Method

	Method position(r#)
		an#=Rnd(360)
		'v#=Rnd(.1,.2)
		v#=Rnd(0,1)
		ox=Cos(an)*r*v
		oy=Sin(an)*r*v
		x=ox
		y=oy
	End Method
	
	Function Create:thought(cx#,cy#,r#)
		t:thought=New thought
		t.position r
		Return t
	End Function
	
	Function availability(thoughts:TList)
		thoughts=thoughts.copy()
		While thoughts.count()
			l:TList=New TList
			av=thought(thoughts.first()).available(l)
			For t:thought=EachIn l
				t.av=av
				thoughts.remove t
			Next
		Wend
	End Function
	
	Function pick:thought(thoughts:TList,x#,y#,r#)
		r:*r
		closest:thought=Null
		mindist#=-1
		For t:thought=EachIn thoughts
			dx#=t.x-x
			dy#=t.y-y
			d#=dx*dx+dy*dy
			If d<r And (d<mindist Or mindist=-1)
				mindist=d
				closest=t
			EndIf
		Next
		Return closest
	End Function
			
	Method update()
		'verlet bit
		vx#=x-ox
		vy#=y-oy
		v#=vx*vx+vy*vy
		If v>9
			v=Sqr(v)
			vx:*3/v
			vy:*3/v
		EndIf
		ox=x
		oy=y
		x:+vx*.9
		y:+vy*.9
		
		x:+Rnd(-1,1)*.001
		y:+Rnd(-1,1)*.001
		
		'gravitate towards centre
		d#=Sqr(x*x+y*y)
		f#=cloud.gravity/(d*(neighbours.count()+1))
		x:-x*f
		y:-y*f
		
		repel
		
		If active>=1
			findneighbours
			active=1
		Else
			active:+Rnd(.01,.02)
		EndIf
		
	End Method
	
	Method repel()
		For t:thought=EachIn cloud.thoughts
			If t<>Self
				dx#=t.x-x
				dy#=t.y-y
				d#=dx*dx+dy*Dy
				f#=15*neighbours.count()/(d*maxneighbours)
				'If neighbours.count()=maxneighbours Or t.neighbours.count()=maxneighbours Or neighbours.contains(t)
				If d<linksize*linksize*4
					px:-dx*f
					py:-dy*f
				EndIf
			EndIf
		Next
	End Method
	
	Method available(chk:TList=Null)
		If Not chk
			chk=New TList
			chk.addlast Self
		Else If chk.contains(Self)
			Return 0
		EndIf
		chk.addlast Self
		av=maxneighbours-neighbours.count()
		For t:thought=EachIn neighbours
			av:+t.available(chk)
		Next
		Return av
	End Method
	
	Method linkedto(t:thought,l:TList=Null)
		If t=Self Return 1
		If Not l
			l=New TList
		EndIf
		If l.contains(Self) Return 0
		l.addlast Self
		For t2:thought=EachIn neighbours
			If t2.linkedto(t,l)
				Return 1
			EndIf
		Next
	End Method
	
	Method findneighbours()
		'DrawText av,x,y
		If neighbours.count()=maxneighbours Return
		For t:thought=EachIn cloud.thoughts
			If t<>Self And (Not neighbours.contains(t)) And t.neighbours.count()<maxneighbours And t.active>=1
				If ((Not linkedto(t)) And av+t.av>2) Or av>2
					dx#=t.x-x
					dy#=t.y-y
					d#=dx*dx+dy*dy
					If d<linksize*linksize
						neighbours.addlast t
						t.neighbours.addlast Self
						l:TList=New TList
						l.addlast Self
						thought.availability l
						If neighbours.count()=3 Return
					EndIf
				EndIf
			EndIf
		Next
	End Method
	
	Method countfriends:TList(l:TList=Null)
		If Not l l=New TList
		If l.contains(Self) Return l
		l.addlast Self
		For t:thought=EachIn neighbours
			If TTypeId.ForObject(Self)=TTypeId.ForObject(t)
				t.countfriends(l)
			EndIf
		Next
		Return l
	End Method
	
	Method constrain()
		px=0
		py=0
		For t:thought=EachIn neighbours
			dx#=t.x-x
			dy#=t.y-y
			d#=Sqr(dx*dx+dy*dy)
			If d>linksize
				f#=(d-linksize)/d
				px:+f*dx/2
				py:+f*dy/2
			EndIf
		Next
	End Method
			
	
	Method draw(bx#,by#)
			scale#=1/Sqr(gravity)
			If scale>.5 scale=.5
			SetScale scale,scale
			SetAlpha active
			DrawzoomImage image,x+bx,y+by
			SetAlpha 1
			SetScale 1,1
			'DrawText neighbours.count(),zoomx(x+bx),zoomy(y+by)
	End Method
	
	Method drawlinks(bx#,by#)
		For t:thought=EachIn neighbours
			DrawZoomLine x+bx,y+by,(x+t.x)/2+bx,(y+t.y)/2+by
		Next
	End Method
End Type

Type lovethought Extends thought

	Method New()
		Global img:timage=LoadImage("images/thoughts/love.png")
		image=img
		score=[0,0,1]
		value=1
	End Method

End Type

Type witthought Extends thought

	Method New()
		Global img:timage=LoadImage("images/thoughts/wit.png")
		image=img
		score=[0,1,0]
		value=1
	End Method

End Type

Type outragethought Extends thought

	Method New()
		Global img:timage=LoadImage("images/thoughts/outrage.png")
		image=img
		score=[1,0,0]
		value=1
	End Method

End Type

Type ragethought Extends thought

	Method New()
		Global img:timage=LoadImage("images/thoughts/rage.png")
		image=img
		score=[-1,0,0]
		value=-1
	End Method

End Type

Type dullthought Extends thought

	Method New()
		Global img:timage=LoadImage("images/thoughts/dull.png")
		image=img
		score=[0,-1,0]
		value=-1
	End Method

End Type

Type pleadthought Extends thought

	Method New()
		Global img:timage=LoadImage("images/thoughts/plead.png")
		image=img
		score=[0,0,-1]
		value=-1
	End Method

End Type

Type thoughtcloud
	Field cx#,cy#,maxr#,nmaxr#
	Field thoughts:TList
	Field gravity#
	
	Method New()
		thoughts=New TList
		gravity=1
	End Method
	
	Method addrandomthought()
		Local t:thought
		Select Rand(1,3)
		Case 1
			t=New lovethought
		Case 2
			t=New witthought
		Case 3
			t=New outragethought
		Case 4
			t=New ragethought
		Case 5
			t=New pleadthought
		Case 6
			t=New dullthought
		End Select
		addthought t
	End method
	
	
	Method addthought(t:thought)
		t.position maxr+100
		thoughts.addlast t
		t.cloud=Self
	End Method
	
	Method update()
		maxr#=0
		dx#=0
		dy#=0
		For t:thought=EachIn thoughts
			t.update
			d#=t.x*t.x+t.y*t.y
			dx:+t.x
			dy:+t.y
			If d>maxr
				maxr=d
			EndIf
		Next
		dx:/thoughts.count()
		dy:/thoughts.count()
		For t:thought=EachIn thoughts
		'	t.x:-dx*.1
		'	t.y:-dy*.1
		Next
		maxr=Sqr(maxr)
		If maxr>200
			gravity:+.01
		Else
			gravity:-.001
			If gravity<0.5 gravity=0.5
		EndIf
		maxr:+20
		nmaxr:+(maxr-nmaxr)*.1
		

		For c=1 To 9
			For t:thought=EachIn thoughts
				t.x:+t.px*.9
				t.y:+t.py*.9
				t.constrain
			Next
		Next

	End Method

	Method draw()
		SetBlend ALPHABLEND
		SetColor 0,0,255
		SetAlpha .1
		Drawzoomcircle cx,cy,nmaxr
		SetColor 255,255,255
		SetAlpha 1
		
		For t:thought=EachIn thoughts
			t.drawlinks cx,cy
		Next
		
		For t:thought=EachIn thoughts
			t.draw cx,cy
		Next
	End Method
End Type


Const linksize#=80
Const maxneighbours=3


rem
thoughts:TList=New TList
Graphics 600,600,0
		SetClsColor 248,236,194
SetBlend ALPHABLEND
SeedRnd MilliSecs()
AutoMidHandle True

cx#=300
cy#=300

Global gravity#=1

selection:TList=New TList
tc:thoughtcloud=New thoughtcloud
tc.cx=300
tc.cy=300

While 1
	'thought.availability thoughts

	
	If MouseDown(1)
		t:thought=thought.pick(tc.thoughts,MouseX(),MouseY(),linksize/4)
		If selection.contains(t) And t<>selection.last()
			selection.removelast
		ElseIf t And (Not selection.contains(t)) And selection.count()<3
			If selection.count()=0 Or thought(selection.last()).neighbours.contains(t)
				selection.addlast t
			EndIf
		EndIf
	ElseIf selection.count()
		For t:thought=EachIn selection
			tc.thoughts.remove t
			For t2:thought=EachIn t.neighbours
				t2.neighbours.remove t
			Next
		Next
		thought.availability tc.thoughts
		Local score[]=quip(selection)
		
		adds=0
		If score[0]>0
			tc.addthought New outragethought
			adds:+1
		ElseIf score[0]<0
			tc.addthought New ragethought
			adds:+1
		EndIf
		If score[1]>0
			tc.addthought New witthought
			adds:+1
		ElseIf score[1]<0
			tc.addthought New dullthought
			adds:+1
		EndIf
		If score[2]>0
			tc.addthought New lovethought
			adds:+1
		ElseIf score[2]<0
			tc.addthought New pleadthought
			adds:+1
		EndIf
		maxadds=poisson(2)
		If adds<maxadds
			For c=1 To maxadds-adds
			Next
		EndIf
		selection=New TList
	EndIf
	
	If KeyHit(KEY_SPACE)
		Select Rand(1,6)
		Case 1
			t=New lovethought
		Case 2
			t=New witthought
		Case 3
			t=New outragethought
		Case 4
			t=New ragethought
		Case 5
			t=New pleadthought
		Case 6
			t=New dullthought
		End Select
		tc.addthought t
	EndIf
	
	tc.update
	tc.draw


	

	

	Flip
	Cls
	If KeyHit(KEY_ESCAPE) Or AppTerminate()
		End
	EndIf
Wend
endrem