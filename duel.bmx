Framework brl.d3d7max2d
Import brl.max2d
Import brl.standardio

Type bone
	Field j1:joint
	Field j2:joint
	Field length#
	
	Function Create:bone(j1:joint,j2:joint,length#)
		b:bone=New bone
		b.j1=j1
		b.j2=j2
		j1.bones.addlast b
		j2.bones.addlast b
		b.length=length
		Return b
	End Function
	
	Method constrain() 
		dx:Float = j2.px - j1.px
		dy:Float = j2.py - j1.py
		d:Float = Sqr(dx * dx + dy * dy) 
		f:Float = (d - length) *.9
		If d = 0 d = 1
		dx:*f / d
		dy:*f / d
		If j1.fixed
			If j2.fixed
				Return
			Else
				j2.npx:-dx
				j2.npy:-dy
			EndIf
		Else
			If j2.fixed
				j1.npx:+dx
				j1.npy:+dy
			Else
				j1.npx:+dx / 2
				j1.npy:+dy / 2
				j2.npx:-dx / 2
				j2.npy:-dy / 2
			EndIf
		EndIf
	End Method
	
	Method otherjoint:joint(j:joint)
		If j=j1 Return j2
		If j=j2 Return j1
	End Method
	
	Method draw()
		SetLineWidth 3
		SetColor 255,255,255
		DrawLine j1.x,j1.y,j2.x,j2.y
		SetLineWidth 1
	End Method
End Type

Type joint
	Field weight#,strength#
	Field px#,py#
	Field x#,y#
	Field npx#,npy#
	Field vx#,vy#
	Field bones:TList
	Field fixed
	Field movex#,movey#,moves
	
	Method New()
		bones=New TList
	End Method

	Function Create:joint(x:Float, y:Float, weight#, strength#=1, fixed = 0) 
		j:joint = New joint
		j.x = x
		j.y = y
		j.weight=weight
		j.strength=strength
		Print x+", "+y
		j.fixed = fixed
		Return j
	End Function
	
	Method draw()
		If fixed
			SetColor 255,0,0
		Else
			SetColor 255,255,255
		EndIf
		DrawOval x-2,y-2,4,4
	End Method
	
	Method update()
		If fixed Return
		ox#=x
		oy#=y
		x=px
		y=py
		f#=1
		px=(1+f)*px-f*ox
		py=(1+f)*py-f*oy
		npx=0
		npy=0
		
		npy:+4
		
		movex=0
		movey=0
		moves=0
	End Method

	
	Method moveto(tx#,ty#,w#=1)
		movex:+(tx-px)*w
		movey:+(ty-py)*w
		moves:+1
	End Method
	
	Method makemove()
		If Not moves Return
		tx=movex/moves+px
		ty=movey/moves+py
		SetColor 0,0,255
		DrawLine px,py,tx,ty
		SetColor 255,255,255
		domove tx,ty
	End Method
	
	Method domove(tx#,ty#,checked:TList=Null)
		If fixed Return 1	'fixed joints allow movement of further-up joints
		
		If Not checked
			checked=New TList
		EndIf
		go=0
		For b:bone=EachIn bones
			If Not checked.contains(b)
				checked.addlast b
				j:joint=b.otherjoint(Self)
				dx#=tx-j.px
				dy#=ty-j.py
				d#=Sqr(dx*dx+dy*dy)
				'If d>=b.length
				'	ntx#=tx
				'	nty#=ty
				'Else
					ntx=tx-dx*b.length/d
					nty=ty-dy*b.length/d
				'EndIf
				'ntx=(ntx+tx)/2
				'nty=(nty+ty)/2
				If j.domove(ntx,nty,checked)
					swing(b,tx,ty)	'swing self around this joint towards target
					go:+1
				EndIf
			EndIf
		Next
		Return go
	End Method
	
	Method swing(b:bone,tx#,ty#,w#=1)
		j:joint=b.otherjoint(Self)
		dx1#=tx-j.px
		dy1#=ty-j.py
		d1#=Sqr(dx1*dx1+dy1*dy1)
		
		'If d1<b.length Return
		
		an1#=ATan2(dy1,dx1)
		dx2#=x-j.px
		dy2#=y-j.py
		an2#=ATan2(dy2,dx2)
		dan#=andiff(an1,an2)
		
		sv#=.5*w
		an=an2+dan*sv
		mx=j.px+Cos(an)*b.length
		my=j.py+Sin(an)*b.length
		reposition(mx,my)
	End Method
	
	Method reposition(tx#,ty#)
		DrawLine px,py,tx,ty
		px:+(tx-px)*strength
		py:+(ty-py)*strength
		npx:+(tx-px)
		npy:+(ty-py)
	End Method
End Type

Function andiff#(an1#,an2#)
	dan#=(an1-an2) Mod 360
	If dan<-180 dan:+360
	If dan>180 dan:-360
	Return dan
End Function

Type skeleton
	Field size#
	Field dir
	Field joints:TList, bones:TList
	Field lfoot:joint, lknee:joint, rfoot:joint, rknee:joint
	Field pelvis:joint, topspine:joint, lelbow:joint, relbow:joint, lhand:joint, rhand:joint
	Field mx#,my#,gx#,gy#
	
	Method New()
		joints=New TList
		bones=New TList
	End Method

	Function Create:skeleton(x:Float, y:Float, dir, size)
		s:skeleton = New skeleton
		s.size = size
		s.dir = dir
		s.makebones() 

		For j:joint = EachIn s.joints
			j.x:+x
			j.y:+y
			j.px=j.x
			j.py=j.y
		Next
		
		Return s
	End Function
	
	Method makebones() 
		footstrength#=.1
		kneestrength#=.6
		pelvisstrength#=.5
		spinestrength#=.3
		elbowstrength#=.2
		handstrength#=.6
		lfoot:joint = addjoint(-1, 0,1,footstrength, 1) 
		lknee:joint = addjoint(0, - 2,1,kneestrength) 
		rfoot:joint = addjoint(1, 0,1,footstrength, 1) 
		rknee:joint = addjoint(0, - 2,1,kneestrength) 
		pelvis:joint = addjoint(0, - 4,4,pelvisstrength) 
		topspine:joint = addjoint(0, - 7,4,spinestrength) 
		lelbow:joint = addjoint(2, topspine.y / size,1,elbowstrength) 
		lhand:joint = addjoint(4, topspine.y / size,7,handstrength) 
		relbow:joint = addjoint(- 2, topspine.y / size,1,elbowstrength) 
		rhand:joint = addjoint(- 4, topspine.y / size,3,handstrength)
		
		llowleg:bone = addbone(lknee, lfoot, 2) 
		lupleg:bone = addbone(pelvis, lknee, 2) 
		rlowleg:bone = addbone(rknee, rfoot, 2) 
		rupleg:bone = addbone(pelvis, rknee, 2) 
		spine:bone = addbone(pelvis, topspine, 3) 
		luparm:bone = addbone(topspine, lelbow, 2) 
		lforearm:bone = addbone(lelbow, lhand, 2) 
		ruparm:bone = addbone(topspine, relbow, 2) 
		rforearm:bone = addbone(relbow, rhand, 2) 
	End Method

	Method addjoint:joint(bx:Float, by:Float, weight#, strength#=1,fixed = 0) 
		j:joint = joint.Create(bx * size * dir, by * size, weight,strength, fixed) 
		joints.AddLast j
		Return j
	End Method	

	Method addbone:bone(j1:joint, j2:joint, length:Float) 
		b:bone = bone.Create(j1, j2, length * size) 
		bones.AddLast b
		Return b
	End Method
	
	Method update()
		If lfoot.fixed Or rfoot.fixed
			For j:joint=EachIn joints
				j.makemove
			Next
		EndIf
		For j:joint=EachIn joints
			j.update
		Next
		
		balance
		
		walk
		
		For c=1 To 5
			For j:joint=EachIn joints
				If Not j.fixed
					j.px:+j.npx
					j.py:+j.npy
					j.npx=0
					j.npy=0
				EndIf
			Next
			For b:bone=EachIn bones
				b.constrain
			Next
		Next
	End Method
	
	Method balance()
		'find centre of gravity
		gx#=0
		gy#=0
		tweight#=0
		For j:joint=EachIn joints
			gx:+j.px*j.weight
			gy:+j.py*j.weight
			tweight#:+j.weight
		Next

		gx:/tweight
		gy:/tweight
		
		DrawOval gx-3,gy-3,6,6
		
		'find middle of stance
		n=0
		mx#=0
		If lfoot.fixed
			mx:+lfoot.px
			n:+1
		EndIf
		If rfoot.fixed
			mx:+rfoot.px
			n:+1
		EndIf
		If n
			mx#:/n
		EndIf
		my#=(topspine.py+pelvis.py)/2
		
		maxmy#=(lfoot.py+rfoot.py)/2-size*6
		If my>maxmy
			my=maxmy
		EndIf
		
		DrawOval mx,500,3,3
		
		dx#=(gx-mx)*.02
		For j:joint=EachIn joints
			If Not j.fixed
				j.px:+dx
			EndIf
		Next
		
		'move hands
		dx#=(mx-gx)*.9
		lhand.moveto lhand.px+dx,my
		rhand.moveto rhand.px+dx,my
		pelvis.moveto pelvis.px+dx,gy,1
		pelvis.moveto mx,gy,.3
		topspine.moveto pelvis.px,pelvis.py-size*3
		
		lknee.moveto lfoot.px,lfoot.py-size*2,1
		rknee.moveto rfoot.px,rfoot.py-size*2,1
		
		
	End Method
	
	Method walk()
		If lfoot.fixed
			If rfoot.fixed
				mode=0	'standing steady, consider a step
			Else
				mode=1	'walking
				pivot:joint=lfoot
				free:joint=rfoot
			EndIf
		Else
			If rfoot.fixed
				mode=1
				pivot:joint=rfoot
				free:joint=lfoot
			Else
				'falling!
			EndIf
		EndIf
		
		Select mode
		Case 0
			If MouseDown(1)
				If lfoot.px<rfoot.px
					leftest:joint=lfoot
					rightest:joint=rfoot
				Else
					leftest:joint=rfoot
					rightest:joint=lfoot
				EndIf
				
				dx#=gx-mx
				If Abs(dx)>size
					If dx<0	'weight on left
						rightest.fixed=0
						rightest.py:-5
					ElseIf dx>0	'weight on right
						leftest.fixed=0
						leftest.py:-5
					EndIf
				EndIf
			endif
		Case 1
			dx#=lhand.px-pivot.px
			tx#=pivot.px+Sgn(dx)*size*4
			ty#=(pelvis.py+pivot.py)/2
			ty#=pelvis.py
			DrawRect tx-size*.4,ty,size*.8,3
			If Abs(free.px-tx)>size
				f#=(pivot.py-free.py)/(pivot.py-pelvis.py)+.3
				If f>1 f=1
				free.moveto tx,ty,.1
				free.py:-2
				pelvis.py:-2
			Else
				free.px:+Sgn(dx)*1
				If free.py>500
					free.py=500
					free.y=500
					free.fixed=1
				EndIf
			EndIf
		End Select
	End Method
	
	Method draw()
		For b:bone=EachIn bones
			b.draw
		Next
		For j:joint=EachIn joints
			j.draw
		Next
	End Method

End Type


Graphics 600,600,0
SetBlend ALPHABLEND

s:skeleton=skeleton.Create(300,500,1,20)
acc#=0
While 1
	
	s.update
	
	If KeyDown(KEY_A)
		s.pelvis.px:-50
		s.topspine.px:-20
	EndIf
	If KeyDown(KEY_D)
		s.pelvis.px:+50
		s.topspine.px:+20
	EndIf
	If KeyDown(KEY_W)
		s.pelvis.py:-20
		s.topspine.py:-10
	EndIf	
	If KeyDown(KEY_S)
		s.pelvis.py:+20
		s.topspine.py:+10
	EndIf	
		s.lhand.moveto MouseX(),MouseY()
	
	s.draw
	
	DrawText "left click to walk!",0,0
	

	Flip
	Cls
	If KeyHit(KEY_ESCAPE) Or AppTerminate()
		End
	EndIf
Wend