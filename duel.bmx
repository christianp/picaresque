'Framework brl.d3d7max2d
'Import brl.max2d
'Import brl.standardio
'Import brl.random


Type bone
	Field j1:joint
	Field j2:joint
	Field length#
	Field an#
	Field topan#,toplength#
	Field botan#,botlength#
	
	Function Create:bone(j1:joint,j2:joint,length#,topan#,toplength#,botan#,botlength#)
		b:bone=New bone
		b.j1=j1
		b.j2=j2
		j1.bones.addlast b
		j2.bones.addlast b
		b.length=length
		
		b.topan=topan
		b.toplength=toplength
		b.botan=botan
		b.botlength=botlength
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
	
	Method update()
		dx#=j2.x-j1.x
		dy#=j2.y-j1.y
		an#=ATan2(dy,dx)
	End Method
	
	Method draw()
		'SetLineWidth 3
		'SetColor 255,255,255
		'DrawLine j1.x,j1.y,j2.x,j2.y
		'SetLineWidth 1
		
		
		Local poly#[]
		
		topx1#=j1.x+Cos(an+topan)*toplength
		topy1#=j1.y+Sin(an+topan)*toplength
		topx2#=j1.x+Cos(an-topan)*toplength
		topy2#=j1.y+Sin(an-topan)*toplength
		botx1#=j2.x+Cos(an-botan+180)*botlength
		boty1#=j2.y+Sin(an-botan+180)*botlength
		botx2#=j2.x+Cos(an+botan+180)*botlength
		boty2#=j2.y+Sin(an+botan+180)*botlength
		
		poly=[topx1,topy1,j1.x,j1.y,topx2,topy2,botx2,boty2,j2.x,j2.y,botx1,boty1]
		DrawtexturedPoly paper, panuv(poly)
		
	End Method
End Type

Function DrawPolyOutline(poly#[])
	For i=0 To Len(poly)-2 Step 2
		DrawRect poly[i],poly[i+1],2,2
	Next
End Function

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
		'DrawOval x-2,y-2,4,4
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
		
		If py>groundheight(px)
			py=groundheight(px)
			y=py
		EndIf
		
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
		'SetColor 0,0,255
		'DrawLine px,py,tx,ty
		'SetColor 255,255,255
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
		maxdan=30+15*strength
		If Abs(dan)>maxdan
			maxdan=30*Sgn(dan)
		EndIf
		
		sv#=.5*w
		an=an2+dan*sv
		mx=j.px+Cos(an)*b.length
		my=j.py+Sin(an)*b.length
		reposition(mx,my)
	End Method
	
	Method reposition(tx#,ty#)
		'DrawLine px,py,tx,ty
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
	Field aimx#,aimy#
	Field size#
	Field dir
	Field joints:TList, bones:TList
	Field lfoot:joint, lknee:joint, rfoot:joint, rknee:joint
	Field head:joint
	Field pelvis:joint, topspine:joint, lelbow:joint, relbow:joint, lhand:joint, rhand:joint
	Field neck:bone
	Field lforearm:bone
	Field swordtip:joint, sword:bone
	Field mx#,my#,gx#,gy#
	Field stumble#
	Field laststep
	Field walking
	
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
		headstrength#=.5
		swordstrength#=.4
		lfoot:joint = addjoint(-1, 0,1,footstrength, 1) 
		lknee:joint = addjoint(0, - 2,1,kneestrength) 
		rfoot:joint = addjoint(1, 0,1,footstrength, 1) 
		rknee:joint = addjoint(0, - 2,1,kneestrength) 
		pelvis:joint = addjoint(0, - 4,4,pelvisstrength) 
		topspine:joint = addjoint(0, - 7,4,spinestrength) 
		lelbow:joint = addjoint(2, topspine.y / size,1,elbowstrength) 
		lhand:joint = addjoint(4, topspine.y / size,6,handstrength) 
		relbow:joint = addjoint(- 2, topspine.y / size,1,elbowstrength) 
		rhand:joint = addjoint(- 4, topspine.y / size,3,handstrength)
		head:joint = addjoint(0,-8,1, headstrength)
		swordtip:joint = addjoint(7,lhand.y/size,1, swordstrength)
		
		llowleg:bone = addbone(lknee, lfoot, 2, 30, .1, 60, .3) 
		lupleg:bone = addbone(pelvis, lknee, 2, 60, .7, 30, .1) 
		rlowleg:bone = addbone(rknee, rfoot, 2, 30, .1, 60, .3) 
		rupleg:bone = addbone(pelvis, rknee, 2, 60, .7, 45, .1) 
		spine:bone = addbone(pelvis, topspine, 3, 80, .3, 60, 1) 
		luparm:bone = addbone(topspine, lelbow, 2, 40, .7, 30, .1) 
		lforearm:bone = addbone(lelbow, lhand, 2, 40, .25, 30, .1) 
		ruparm:bone = addbone(topspine, relbow, 2, 40, .7, 30, .1) 
		rforearm:bone = addbone(relbow, rhand, 2, 40, .25, 30, .1) 
		neck:bone = addbone(topspine, head,1, 80,.2,80,.5)
		sword:bone=addbone(lhand,swordtip,3,30,.1,30,.1)
	End Method

	Method addjoint:joint(bx:Float, by:Float, weight#, strength#=1,fixed = 0) 
		j:joint = joint.Create(bx * size * dir, by * size, weight,strength, fixed) 
		joints.AddLast j
		Return j
	End Method	

	Method addbone:bone(j1:joint, j2:joint, length:Float, topan#=0, toplength#=0, botan#=0, botlength#=0) 
		b:bone = bone.Create(j1, j2, length * size, topan, toplength*size, botan, botlength*size) 
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
		
		walking=0
		
		look
		
		If Not stumble
			lhand.moveto aimx,aimy
		Else
			lhand.moveto gx+stumble*.2,gy-150
		EndIf
		
		swingsword()
		
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
		
		For b:bone=EachIn bones
			b.update
		Next

		aimx=lhand.px
		aimy=lhand.py
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
		
		'DrawOval gx-3,gy-3,6,6
		
		
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
		
		'DrawOval mx,500,3,3
		
		dx#=(gx-mx)*.02
		For j:joint=EachIn joints
			If Not j.fixed
				j.px:+dx
			EndIf
		Next
		
		'move bits
		dx#=(mx-gx)*.9
		lhand.moveto lhand.px+dx,my
		rhand.moveto rhand.px+dx,my
		pelvis.moveto pelvis.px+dx,gy,1
		pelvis.moveto mx,gy,.3
		topspine.moveto pelvis.px,pelvis.py-size*3
		
		lknee.moveto lfoot.px,lfoot.py-size*2,.5
		rknee.moveto rfoot.px,rfoot.py-size*2,.5
		
		
		'stumbling
		gx:+stumble
		stumble:*.98
		If Abs(stumble)<.5 stumble=0
		If stumble
			an#=stumble*.1
			rhand.moveto topspine.px+Cos(an)*size*2,topspine.py+Sin(an)*size*2,4
		EndIf
		pelvis.py:-stumble*5
		
		For j:joint=EachIn joints
			If Not j.fixed
				j.px:+stumble
			EndIf
		Next
		
	End Method
	
	Method walk()
	
		If stumble
			walking=1
		EndIf

		If lfoot.px<rfoot.px
			leftest:joint=lfoot
			leftknee:joint=lknee
			rightest:joint=rfoot
			rightknee:joint=lknee
		Else
			leftest:joint=rfoot
			leftknee:joint=rknee
			rightest:joint=lfoot
			rightknee:joint=rknee
		EndIf
		
		If lfoot.fixed
			If rfoot.fixed
				mode=0	'standing steady, consider a step
			Else
				mode=1	'walking
				pivot:joint=lfoot
				free:joint=rfoot
				freeknee:joint=rknee
			EndIf
		Else
			If rfoot.fixed
				mode=1
				pivot:joint=rfoot
				free:joint=lfoot
				freeknee:joint=lknee
			Else
				'falling!
			EndIf
		EndIf
		

		Select mode
		Case 0
			laststep:-1
			If laststep>0 Return
			If gx<leftest.px-size*1.5
				rightest.fixed=0
			ElseIf gx>rightest.px+size*1.5
				leftest.fixed=0
			EndIf
		
			If walking
				
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
			EndIf
		Case 1
			dx#=lhand.px-pivot.px
			tx#=pivot.px+Sgn(dx)*size*4
			ty#=(pelvis.py+pivot.py)/2
			ty#=pelvis.py
			'DrawRect tx-size*.4,ty,size*.8,3
			'DrawText (free.px-tx)*Sgn(tx-gx),0,15
			If (free.px-tx)*Sgn(tx-gx)<-size
				f#=(pivot.py-free.py)/(pivot.py-pelvis.py)+.3
				If f>1 f=1
				free.moveto tx,ty,.1
				If free.py>pelvis.py+size
					free.py:-2
				EndIf
				'freeknee.py:-
				'pelvis.py:-4*size/(free.py-pelvis.py)
				'pelvis.py:-4
				'pelvis.moveto pelvis.px,free.py-size*4
			Else
				pelvis.py:+1
				free.px:-Sgn(dx)*1
				free.py:+2
				gh#=groundheight(free.px)
				If free.py>=gh
					free.x=free.px
					free.py=gh
					free.y=gh
					free.fixed=1
					laststep=10
				EndIf
			EndIf
		End Select
	End Method
	
	Method look()
		an#=ATan2(lhand.py-topspine.py,lhand.px-topspine.px)-90
		If an<-180 an:+360
		If an>0 an:-180
		head.swing neck, topspine.px+Cos(an)*size,topspine.py+Sin(an)*size,1
		head.swing neck, topspine.px,topspine.py-size,.5
	End Method
	
	Method swingsword()
		an#=lforearm.an+10*Sgn(lhand.x-gx)
		tx#=lhand.x+Cos(an)*3*size
		ty#=lhand.y+Sin(an)*3*size
		swordtip.swing sword,tx,ty,.6
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

Function groundheight#(x#)
'	If x<gfxwidth/3
		Return gfxheight-50
'	Else
'		x:-gfxwidth/3
'		Return gfxheight-5*(x*x/8000)-50
'	EndIf
End Function

Global paper:timage
Type fight Extends gamemode
	Field s:skeleton
	
	Method New()
		paper=LoadImage("inspiration/fencing/bluepaper.jpg")
		s:skeleton=skeleton.Create(300,groundheight(300),1,20)
	End Method
	
	Method update()
		s.update
		
		If MouseHit(1)
			s.walking=1
		EndIf
		
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
		s.aimx=MouseX()
		s.aimy=MouseY()
		
		If KeyHit(KEY_SPACE)
			status=1
		EndIf
		
	End Method
	
	Method win()
		status=1
	End Method
	Method lose()
		status=2
	End Method
	
	Method draw()
		For x=0 To 959 Step 1
			DrawRect x,groundheight(x),1,1
		Next
		
		s.draw
		
		DrawText "left click to walk!",0,0
		DrawText "SPACE to finish",0,15
		
	
	End Method
End Type