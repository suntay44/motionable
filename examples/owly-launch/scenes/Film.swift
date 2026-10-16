import AppKit
let owShort = ProcessInfo.processInfo.environment["OWLY_SHORT"] == "1"
let owStill = ProcessInfo.processInfo.environment["OWLY_STORYBOARD"] == "1"
enum T {
 static let bpm = 120.0, beat = 0.5
 static let write = owShort ? 2.0 : 2.5
 static let share = owShort ? 5.0 : 6.5
 static let widget = owShort ? 7.0 : 9.0
 static let tap = owShort ? 7.5 : 9.5
 static let done = owShort ? 8.5 : 10.5
 static let routine = 12.5, day = 17.0, recap = 22.0
 static let end = owShort ? 11.0 : 26.0
 static let duration = owShort ? 15.0 : 30.0
 static let hold = duration-2
}
let paper=Col(0xF6F3E8), green=Col(0x0B7A31), ink=Col(0x10241A), lime=Col(0xC8F36A), blue=Col(0x2F6FE0)
let face=Face.system(.heavy)
let logo=loadImage("assets/logo.png")
let badge:CGImage? = FileManager.default.fileExists(atPath:projectDir.appendingPathComponent("assets/download-on-the-app-store-black-en-us.svg").path) ? loadSVG("assets/download-on-the-app-store-black-en-us.svg",height:130) : nil
let parent=Screenshot("assets/screen-parent-result.png")
let capacity=Screenshot("assets/screen-capacity.png")
let routine=Screenshot("assets/screen-routine.png")
let typing=Footage("assets/parent-typing.mp4")
let child=Footage("assets/child-widget.mp4")
let listRegion=CGRect(x:25,y:165,width:1156,height:900)
let typeRegion=CGRect(x:20,y:240,width:1166,height:760)
let widgetRegion=CGRect(x:65,y:245,width:1076,height:620)
let typePlay=Playback([(T.write,0.5),(T.write+0.25,1),(T.share-0.25,6.6),(T.share,6.6)],ramps:false)
let childPlay=Playback([(T.share,2.6),(T.widget,2.6),(T.tap,4),(T.done,6.1),(T.done+1,8.5),(T.end,8.5)],ramps:false)
func makeFilm()->Film {
 Film(name:owShort ? "owly-hype-15s" : "owly-hype-30s",width:1080,height:1920,fps:60,duration:T.duration,bpm:T.bpm,holdFrom:T.hold,draw:frame,score:score,
 keyframes:owShort ? [1.3,4.2,6.4,8.1,9.8,14] : [1.5,5.7,8.2,10,11.6,14.8,19.5,24.5,29],motionMoments:[0.5,T.write,T.write+1,T.share,T.share+1,T.widget,T.tap,T.done,T.done+0.5,T.routine,T.day,T.recap,T.end,T.end+0.5])
}
// Camera-framed artwork uses authentic screenshots/recordings. The stage and chips are promotional graphics.
func ground(_ t:Double,dark:Bool=false) {
 fill(fullCanvas(),dark ? ink : paper)
 let c=(dark ? lime : green).alpha(dark ? 0.08 : 0.055)
 let drift=owStill ? 0 : CGFloat(sin(t*0.65))*65
 for i in 0..<3 {
  let r=CGFloat(260+i*145)
  stroke(CGPath(ellipseIn:CGRect(x:580-r+drift,y:1050-r,width:r*2,height:r*2),transform:nil),c,CGFloat(22-i*5))
 }
 for x in stride(from:CGFloat(55),to:1080,by:50) { for y in stride(from:CGFloat(180),to:1840,by:50) {
  fill(CGPath(ellipseIn:CGRect(x:x,y:y,width:2,height:2),transform:nil),(dark ? paper : green).alpha(0.10))
 } }
}
func title(_ lines:[String],_ t:Double,_ a:Double,_ b:Double,dark:Bool=false,size:CGFloat=108,immediate:Bool=false) {
 Kinetic(lines:lines,face:face,size:size,colour:dark ? paper : ink,x:80,y:395,from:a,to:b,enter:owStill || immediate ? .none : .stamp,exit:.none,lineHeight:1.02,maxWidth:880,stagger:0,accent:TextStyle(colour:dark ? lime : green)).draw(t)
}
func staged(_ rect:CGRect,_ t:Double,_ a:Double,angle:CGFloat=0,dx:CGFloat=0,_ paint:()->Void) {
 let p=owStill ? 1 : outCubic(prog(t,a,a+0.5))
 ctx.saveGState();ctx.translateBy(x:rect.midX+dx*CGFloat(1-p),y:rect.midY+120*CGFloat(1-p));ctx.rotate(by:angle*CGFloat(p) * .pi/180)
 let s=CGFloat(0.84+0.16*p);ctx.scaleBy(x:s,y:s);ctx.translateBy(x:-rect.midX,y:-rect.midY);paint();ctx.restoreGState()
}
func arrow(_ pts:[CGPoint],_ p:Double,_ c:Col=green) {
 stroke(partial(pts,p),c,8)
 if p>=1,let z=pts.last,pts.count>1 { let prev=pts[pts.count-2];let a=atan2(z.y-prev.y,z.x-prev.x)
  line(z,CGPoint(x:z.x-26*cos(a-0.55),y:z.y-26*sin(a-0.55)),c,8)
  line(z,CGPoint(x:z.x-26*cos(a+0.55),y:z.y-26*sin(a+0.55)),c,8)
 }
}
func sparks(_ t:Double,at a:Double,centre:CGPoint,colour:Col=green) {
 let p=owStill ? 0.6 : prog(t,a,a+0.6)
 guard p>0 && p<1 else{return}
 for i in 0..<12 {let ang=Double(i)*Double.pi/6;let r=70+160*p
  let c=CGPoint(x:centre.x+CGFloat(cos(ang)*r),y:centre.y+CGFloat(sin(ang)*r))
  let z=CGFloat(18*(1-p));line(c,CGPoint(x:c.x+CGFloat(cos(ang))*z,y:c.y+CGFloat(sin(ang))*z),colour.alpha(CGFloat(1-p)),7)
 }
}
func chip(_ s:String,at c:CGPoint,t:Double,from a:Double,to b:Double,fill bg:Col=lime,ink fg:Col=ink,size:CGFloat=40) {
 guard t>=a && t<b else{return}
 sticker(s,at:c,fill:bg,ink:fg,face:.system(.bold),size:size,degrees:0,p:owStill ? 1 : prog(t,a,a+0.25))
}
func phone(_ shot:Screenshot,_ box:CGRect,t:Double,from a:Double,angle:CGFloat=0,dx:CGFloat=0) {
 staged(box,t,a,angle:angle,dx:dx) {drawScreen(shot,in:box,radius:40)}
}
func hook(_ t:Double) {
 ground(t)
 title(owShort ? ["Write it.","*Tick it*."] : ["You write it.","*They tick it*."],t,0,T.write,size:118,immediate:true)
 let a=CGRect(x:80,y:590,width:400,height:900),b=CGRect(x:560,y:690,width:400,height:900)
 phone(parent,a,t:t,from:0,angle:-7,dx:-160)
 staged(b,t,0.35,angle:7,dx:180) {drawFootage(child,at:6.8,in:b,radius:40)}
 arrow([CGPoint(x:440,y:780),CGPoint(x:500,y:730),CGPoint(x:540,y:765),CGPoint(x:590,y:850)],owStill ? 1 : prog(t,0.65,1.15))
 sparks(t,at:1,centre:CGPoint(x:540,y:950))
 chip("One shared list",at:CGPoint(x:520,y:1150),t:t,from:0.25,to:T.write,fill:lime)
}
func write(_ t:Double) {
 ground(t,dark:true)
 title(["Type it.","*Owly gets it*."],t,T.write,T.share,dark:true)
 let box=CGRect(x:80,y:610,width:880,height:500)
 staged(box,t,T.write,dx:160) {drawFootage(typing,at:owStill ? 6.6 : typePlay.at(t),region:typeRegion,in:box,radius:36)}
 // The real recognized-time chip remains in the recording. The larger pill below is an explanatory annotation.
 let reveal=owShort ? T.write+1 : T.write+1.5
 chip("Task + time",at:CGPoint(x:520,y:1170),t:t,from:reveal,to:T.share,fill:lime)
 arrow([CGPoint(x:840,y:1090),CGPoint(x:910,y:1160),CGPoint(x:890,y:1270)],owStill ? 1 : prog(t,reveal,reveal+0.5),lime)
 // Stacked task-card silhouettes continue the visual rhythm without introducing extra copy.
 for i in 0..<3 {
  let p=owStill ? 1 : outCubic(prog(t,T.write+0.5+Double(i)*0.5,T.write+1+Double(i)*0.5))
  let r=CGRect(x:140+CGFloat(i)*45,y:1340+CGFloat(i)*95+70*CGFloat(1-p),width:720,height:100)
  fill(rr(r,25),paper.alpha(0.10+0.05*CGFloat(i)));fill(CGPath(ellipseIn:CGRect(x:r.minX+30,y:r.minY+30,width:36,height:36),transform:nil),lime.alpha(0.6))
  line(CGPoint(x:r.minX+100,y:r.midY),CGPoint(x:r.maxX-70,y:r.midY),paper.alpha(0.25),12)
 }
}
func share(_ t:Double) {
 ground(t)
 title(owShort ? ["*Share it*."] : ["One list.","*Your people*."],t,T.share,T.widget,size:112)
 let p=owStill ? 1 : inOut(prog(t,T.share+0.5,T.share+1.5))
 let a=CGRect(x:75,y:610,width:400,height:880),b=CGRect(x:560,y:680,width:400,height:880)
 phone(parent,a,t:t,from:T.share,angle:-5,dx:-180)
 staged(b,t,T.share+0.25,angle:5,dx:180) {drawFootage(child,at:2.6,in:b,radius:38)}
 let c=lerp(CGPoint(x:330,y:1150),CGPoint(x:660,y:1150),p)
 arrow([CGPoint(x:350,y:1010),CGPoint(x:490,y:980),CGPoint(x:580,y:1030),CGPoint(x:690,y:1030)],owStill ? 1 : prog(t,T.share+0.4,T.share+0.9))
 chip("Family lists",at:c,t:t,from:T.share+0.3,to:T.widget,fill:lime)
}
func widget(_ t:Double) {
 ground(t,dark:true)
 if t<T.done {title(["*Home Screen*."],t,T.widget,T.done,dark:true,size:104,immediate:true)}
 else {title(["*Done*.","Just like that."],t,T.done,owShort ? T.end : T.routine,dark:true,size:110,immediate:true)}
 let zoomEnd=T.widget+0.25
 let box=CGRect(x:80,y:660,width:880,height:580)
 let z=owStill ? widgetRegion : Zoom([(T.widget,CGRect(x:65,y:245,width:1076,height:850)),(zoomEnd,widgetRegion)]).region(t)
 let dest=drawFootage(child,at:owStill ? (t>=T.done ? 6.8 : 4) : childPlay.at(t),region:z,in:box,radius:38,camera:t<zoomEnd)
 if !owStill {TouchPath([(T.tap-0.3,CGPoint(x:205,y:630)),(T.tap,CGPoint(x:158,y:576))],taps:[T.tap]).draw(t,colour:lime,size:55,map:{canvasPoint($0,region:z,drawnIn:dest)})}
 sparks(t,at:T.done,centre:CGPoint(x:540,y:950),colour:lime)
 // A large drawn check orbits below the actual completed widget; it is a celebratory graphic.
 if t>=T.done {
  let p=owStill ? 1 : outCubic(prog(t,T.done,T.done+0.5));let r=CGRect(x:410,y:1320,width:220,height:220)
  fill(CGPath(ellipseIn:r,transform:nil),lime)
  stroke(partial([CGPoint(x:460,y:1430),CGPoint(x:505,y:1470),CGPoint(x:580,y:1385)],p),ink,16)
  for i in 0..<3 {let a=Double(i)*2.1+(owStill ? 0 : t-T.done)*0.8
   let c=CGPoint(x:520+CGFloat(cos(a))*180,y:1430+CGFloat(sin(a))*150)
   fill(CGPath(ellipseIn:centred(c,12),transform:nil),paper.alpha(0.7))
  }
 }
}
func routines(_ t:Double) {
 ground(t)
 title(["Routines.","*Ready for repeat*."],t,T.routine,T.day,size:102)
 let zoom=ScreenMove(routine,[(T.routine,routine.bounds),(T.routine+0.5,CGRect(x:20,y:440,width:1166,height:1000))])
 zoom.draw(owStill ? T.routine+1 : t,in:CGRect(x:80,y:650,width:880,height:740),radius:36)
 chip("Resets tomorrow",at:CGPoint(x:520,y:570),t:t,from:T.routine+1,to:T.day)
 // Circular repeat arrows draw around the routine proof, kept outside its text.
 let p=owStill ? 1 : prog(t,T.routine+0.5,T.routine+1.5)
 arrow([CGPoint(x:170,y:1460),CGPoint(x:290,y:1540),CGPoint(x:550,y:1570),CGPoint(x:790,y:1500),CGPoint(x:860,y:1410)],p)
 sparks(t,at:T.routine+2,centre:CGPoint(x:770,y:1460))
}
func day(_ t:Double) {
 ground(t,dark:true)
 title(["Big plans.","*Real limits*."],t,T.day,T.recap,dark:true,size:116)
 let region=CGRect(x:25,y:350,width:1156,height:1050)
 let box=CGRect(x:80,y:590,width:880,height:850)
 staged(box,t,T.day,dx:180) {drawScreen(capacity,region:region,in:box,radius:36)}
 chip("Daily capacity",at:CGPoint(x:520,y:570),t:t,from:T.day+0.5,to:T.recap,fill:lime)
 // A graphic meter expands in steps to echo the real UI's load calculation; it has no numerical claim.
 for i in 0..<12 {
  let p=owStill ? 1 : outCubic(prog(t,T.day+Double(i)*0.16,T.day+Double(i)*0.16+0.25))
  let h=CGFloat(50+i*11)*CGFloat(p)
  fill(rr(CGRect(x:125+CGFloat(i)*67,y:1650-h,width:44,height:h),12),(i<8 ? lime : Col(0xF6A78B)).alpha(0.85))
 }
}
func recap(_ t:Double) {
 ground(t)
 title(["Less chasing.","*More doing*."],t,T.recap,T.end,size:112)
 let cards:[(Screenshot,CGRect,CGFloat)]=[(parent,CGRect(x:90,y:630,width:410,height:760),-5),(routine,CGRect(x:550,y:630,width:410,height:760),5)]
 for (i,c) in cards.enumerated() {phone(c.0,c.1,t:t,from:T.recap+Double(i)*0.25,angle:c.2,dx:i==0 ? -150 : 150)}
 chip("Share. Tick. Repeat.",at:CGPoint(x:520,y:1170),t:t,from:T.recap+0.5,to:T.end,fill:green,ink:paper)
 arrow([CGPoint(x:170,y:1480),CGPoint(x:500,y:1550),CGPoint(x:850,y:1470)],owStill ? 1 : prog(t,T.recap+1,T.recap+2))
}
func ending(_ t:Double) {
 fill(fullCanvas(),green)
 let tt=min(t,T.hold),p=owStill ? 1 : outCubic(prog(tt,T.end,T.end+0.5))
 for i in 0..<4 {let r=CGFloat(160+i*105)*CGFloat(0.7+0.3*p)
  stroke(CGPath(ellipseIn:centred(CGPoint(x:540,y:580),r),transform:nil),paper.alpha(0.045),18)
 }
 let box=CGRect(x:420,y:350,width:240,height:240)
 staged(box,owStill ? T.end+1 : tt,T.end) {drawImage(logo,in:box)}
 Kinetic(lines:["Owly"],face:face,size:160,colour:paper,x:540,y:790,from:T.end+0.25,enter:owStill ? .none : .stamp,exit:.none,align:0.5,maxWidth:880).draw(tt)
 Kinetic(lines:["Shared lists.","Everyday help."],face:.system(.semibold),size:65,colour:paper,x:540,y:930,from:T.end+0.5,enter:.none,exit:.none,align:0.5,lineHeight:1.1,maxWidth:880).draw(tt)
 if t>=T.end+1 { _ = exampleStoreBadge(badge,centre:CGPoint(x:540,y:1150),height:130) }
}
let reel:Reel = {
 var clips=[Clip(from:0,to:T.write,draw:hook),Clip(from:T.write,to:T.share,draw:write),Clip(from:T.share,to:T.widget,draw:share),Clip(from:T.widget,to:owShort ? T.end : T.routine,draw:widget)]
 var joins:[(Join,Double)]=[(.whip(.up),0.25),(.cover(.left),0.25),(.cut,0)]
 if !owShort {
  clips += [Clip(from:T.routine,to:T.day,draw:routines),Clip(from:T.day,to:T.recap,draw:day),Clip(from:T.recap,to:T.end,draw:recap)]
  joins += [(.whip(.left),0.25),(.cover(.up),0.25),(.slice(degrees:15),0.25)]
 }
 clips.append(Clip(from:T.end,to:T.duration,draw:ending));joins.append((.cover(.up),0.25))
 return Reel(clips,joins:joins)
}()
func frame(_ t:Double){reel.draw(t)}
let recipe=Recipe(bpm:T.bpm,key:7,mode:.mixolydian,progression:[1,7,4,1],barsPerChord:1,chordColour:.sus2,kit:.clean,
 drums:Drums(kick:"X...x...X..x....",snare:"....X.......X...",shaker:"x.x.x.x.x.x.x.x."),
 parts:[Part(synth:.pluck,rhythm:"X..x..x...x.x...",notes:.motif,octave:4,gain:0.27,from:1),Part(synth:.ePiano,rhythm:"X_______..x_____",notes:.chord,octave:3,gain:0.16,from:0),Part(synth:.funk,rhythm:"X..x..X...x.X...",notes:.rootFifth,octave:2,gain:0.24,from:2)],space:.room,colour:.warm,sidechain:0.30,seed:916047)
