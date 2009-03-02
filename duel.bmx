'Framework brl.d3d7max2d
'Import brl.max2d
'Import brl.standardio
'Import brl.random
'Include "texpoly.bmx"

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
		
		DrawzoomtexturedPoly paper, panuv(poly)
		
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

Const stance_block=1, stance_walk=2, stance_upswing=3, stance_downswing=4

Type skeleton
	Field aimx#,aimy#,naimx#,naimy#
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
	Field stance,ostance
	Field swingacc#,swordan#,nswordan#,vswordan#
	Field opponent:skeleton
	Field hit,hits
	Field walking
	Field aggression#,defence#,love#
	Field nextmove,thinktick
	
	
	Field cloud:thoughtcloud
	Field selection:TList
	
	
	Method New()
		joints=New TList
		bones=New TList
		aggression=0
		defence=0
		love=0
		cloud=New thoughtcloud
		For c=1 To 3
			cloud.addrandomthought
		Next
		selection=New TList
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
		
		s.cloud.cx=s.head.x-dir*50
		s.cloud.cy=s.head.y-100
		
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
		swordtip:joint = addjoint(8,lhand.y/size,0.01, swordstrength)
		
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
		sword:bone=addbone(lhand,swordtip,4,30,.1,30,.1)
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
	
	Method control()
		stance=0
		ostance=0
		If KeyDown(KEY_W)
			stance=stance_upswing
			ostance=stance_upswing
		EndIf
		If KeyDown(KEY_S)
			stance=stance_downswing
			ostance=stance_downswing
		EndIf
		If KeyDown(KEY_A)
			stance=stance_block
		EndIf
		If KeyDown(KEY_D)
			stance=stance_walk
		EndIf
	End Method
	
	Method ai()
		'If Rand(5)=1 And opponent.ostance And opponent.stance=stance_walk
		'	parry
		'	Return
		'EndIf
		If opponent.ostance And opponent.stance=stance_walk And defence>1 And defence>=opponent.defence
			If stance<>stance_block
				defence:-1
			EndIf
			If defence>0
				parry
			EndIf
			Return
		EndIf
		
		thinktick:+1
		If thinktick>nextmove+Rand(3)
			thinktick=0
			If Abs(opponent.mx-mx)>size*10
				If (mx-gfxwidth/2)*dir<0 And Rand(10)>1	'move toward opponent
					advance
				Else
					relax
				EndIf
				Return
			EndIf
			'DrawLine gx,0,gx,gy
			If opponent.stumble And Rand(10)>3
				relax
				Return
			EndIf
			
			If opponent.stance=stance_walk
				'If Rnd(0,defence)<=1
				If defence<1 Or Rand(30)<=1
					relax
				Else
					parry
					defence:-1
				EndIf
			Else
				'If Rnd(0,aggression)<=1 Or opponent.stance=stance_block
				If aggression<1 Or aggression<opponent.aggression Or Rnd(0,aggression)<1
					relax
				Else
					If stance<>stance_walk
						aggression:-1
					EndIf
					thrust
				EndIf
				
			EndIf
		EndIf
	End Method
	
	Method thrust()
					stance=stance_walk
					Select Rand(1,2)
					Case 1
						ostance=stance_upswing
					Case 2
						ostance=stance_downswing
					End Select
					nextmove=10
					Return
	End Method
	
	Method parry()
				stance=stance_block
				ostance=opponent.ostance
				nextmove=Rnd(50,100)/Sqr(aggression)
				Return
	End Method
	
	Method advance()
				stance=stance_walk
				ostance=0
				nextmove=10
				Return
	End Method
	
	Method relax()
					stance=0
					nextmove=Rnd(1,2)*50/aggression
					Return
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
		
		pose
		
		walk
		
		look
		
		swingsword()
		
		fence
		
		thinkcloud

		For c=1 To 10
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
		If Abs(stumble)<1.5 stumble=0
		If stumble
			'DrawLine 0,0,gx,gy
			an#=Abs(stumble)*.1
			rhand.moveto topspine.px+Cos(an)*size*2*Sgn(stumble),topspine.py+Sin(an)*size*2,4
		EndIf
		pelvis.py:+Abs(stumble)*5
		
		For j:joint=EachIn joints
			If Not j.fixed
				j.px:+stumble*size/30
			EndIf
		Next
		
	End Method
	
	Method pose()
		If stance=stance_walk
			swingacc:+2
		Else
			swingacc=0
		EndIf
		
		If stumble
			swordan=90*(1-dir)
			Return
		EndIf

		Select stance
		Case stance_block
			pelvis.px:-30*dir
			pelvis.py:-15
			topspine.px:-20*dir
			topspine.py:-5
			'walking=1
			aimx=pelvis.px+size*8*dir
			aimy=groundheight(mx)-size
			Select ostance
			Case stance_downswing
				swordan=90
				aimy:-size*3
			Case stance_upswing
				swordan=-90
				aimy:+size*3
			Default
			'	rhand.px:-3
			'	aimx:-size*18
			'	aimy:-size*3
			'	swordan=180
				swordan=0
			End Select
		Case stance_walk
			Select ostance
			Case stance_upswing
				aimx=topspine.px+size*swingacc*dir
				aimy=groundheight(mx)-size*10+acc/100
				swordan=0
				lhand.py:-10
			Case stance_downswing
				aimx=pelvis.px+size*swingacc*dir
				aimy=groundheight(mx)+acc/100
				swordan=-10
				lhand.py:+10
			Default
				aimx=mx+size*Rnd(20,30)*dir
				aimy=gy
				If Abs(mx-opponent.mx)>size*10
					walking=1
				EndIf
				swordan=-90+Rand(0,20)
				'swordan=Rand(-30,30)
			End Select
		Case stance_upswing
			aimx=mx+size*2*dir
			aimy=groundheight(mx)-size*10
			swordan=-10
		Case stance_downswing
			aimx=mx+size*2*dir
			aimy=groundheight(mx)
			swordan=-10
		Default
			aimx=gx+size*2*dir
			If Not (lfoot.fixed And rfoot.fixed)
				aimx:+size*8*dir
			EndIf
			aimy=groundheight(mx)-size*4
			pelvis.py:-10
			topspine.py:-10
			swordan=30
		End Select
		
		'If Self=fight(game.curmode).s2
		'	aimx=MouseX()
		'	aimy=MouseY()
		'	walking=1
		'EndIf
	End Method
	
	
	Method walk()
	
		If stumble
			walking=1
		EndIf

		If lfoot.px<rfoot.px
			leftest:joint=lfoot
			rightest:joint=rfoot
		Else
			leftest:joint=rfoot
			rightest:joint=lfoot
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
			
			If gx<leftest.px-size*1.5		'falling over
			'	rightest.fixed=0
			ElseIf gx>rightest.px+size*1.5
			'	leftest.fixed=0
			EndIf
		
			If walking
				
				dx#=gx-mx
				If Abs(dx)>size
					If dx<0	'weight on left
						rightest.fixed=0
						rightest.py:-10
					ElseIf dx>0	'weight on right
						leftest.fixed=0
						leftest.py:-10
					EndIf
					laststep=10
				EndIf
			EndIf
		Case 1
			laststep:-1
			dx#=gx-pivot.px
			tx#=pivot.px+Sgn(dx)*size*4
			ty#=pelvis.y
			'DrawRect tx-size*.4,ty,size*.8,3
			'DrawText (free.px-tx)*Sgn(tx-gx),0,15
			If (free.px-tx)*Sgn(tx-gx)<-size
				'f#=(pivot.py-free.py)/(pivot.py-pelvis.py)+.3
				'If f>1 f=1
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
				
				diff#=(groundheight(free.px)-free.py)
				For j:joint=EachIn joints
					j.py:+diff/10
				Next
				
				If free.py>=gh And laststep<=0
					free.x=free.px
					free.py=gh
					free.y=gh
					free.fixed=1
					laststep=10
				EndIf
			EndIf
		End Select

		walking=0
		
	End Method
	
	Method look()
		'head.
		an#=ATan2(opponent.lhand.py-topspine.py,opponent.lhand.px-topspine.px)-90
		If an<-180 an:+360
		If an>0 an:-180
		'head.swing neck, topspine.px+Cos(an)*size,topspine.py+Sin(an)*size,1
		'head.swing neck, topspine.px,topspine.py-size,.5
		head.moveto topspine.px+Cos(an)*size,topspine.py+Sin(an)*size,1
		head.moveto topspine.px,topspine.py-size,.5
	End Method
	
	Method swingsword()
		naimx:+(aimx-naimx)*.2
		naimy:+(aimy-naimy)*.2

		wobblean#=MilliSecs()*.7
		wobble#=size*Rnd(.1,.2)
		'naimx:+Cos(wobblean)*wobble
		naimy:+Sin(wobblean)*wobble
		
		If Not stumble
			lhand.moveto naimx,naimy
		Else
			lhand.moveto gx+stumble*.2,gy-150
		EndIf
		
		dan#=andiff(swordan,nswordan)
		vswordan:+dan*.2
		vswordan:-vswordan*Abs(vswordan)*.02
		nswordan:+vswordan
		If dir=1
			san#=nswordan
		Else
			san=180-nswordan
		EndIf
		an#=lforearm.an+10*Sgn(lhand.x-gx)
		tx#=lhand.x+Cos(san)*3*size
		ty#=lhand.y+Sin(san)*3*size
		swordtip.swing sword,tx,ty,.6
		
	End Method
	
	Method thinkcloud()
		tx=mx-dir*cloud.nmaxr
		ty=head.y-cloud.nmaxr-size
		cloud.cx:+(tx-cloud.cx)*.002
		cloud.cy:+(ty-cloud.cy)*.002
		cloud.update
		If Rand(50*Sqr(cloud.thoughts.count()))=1
			cloud.addrandomthought
		EndIf
		
		If love>0
			'aggression:+love*.001
			'defence:+love*.001
			'love:*.999
		EndIf
		
		'If aggression<2 aggression=2
		'If defence<2 defence=2
	End Method
	
	Method mouseselection()
		t:thought=thought.pick(cloud.thoughts,unzoomx(MouseX()-cloud.cx),unzoomy(MouseY()-cloud.cy),linksize/4)
		If MouseDown(1)
			If selection.contains(t) And t<>selection.last()
				selection.removelast
			ElseIf t And (Not selection.contains(t))
				If selection.count()=0
					selection.addlast t
				Else
					t1:thought=thought(selection.first())
					t2:thought=thought(selection.last())
					If t2.neighbours.contains(t) And (selection.count()=1 Or (TTypeId.ForObject(t1)=TTypeId.ForObject(t) And TTypeId.ForObject(t2)=TTypeId.ForObject(t)))
						selection.addlast t
					EndIf
				EndIf
			EndIf
		Else
			Select selection.count()
			Case 0
			Case 1
				If t 
					quip
				Else
					selection=New TList
				EndIf
			Case 2
				If TTypeId.ForObject(selection.first())=TTypeId.ForObject(selection.last())
					quip
				Else
					swapthoughts
				EndIf
			Default
				quip
			End Select
		EndIf
	End Method
	
	Method aiselection()
		If Rand(100)>1 Return
		If cloud.thoughts.count()=0 Return
		
		l:TList=cloud.thoughts.copy()
		While l.count()
			l2:TList=thought(l.first()).countfriends()
			If l2.count()>=3 Or Rand(20)=1
				selection=l2
				quip
				Return
			Else
				For t:thought=EachIn l2
					l.remove t
				Next
			EndIf
		Wend
		
		'if you get here no chains to make, swap two random things
		t:thought=thought(picklist(cloud.thoughts))
		If Not t.neighbours.count() Return
		
		l.addlast t
		l.addlast picklist(t.neighbours)
		selection=l
		swapthoughts
	
	
		Return
		Function thoughtsort(o1:Object,o2:Object)
			t1:thought=thought(o1)
			t2:thought=thought(o2)
			If t1.value<t2.value Return 1 Else Return -1
		End Function
		
		Function sqrrand!(min_value!=1,max_value!=0)
			u#=Rand(min_value,max_value)
			Return u*u
		End Function
	
	
		If selection.count()=2 And Rand(1500/(selection.count()*cloud.thoughts.count()))=1
			quip
		EndIf
		If selection.count() 
			If selection.count()<2
				l:TList=New TList
				For t:thought=EachIn thought(selection.last()).neighbours
					If Not selection.contains(t)
						l.addlast t
					EndIf
				Next
				If l.count()
					l.sort 1,thoughtsort
					selection.addlast picklist(l,sqrrand)
				Else
					selection.removelast
				EndIf
			EndIf
		ElseIf cloud.thoughts.count()
			selection.addlast picklist(cloud.thoughts,sqrrand)
		EndIf
	End Method
	
	Method swapthoughts()
		t1:thought=thought(selection.first())
		t2:thought=thought(selection.last())
		px#=t1.x
		py#=t1.y
		pox#=t1.ox
		poy#=t1.oy
		t1.x=t2.x
		t1.y=t2.y
		t1.ox=t2.ox
		t1.oy=t2.oy
		t2.x=px
		t2.y=py
		t2.ox=pox
		t2.oy=poy
		selection=New TList
		For t3:thought=EachIn t1.neighbours
			t3.neighbours.remove t1
		Next
		For t3:thought=EachIn t2.neighbours
			t3.neighbours.remove t2
		Next
		t1.neighbours.remove t2
		t2.neighbours.remove t1
		pneighbours:TList=t1.neighbours
		t1.neighbours=t2.neighbours
		t2.neighbours=pneighbours
		For t3:thought=EachIn t1.neighbours
			If Not t3.neighbours.contains(t1)
				t3.neighbours.addlast t1
			EndIf
		Next
		For t3:thought=EachIn t2.neighbours
			If Not t3.neighbours.contains(t2)
				t3.neighbours.addlast t2
			EndIf
		Next
		t1.neighbours.addlast t2
		t2.neighbours.addlast t1
		
		Rem
		l1:TList=t1.countfriends()
		If l1.count()>=3
			Print l1.count()
			For t:thought=EachIn l1
				cloud.thoughts.remove t
				For t2:thought=EachIn t.neighbours
					t2.neighbours.remove t
				Next
			Next
		EndIf
		l2:TList=t2.countfriends()
		'Print score1
		'Print score2
	
		Return
		EndRem
	End Method
		
	Method quip()
		
		
		If fight(game.curmode).sp Return

			For t:thought=EachIn selection
				cloud.thoughts.remove t
				For t2:thought=EachIn t.neighbours
					t2.neighbours.remove t
				Next
			Next
			thought.availability cloud.thoughts
			Local score[3]

			For t:thought=EachIn selection
				For i=0 To 2
					score[i]:+t.score[i]
				Next
			Next
			For i=0 To 2
				tot:+Abs(score[i])
			Next
			'If tot<>0
			'	For i=0 To 2
			'		score[i]:/Abs(tot)
			'	Next
			'EndIf
			Print "["+score[0]+","+score[1]+","+score[2]+"] "+tot

			benefitquip score
					
			Global g:grammar=grammar.fromfile("grammars/insults.txt")
			l:TList=New TList
			minerr=-1
			For name$=EachIn g.symbols.keys()
				If name[0]=Asc("$")	'if this is a beginning insult
					Local keyscore[]
					keyscore=scorekey(name)
					err#=0
					For i=0 To 2
						err:+Abs(keyscore[i]-score[i])
					Next
					If err<minerr Or minerr=-1
						l=New TList
						l.addlast name
						minerr=err
					ElseIf err=minerr
						l.addlast name
					EndIf
				EndIf
			Next
			key$=String(picklist(l))
			Print "picked "+key
			txt$=g.fill(key)
			fight(game.curmode).insult Self,txt
			Print "I say: "+txt
			
			Rem
			score=scorekey(key)

			adds=0
			If score[0]>0
				'cloud.addthought New outragethought
				'opponent.cloud.addthought New ragethought
				'adds:+1
			ElseIf score[0]<0
				'cloud.addthought New ragethought
				'opponent.cloud.addthought New outragethought
				'adds:+1
			EndIf
			If score[1]>0
				'cloud.addthought New witthought
				'opponent.cloud.addthought New dullthought
				'adds:+1
			ElseIf score[1]<0
				'cloud.addthought New dullthought
				'opponent.cloud.addthought New witthought
				'adds:+1
			EndIf
			If score[2]>0
				'cloud.addthought New lovethought
				'opponent.cloud.addthought New pleadthought
				'adds:+1
			ElseIf score[2]<0
				'cloud.addthought New pleadthought
				'opponent.cloud.addthought New lovethought
				'adds:+1
			EndIf
			maxadds=poisson(2.5)
			If maxadds<1 maxadds=1
			If adds<maxadds
				For c=1 To maxadds-adds
					'cloud.addrandomthought
				Next
			EndIf
			
			EndRem
			
			selection=New TList
			
			

	End Method
	
	Method benefitquip(score[])
		Local res#[3]
		For i=0 To 2
			res[i]=Int(score[i]^1.5)
			Print score[i]+">>"+res[i]
		Next
		
		aggression:+res[0]
		defence:+res[1]
		love:+res[1]
	End Method
		
	
	Method fence()
		If opponent.stance=stance_block And opponent.ostance=ostance And opponent.ostance	'opponent can block
			opponent.hit=0
			If (swordtip.px-opponent.lhand.px)*dir>0	'if swords cross
				swordtip.px=opponent.lhand.px
				swordtip.px=swordtip.x
				swordtip.py=swordtip.y
				'stumble:-1.6*dir
				'swordtip.px:-dir*size*2
				'lhand.px:-dir*size*2
			EndIf
			Return
		EndIf
		
		If (swordtip.px-opponent.gx)*dir>0 And stance=stance_walk And ostance	'if sword inside opponent
			If Not opponent.hit
				opponent.stumble:+dir*8
				opponent.hit=1
				opponent.hits:+1
				
				If opponent.hits>=20
					fight(game.curmode).victory Self
				EndIf
				
				love:+1
				opponent.love:-1
				'opponent.defence:-1
				'opponent.aggression:*.8
			EndIf
		Else
			opponent.hit=0
		EndIf
			
	End Method
		
	Method draw()
		Local r
		For b:bone=EachIn bones
			r=(r+50) Mod 256
			SetColor r,255,255-r
			b.draw
		Next
		For j:joint=EachIn joints
			j.draw
		Next
		
		cloud.draw
		For t:thought=EachIn selection
			SetAlpha .4
			Drawzoomcircle t.x+cloud.cx,t.y+cloud.cy,20
			SetAlpha 1
		Next		
		
		SetColor 0,0,0
		DrawText Int(aggression)+","+Int(defence)+","+Int(love)+" ("+stance+") "+hits,zoomx(gx),zoomy(lfoot.y)
	End Method

