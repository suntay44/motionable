import AppKit
let short=ProcessInfo.processInfo.environment["PONDA_SHORT"] == "1"
let still=ProcessInfo.processInfo.environment["PONDA_STORYBOARD"] == "1"
let live=ProcessInfo.processInfo.environment["PONDA_LIVE"] != "0"
let isDove=false
let paper=Col(0xFFF6ED),accent=Col(0xB4232D),ink=Col(0x35151A),highlight=Col(0xFFD88C)
let headFace=Face.system(.heavy,.rounded)
let detail=Screenshot("assets/screen-detail.png"),scaling=Screenshot("assets/screen-scaling.png"),explore=Screenshot("assets/screen-explore.png"),cart=Screenshot("assets/screen-cart.png"),left=Screenshot("assets/screen-leftovers.png"),sheet=Screenshot("assets/screen-kitchen-sheet.png")
let mascot=loadImage("assets/mascot-pose-2.png"),icon=loadImage("assets/logo-icon.png")
let badge:CGImage? = FileManager.default.fileExists(atPath:projectDir.appendingPathComponent("assets/download-on-the-app-store-black-en-us.svg").path) ? loadSVG("assets/download-on-the-app-store-black-en-us.svg",height:130) : nil
enum T {
 static let bpm=128.0,beat=60.0/128
 static let scale=2.8125
 static let shop=short ? 6.5625 : 15.0
 static let cost=7.5,left=10.78125,export=18.28125,privateBeat=22.5
 static let end=short ? 11.25 : 26.25,duration=short ? 15.0 : 30.0
 static let hold=duration-2
}
func makeFilm()->Film {Film(name:short ? "ponda-launch-15s" : "ponda-launch-30s",width:1080,height:1920,fps:60,duration:T.duration,bpm:T.bpm,holdFrom:T.hold,draw:frame,score:score,keyframes:short ? [1.6,5.4,9.3,14] : [1.8,6.4,9.5,13.5,17.3,21,24.3,29],motionMoments:[0.5,T.scale,T.scale+1,T.shop,T.end,T.end+0.5])}
func hook(_ t:Double) {
 stageBackground(t)
 headline(["Cook for 4.","*Or 40*."],t:t,from:0,to:T.scale,immediate:true,size:116)
 phone(detail,in:CGRect(x:80,y:610,width:420,height:1000),t:t,from:0,side:-200)
 let box=CGRect(x:560,y:650,width:400,height:860)
 lift(box,t:t,from:0.25,side:180){drawImage(mascot,in:fitted(CGRect(x:0,y:0,width:mascot.width,height:mascot.height),in:box))}
 label("Meet Ponda",t:t,from:0.5,to:T.scale,at:CGPoint(x:750,y:600))
 drawnArrow([CGPoint(x:460,y:780),CGPoint(x:530,y:720),CGPoint(x:620,y:780)],t:t,from:0.5,colour:accent)
 rays(t,from:1,at:CGPoint(x:750,y:1400),colour:accent)
}
func scaleScene(_ t:Double) {
 stageBackground(t,dark:true)
 headline(["Scale every","*ingredient*."],t:t,from:T.scale,to:short ? T.shop : T.cost,dark:true)
 let region=CGRect(x:25,y:460,width:1156,height:1040)
 let keys:[(Double,CGRect)] = short ? [(T.scale,scaling.bounds),(T.scale+0.65,region)] : [(T.scale,scaling.bounds),(T.scale+0.65,region),(T.scale+2.2,region),(T.scale+2.8,CGRect(x:20,y:1840,width:1166,height:650))]
 ScreenMove(scaling,keys).draw(still ? (short ? T.scale+1 : T.scale+3) : t,in:CGRect(x:80,y:650,width:880,height:800),radius:32)
 label("4 → 40 servings",t:t,from:T.scale+0.5,to:short ? T.shop : T.cost,dark:true)
 // Promotional digits echo the actual before/after servings; screen contents are untouched.
 unlogged {rollNumber("40",p:still ? 1 : prog(t,T.scale+0.5,T.scale+1.5),x:520,y:1630,size:180,face:headFace,colour:highlight,align:0.5)}
 rays(t,from:T.scale+1.5,at:CGPoint(x:520,y:1540),colour:highlight)
}
func costScene(_ t:Double) {
 stageBackground(t)
 headline(["Know the","*cost per plate*."],t:t,from:T.cost,to:T.left,size:104)
 focus(detail,region:CGRect(x:25,y:420,width:1156,height:450),in:CGRect(x:80,y:680,width:880,height:520),t:t,from:T.cost)
 label("Your prices. Your estimate.",t:t,from:T.cost+0.5,to:T.left,at:CGPoint(x:520,y:1170))
 for i in 0..<5 {let p=still ? 1 : outCubic(prog(t,T.cost+Double(i)*0.3,T.cost+Double(i)*0.3+0.4));let h=CGFloat(60+i*25)*CGFloat(p)
  fill(rr(CGRect(x:170+CGFloat(i)*155,y:1570-h,width:110,height:h),22),accent.alpha(0.15+CGFloat(i)*0.1))}
}
func leftScene(_ t:Double) {
 stageBackground(t,dark:true)
 headline(["Use what","*you have*."],t:t,from:T.left,to:T.shop,dark:true)
 focus(left,region:CGRect(x:20,y:520,width:1166,height:1250),in:CGRect(x:80,y:650,width:880,height:900),t:t,from:T.left)
 label("Scale by ingredient",t:t,from:T.left+0.5,to:T.shop,dark:true)
 drawnArrow([CGPoint(x:180,y:1570),CGPoint(x:500,y:1620),CGPoint(x:840,y:1560)],t:t,from:T.left+1,colour:highlight)
}
func shopScene(_ t:Double) {
 stageBackground(t)
 headline(["Every recipe.","*One grocery list*."],t:t,from:T.shop,to:short ? T.end : T.export,size:100)
 focus(cart,region:CGRect(x:20,y:300,width:1166,height:1800),in:CGRect(x:80,y:650,width:880,height:1050),t:t,from:T.shop)
 label("Shop from one list",t:t,from:T.shop+0.5,to:short ? T.end : T.export)
 rays(t,from:T.shop+1,at:CGPoint(x:830,y:1510),colour:accent)
}
func exportScene(_ t:Double) {
 stageBackground(t,dark:true)
 headline(["Share it.","*Print it*."],t:t,from:T.export,to:T.privateBeat,dark:true)
 phone(sheet,in:CGRect(x:80,y:650,width:470,height:1000),t:t,from:T.export,side:-180)
 phone(cart,in:CGRect(x:580,y:760,width:380,height:840),t:t,from:T.export+0.25,side:180)
 label("PDF · Excel · text",t:t,from:T.export+0.5,to:T.privateBeat,dark:true)
 drawnArrow([CGPoint(x:450,y:1400),CGPoint(x:550,y:1450),CGPoint(x:670,y:1400)],t:t,from:T.export+1,colour:highlight)
}
func privacyScene(_ t:Double) {
 stageBackground(t)
 headline(["No account.","*Works offline*."],t:t,from:T.privateBeat,to:T.end)
 let box=CGRect(x:260,y:650,width:560,height:800)
 lift(box,t:t,from:T.privateBeat){drawImage(mascot,in:fitted(CGRect(x:0,y:0,width:mascot.width,height:mascot.height),in:box))}
 label("A little prep. A lot easier.",t:t,from:T.privateBeat+0.5,to:T.end,at:CGPoint(x:520,y:600))
}
func ending(_ t:Double) {
 fill(fullCanvas(),accent)
 let tt=min(t,T.hold),box=CGRect(x:430,y:330,width:220,height:220)
 lift(box,t:tt,from:T.end){drawImage(icon,in:box)}
 Kinetic(lines:["Ponda","the Chef"],face:headFace,size:120,colour:paper,x:540,y:740,from:T.end+0.25,enter:still ? .none : .stamp,exit:.none,align:0.5,lineHeight:0.95,maxWidth:880).draw(tt)
 Kinetic(lines:["Scale. Cost. Shop."],face:.system(.semibold),size:48,colour:paper,x:540,y:1000,from:T.end+0.5,enter:.none,align:0.5).draw(tt)
 if t>=T.end+1 {if live {_ = exampleStoreBadge(badge,centre:CGPoint(x:540,y:1160),height:130)} else {Kinetic(lines:["Coming soon"],face:.system(.semibold),size:44,colour:paper,x:540,y:1160,from:T.end+1,enter:.none,align:0.5).draw(tt)}}
}
let reel:Reel={
 var c=[Clip(from:0,to:T.scale,draw:hook),Clip(from:T.scale,to:short ? T.shop : T.cost,draw:scaleScene)]
 var j:[(Join,Double)]=[(.whip(.up),0.25)]
 if !short {c += [Clip(from:T.cost,to:T.left,draw:costScene),Clip(from:T.left,to:T.shop,draw:leftScene)];j += [(.slice(degrees:12),0.25),(.cover(.left),0.25)]}
 c.append(Clip(from:T.shop,to:short ? T.end : T.export,draw:shopScene));j.append((.whip(.left),0.25))
 if !short {c += [Clip(from:T.export,to:T.privateBeat,draw:exportScene),Clip(from:T.privateBeat,to:T.end,draw:privacyScene)];j += [(.cover(.up),0.25),(.cover(.left),0.25)]}
 c.append(Clip(from:T.end,to:T.duration,draw:ending));j.append((.cover(.up),0.25));return Reel(c,joins:j)
}()
func frame(_ t:Double){reel.draw(t)}
let recipe=Recipe(bpm:T.bpm,swing:0.1,key:10,mode:.major,progression:[1,6,2,5],barsPerChord:1,chordColour:.seventh,kit:.punchy,drums:Drums(kick:"X..x....X.x.....",snare:"....X.......X...",shaker:"xoxoxoxoxoxoxoxo"),parts:[Part(synth:.marimba,rhythm:"X.x..x.xx..x.x..",notes:.motif,octave:5,gain:0.25,from:1),Part(synth:.funk,rhythm:"X..x..X...x.X...",notes:.walk,octave:2,gain:0.30,from:1),Part(synth:.ePiano,rhythm:"X___..x_....x_..",notes:.chord,octave:4,gain:0.20,from:0)],space:.room,colour:.warm,sidechain:0.22,seed:723159)
func score(_ s:Score){s.compose(recipe,[Section(from:0,to:T.scale,energy:2,fill:false),Section(from:T.scale,to:T.end,energy:3,fill:false),Section(from:T.end,to:T.duration,energy:1,fill:false)])
 for a in [T.scale,T.shop,T.end] {s.cue(a,"Kitchen handoff",chop(),0.10);s.hit(recipe,at:a,synth:.marimba,gain:0.18)}
 s.cue(T.scale+1.5,"Servings lands",kaching(),0.18)
 if !short {for a in [T.cost,T.left,T.export,T.privateBeat]{s.cue(a,"Feature",pageFlip(),0.10)}}
 s.cadence(recipe,at:T.end+0.5,length:2.8,synth:.ePiano,gain:0.28);s.fadeOut=(T.duration-1.2,T.duration-0.1)
}

@discardableResult
func exampleStoreBadge(_ badge:CGImage?,centre:CGPoint,height:CGFloat)->CGRect {
 if let badge {return drawAppStoreBadge(badge,centre:centre,height:height)}
 let r=CGRect(x:centre.x-320,y:centre.y-height/2,width:640,height:height)
 text("On the App Store",42,.semibold,paper,centre.x,centre.y+15,align:0.5)
 return r
}
