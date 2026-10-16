import AppKit
let short=ProcessInfo.processInfo.environment["DOVE_SHORT"] == "1"
let still=ProcessInfo.processInfo.environment["DOVE_STORYBOARD"] == "1"
let isDove=true
let paper=Col(0xF7F5ED),accent=Col(0x294B3B),ink=Col(0x203E31),highlight=Col(0xF2D69A)
let headFace=Face.system(.bold,.serif)
let home=Screenshot("assets/screen-home.png"),reader=Screenshot("assets/screen-reader.png"),context=Screenshot("assets/screen-context.png"),compare=Screenshot("assets/screen-comparison-stacked.png"),listen=Screenshot("assets/screen-listening.png"),journey=Screenshot("assets/screen-journey.png")
let icon=loadImage("assets/app-icon.png"),logo=loadImage("assets/logo.png")
let badge:CGImage? = FileManager.default.fileExists(atPath:projectDir.appendingPathComponent("assets/download-on-the-app-store-black-en-us.svg").path) ? loadSVG("assets/download-on-the-app-store-black-en-us.svg",height:130) : nil
enum T {
 static let bpm=112.0
 static let read=short ? 2.5 : 3.0,context=7.0,compare=11.0,listen=15.0,grow=19.0,privacy=23.0
 static let reflect=6.0,end=short ? 11.0 : 26.0,duration=short ? 15.0 : 30.0
 static let hold=duration-2,tap=read+1
}
func makeFilm()->Film {Film(name:short ? "dove-launch-15s" : "dove-launch-30s",width:1080,height:1920,fps:60,duration:T.duration,bpm:T.bpm,holdFrom:T.hold,draw:frame,score:score,keyframes:short ? [1.4,5.2,8.8,14] : [1.5,5.8,9.4,13.4,17.4,21.4,24.8,29],motionMoments:[0.5,T.read,T.tap,T.tap+0.5,T.context,T.compare,T.listen,T.grow,T.privacy,T.end])}
func hook(_ t:Double) {
 stageBackground(t)
 headline(["Read. Reflect.","*Grow*."],t:t,from:0,to:T.read,immediate:true,size:114)
 phone(home,in:CGRect(x:80,y:650,width:430,height:1000),t:t,from:0,side:-160)
 phone(reader,in:CGRect(x:550,y:720,width:410,height:950),t:t,from:0.25,side:160)
 label("A daily practice",t:t,from:0.5,to:T.read,at:CGPoint(x:520,y:1170))
 drawnArrow([CGPoint(x:190,y:1570),CGPoint(x:500,y:1640),CGPoint(x:840,y:1570)],t:t,from:0.6,colour:accent)
}
func readScene(_ t:Double) {
 stageBackground(t,dark:true)
 headline(["Pick up","*where you left*."],t:t,from:T.read,to:short ? T.reflect : T.context,dark:true,size:104)
 let box=CGRect(x:80,y:660,width:880,height:980)
 let camera=ScreenMove(home,[(T.read,home.bounds),(T.read+0.65,CGRect(x:35,y:1190,width:1136,height:520))])
 let time=still ? T.tap+1 : t
 changeState(t:time,at:T.tap+0.15,length:0.4,style:.push(.left),in:box,radius:36,before:{camera.draw(time,in:box,radius:36)},after:{drawScreen(reader,in:box,radius:36)})
 if time>=T.tap-0.1 && time<T.tap+0.2 {let r=camera.region(time);tapRipple(at:canvasPoint(CGPoint(x:1020,y:1460),region:r,drawnIn:fitted(r,in:box)),at:T.tap,t:time,colour:highlight)}
 label("Read offline",t:t,from:T.read+0.5,to:short ? T.reflect : T.context,dark:true)
}
func contextScene(_ t:Double) {
 stageBackground(t)
 headline(["Explore","*passage context*."],t:t,from:T.context,to:T.compare,size:104)
 phone(context,in:CGRect(x:130,y:650,width:800,height:1080),t:t,from:T.context,side:180)
 label("Understand the passage",t:t,from:T.context+0.5,to:T.compare)
 drawnArrow([CGPoint(x:130,y:1530),CGPoint(x:110,y:1430),CGPoint(x:160,y:1350)],t:t,from:T.context+1,colour:accent)
}
func compareScene(_ t:Double) {
 stageBackground(t,dark:true)
 headline(["Compare","*English + Spanish*."],t:t,from:T.compare,to:T.listen,dark:true,size:100)
 focus(compare,region:CGRect(x:20,y:350,width:1166,height:1150),in:CGRect(x:80,y:650,width:880,height:900),t:t,from:T.compare)
 label("Read side by side",t:t,from:T.compare+0.5,to:T.listen,dark:true)
 // Parallel strokes echo two editions without altering the source text.
 for i in 0..<3 {let p=still ? 1 : outCubic(prog(t,T.compare+0.7+Double(i)*0.3,T.compare+1.1+Double(i)*0.3))
  line(CGPoint(x:180,y:1590+CGFloat(i)*36),CGPoint(x:180+650*CGFloat(p),y:1590+CGFloat(i)*36),highlight.alpha(0.25),8)}
}
func listenScene(_ t:Double) {
 stageBackground(t)
 headline(["Read it.","*Listen, too*."],t:t,from:T.listen,to:T.grow,size:110)
 phone(listen,in:CGRect(x:150,y:650,width:780,height:1050),t:t,from:T.listen,side:-180)
 label("Offline audio",t:t,from:T.listen+0.5,to:T.grow)
 // Sound-wave illustration outside the product, not a recording of voice playback.
 for i in 0..<15 {let q=Double(i)*0.65+(still ? 0 : t*4);let h=CGFloat(25+abs(sin(q))*80)
  fill(rr(CGRect(x:160+CGFloat(i)*50,y:1770-h/2,width:22,height:h),11),accent.alpha(0.5))}
}
func growScene(_ t:Double) {
 stageBackground(t,dark:true)
 headline(["Your practice.","*Your Journey*."],t:t,from:T.grow,to:T.privacy,dark:true,size:106)
 focus(journey,region:CGRect(x:25,y:350,width:1156,height:1500),in:CGRect(x:80,y:650,width:880,height:1000),t:t,from:T.grow)
 label("Reflect. Return. Grow.",t:t,from:T.grow+0.5,to:T.privacy,dark:true)
 drawnArrow([CGPoint(x:160,y:1610),CGPoint(x:460,y:1690),CGPoint(x:850,y:1560)],t:t,from:T.grow+1,colour:highlight)
}
func reflectScene(_ t:Double) {
 stageBackground(t)
 headline(["Your passage.","*Your reflection*."],t:t,from:T.reflect,to:T.end,size:104)
 phone(reader,in:CGRect(x:80,y:650,width:430,height:1000),t:t,from:T.reflect,side:-160)
 phone(journey,in:CGRect(x:550,y:720,width:410,height:950),t:t,from:T.reflect+0.25,side:160)
 label("Read. Reflect. Grow.",t:t,from:T.reflect+0.5,to:T.end,at:CGPoint(x:520,y:1170))
}
func privacyScene(_ t:Double) {
 stageBackground(t)
 headline(["Your journal.","*On your device*."],t:t,from:T.privacy,to:T.end,size:102)
 let box=CGRect(x:370,y:650,width:340,height:340)
 lift(box,t:t,from:T.privacy){drawImage(logo,in:fitted(CGRect(x:0,y:0,width:logo.width,height:logo.height),in:box))}
 label("Private by design",t:t,from:T.privacy+0.5,to:T.end,at:CGPoint(x:520,y:1170))
 for i in 0..<3 {let r=CGFloat(220+i*100);stroke(CGPath(ellipseIn:centred(CGPoint(x:540,y:850),r),transform:nil),accent.alpha(0.10),4)}
}
func ending(_ t:Double) {
 fill(fullCanvas(),accent)
 let tt=min(t,T.hold),box=CGRect(x:430,y:330,width:220,height:220)
 lift(box,t:tt,from:T.end){ctx.saveGState();ctx.addPath(rr(box,44));ctx.clip();drawImage(icon,in:box);ctx.restoreGState()}
 Kinetic(lines:["Dove"],face:headFace,size:160,colour:paper,x:540,y:790,from:T.end+0.25,enter:still ? .none : .rise,exit:.none,align:0.5,maxWidth:880).draw(tt)
 Kinetic(lines:["Read. Reflect. Grow."],face:.system(.regular,.serif),size:58,colour:paper,x:540,y:930,from:T.end+0.5,enter:.none,align:0.5,maxWidth:880).draw(tt)
 if t>=T.end+1 {_ = exampleStoreBadge(badge,centre:CGPoint(x:540,y:1130),height:130)}
}
let reel:Reel={
 var c=[Clip(from:0,to:T.read,draw:hook),Clip(from:T.read,to:short ? T.reflect : T.context,draw:readScene)]
 var j:[(Join,Double)]=[(.whip(.up),0.25)]
 if short {c.append(Clip(from:T.reflect,to:T.end,draw:reflectScene));j.append((.cover(.left),0.3))}
 else {c += [Clip(from:T.context,to:T.compare,draw:contextScene),Clip(from:T.compare,to:T.listen,draw:compareScene),Clip(from:T.listen,to:T.grow,draw:listenScene),Clip(from:T.grow,to:T.privacy,draw:growScene),Clip(from:T.privacy,to:T.end,draw:privacyScene)];j += [(.cover(.left),0.3),(.slice(degrees:10),0.25),(.cover(.up),0.3),(.whip(.left),0.25),(.cover(.left),0.3)]}
 c.append(Clip(from:T.end,to:T.duration,draw:ending));j.append((.cover(.up),0.3));return Reel(c,joins:j)
}()
func frame(_ t:Double){reel.draw(t)}
let recipe=Recipe(bpm:T.bpm,key:2,mode:.majorPentatonic,progression:[1,4,1,5],barsPerChord:2,chordColour:.add9,kit:.lofi,drums:Drums(kick:"X.......x..x....",rim:"....x.......x...",shaker:"..o...o...o...o."),parts:[Part(synth:.piano,rhythm:"X___..x_....x_..",notes:.motif,octave:4,gain:0.30,from:1),Part(synth:.kalimba,rhythm:"..x...x...x..x..",notes:.arpUpDown,octave:5,gain:0.12,from:2),Part(synth:.sub,rhythm:"X_______x_______",notes:.rootFifth,octave:2,gain:0.16,from:1),Part(synth:.pad,rhythm:"X_______________",notes:.chord,octave:3,gain:0.10,from:0)],space:.hall,colour:.warm,sidechain:0.12,seed:482617)
func score(_ s:Score){s.compose(recipe,[Section(from:0,to:T.read,energy:2,fill:false),Section(from:T.read,to:T.end,energy:2,fill:false),Section(from:T.end,to:T.duration,energy:0,fill:false)])
 s.cue(T.tap,"Continue reading",click(),0.10);s.cue(T.tap+0.15,"Open chapter",pageFlip(),0.14)
 let cuts=short ? [T.read,T.reflect,T.end] : [T.read,T.context,T.compare,T.listen,T.grow,T.privacy,T.end]
 for a in cuts {s.cue(a,"Page handoff",swish(),0.05);s.hit(recipe,at:a,synth:.piano,gain:0.12)}
 s.cadence(recipe,at:T.end+0.5,length:2.8,synth:.piano,gain:0.30);s.fadeOut=(T.duration-1.3,T.duration-0.1)
}

@discardableResult
func exampleStoreBadge(_ badge:CGImage?,centre:CGPoint,height:CGFloat)->CGRect {
 if let badge {return drawAppStoreBadge(badge,centre:centre,height:height)}
 let r=CGRect(x:centre.x-320,y:centre.y-height/2,width:640,height:height)
 text("On the App Store",42,.semibold,paper,centre.x,centre.y+15,align:0.5)
 return r
}