End Type

Function groundheight#(x#)
	x=Abs(x)+1
	Return gfxheight-50-Abs(Log(x)*Sin(x)+Log(x))*3

End Function



Function scorekey[](name$)
	Local keyscore[3]
	i=1
	While i<Len(name)
		Select Chr(name[i])
		Case "o"
			keyscore[0]:+1
		Case "w"
			keyscore[1]:+1
		Case "l"
			keyscore[2]:+1
		Case "r"
			keyscore[0]:-1
		Case "d"
			keyscore[1]:-1
		Case "p"
			keyscore[2]:-1
		End Select
		i:+1
	Wend
	Return keyscore
End Function
Type speech
	Field x#,y#,txt$
	Field progress#
	Field fade#
	Field s:skeleton
	Field size#
	
	Function Create:speech(s:skeleton,x#,y#,txt$,size#=30)
		sp:speech=New speech
		sp.s=s
		sp.x=x
		sp.y=y
		sp.txt=txt
		sp.fade=1
		sp.size=size
		Return sp
	End Function
	
	Method update()
		progress:+Sqr(Len(txt))/10.0
		If progress>Len(txt)
			fade:-.001
			fade:*.99
		EndIf
		dy#=y-s.head.y
		If dy>0
			y:-dy*.2
		EndIf
	End Method
	
	Method draw()
		wf:wfont=wfont(dfonts.valueforkey("print"))
		'wf.draw txt[..Int(progress)],zoomx(x),zoomy(y),20
		tx#=x-wf.width(txt,size)/2
		numlines=wf.width(txt,size)/150
		ty#=y-(numlines-1)*wf.height(size)
		If progress>Len(txt)-1
			top=Len(txt)-1
		Else
			top=progress
		EndIf
		mx#=0
		newline=0
		
		SetBlend MASKBLEND
		SetColor 0,0,0
		For i=0 To top
			t#=(progress-i)/4
			If t>1 t=1
			SetAlpha t*fade
			c$=Chr(txt[i])
			wf.draw c,zoomx(tx+mx),zoomy(ty),size
			mx#:+wf.width(c,size)
			If mx>150
				newline=1
			EndIf
			If c=" " And newline
				ty:+wf.height(size)
				mx=0
				newline=0
			EndIf
		Next
		SetAlpha 1
	End Method
End Type

Global paper:timage
Type fight Extends gamemode
	Field hero:skeleton
	Field villain:skeleton
	
	Field g:grammar
	Field gi:ginput
	Field victor:skeleton
	
	Field sp:speech
	
	Method New()
		paper=LoadImage("images/bluepaper.jpg")
		hero:skeleton=skeleton.Create(-200,groundheight(-200),1,20)
		villain:skeleton=skeleton.Create(200,groundheight(200),-1,22)
		hero.opponent=villain
		villain.opponent=hero
		
		g=grammar.find("fencing insults")
		gi=ginput.Create(g,0,0,gfxwidth,gfxheight/2)
		
		panx=-gfxwidth/2
		pany=0'gfxheight/2
		zoom=1
	End Method
	
	Method update()
		hero.update
		villain.update
		
		
		hero.ai
		villain.ai
		
		'gi.update
		'If gi.out
		'	insult hero,gi.out.value()
		'	gi.reset
		'EndIf
		
		hero.mouseselection
		villain.aiselection
		
		Rem
		If KeyHit(KEY_ENTER)
			g:grammar=grammar.find("fencing insults")
			txt$=g.fill()
			insult hero,txt
		EndIf
		EndRem
		
		If sp
			If victor
				hero.relax
				villain.relax
			EndIf
			sp.update
			If sp.fade<=.4
				sp=Null
				If victor
					If victor=hero
						win
					Else
						lose
					EndIf
				EndIf
			EndIf
		EndIf
		
		camera
		
		If KeyHit(KEY_LCONTROL)
			status=1
		EndIf
		
	End Method
	
	Method insult(s:skeleton,txt$)
		Print txt
		sp=speech.Create(s,s.head.x,s.head.y,txt)
	End Method
	
	Method camera()

		mx#=(hero.mx+villain.mx)/2
		dx#=mx-panx-gfxwidth/2
		'DrawText dx,0,100
		'DrawLine gfxwidth/2,0,mx,groundheight(mx)
		'DrawLine gfxwidth/2,0,panx,groundheight(panx)
		bump#=gfxwidth*.2
		If Abs(dx)>bump
			dx:-Sgn(dx)*bump
			panx:+dx*.01
		EndIf
		
		my=(hero.gy+villain.gy)/2-gfxheight+(hero.size+villain.size)*3
		dy#=my-pany
		If Abs(dy)>50
			dy:-Sgn(dy)*50
			pany:+dy*.01
		EndIf
		
	End Method
	
	Method victory(s:skeleton)
		insult s.opponent,"Mercy!"
		victor=s
	End Method
	
	Method win()
		status=1
	End Method
	Method lose()
		status=2
	End Method
	
	Method draw()
		Local oy#
		For x=0 To 959 Step 1
			y#=groundheight(x+panx)-pany
			If x
				DrawLine x-1,oy,x,y
			EndIf
			oy=y
		Next
		
		hero.draw
		villain.draw
		
		
		If sp
			sp.draw
		Else
			'gi.draw
		EndIf
		
	End Method
End Type

Rem
Type gamemode
	Field status
	
	Method New()
		FlushKeys
		FlushMouse
	End Method
	
	Method update() Abstract
	Method draw() Abstract
End Type

Global gfxwidth=960
Global gfxheight=600
Graphics 960,600,0
curmode:gamemode=New fight
oms=MilliSecs()
While 1
	curmode.update
	curmode.draw
	
	ms=MilliSecs()
	fps=1000/(ms-oms)
	DrawText fps,0,0
	oms=ms

	Flip
	Cls
	
	If KeyHit(KEY_ESCAPE) Or AppTerminate()
		End
	EndIf
Wend
endrem