func score(_ s:Score) {
 s.compose(recipe,[Section(from:0,to:T.write,energy:2,fill:false),Section(from:T.write,to:T.done,energy:2,fill:false),Section(from:T.done,to:T.end,energy:3,fill:false),Section(from:T.end,to:T.duration,energy:1,fill:false)])
 s.gates=[(T.done-0.25,T.done)]
 for a in [T.write,T.share,T.widget,T.end] {s.cue(a,"Scene handoff",swish(),0.07);s.hit(recipe,at:a,synth:.ePiano,gain:0.18)}
 for i in 0..<10 {s.cue(T.write+0.5+Double(i)*0.125,"Typing",keyTap(),0.04)}
 s.cue(T.tap,"Widget touch",click(),0.14)
 s.cue(T.done,"Completed tick",success(),0.15);s.hit(recipe,at:T.done,synth:.pluck,gain:0.3)
 if !owShort {for a in [T.routine,T.day,T.recap] {s.cue(a,"Feature reveal",swish(),0.08);s.hit(recipe,at:a,synth:.stab,gain:0.15)}}
 s.cadence(recipe,at:T.end+0.5,length:2.8,synth:.ePiano,gain:0.32)
 s.fadeOut=(T.duration-1.2,T.duration-0.1)
}

@discardableResult
func exampleStoreBadge(_ badge:CGImage?,centre:CGPoint,height:CGFloat)->CGRect {
 if let badge {return drawAppStoreBadge(badge,centre:centre,height:height)}
 let r=CGRect(x:centre.x-320,y:centre.y-height/2,width:640,height:height)
 text("On the App Store",42,.semibold,paper,centre.x,centre.y+15,align:0.5)
 return r
}
