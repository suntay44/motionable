import AppKit
func stageBackground(_ t:Double,dark:Bool=false) {
 fill(fullCanvas(),dark ? ink : paper)
 let c=(dark ? highlight : accent).alpha(0.075)
 if isDove {
  for i in 0..<6 {let q=CGFloat(i);let x=CGFloat(160)+q*140
   let p=CGMutablePath();p.move(to:CGPoint(x:x-300,y:1740));p.addCurve(to:CGPoint(x:x+400,y:600),control1:CGPoint(x:x+500,y:1600),control2:CGPoint(x:x-200,y:900));stroke(p,c,8)
  }
 } else {
  for i in 0..<5 {let r=CGFloat(250+i*115);let dx=still ? 0 : CGFloat(sin(t*0.7))*35
   stroke(CGPath(ellipseIn:centred(CGPoint(x:550+dx,y:1110),r),transform:nil),c,CGFloat(14-i*2))
  }
 }
}
func headline(_ lines:[String],t:Double,from a:Double,to b:Double,dark:Bool=false,immediate:Bool=false,size:CGFloat=106) {
 Kinetic(lines:lines,face:headFace,size:size,colour:dark ? paper : ink,x:80,y:395,from:a,to:b,enter:immediate || still ? .none : (isDove ? .rise : .stamp),exit:.none,lineHeight:1.03,maxWidth:880,stagger:0,accent:TextStyle(colour:dark ? highlight : accent)).draw(t)
}
func lift(_ box:CGRect,t:Double,from a:Double,side:CGFloat=0,_ paint:()->Void) {
 let p=still ? 1 : outCubic(prog(t,a,a+0.55))
 ctx.saveGState();ctx.translateBy(x:box.midX+side*CGFloat(1-p),y:box.midY+100*CGFloat(1-p));let z=CGFloat(0.88+0.12*p);ctx.scaleBy(x:z,y:z);ctx.translateBy(x:-box.midX,y:-box.midY);paint();ctx.restoreGState()
}
func label(_ s:String,t:Double,from a:Double,to b:Double,at c:CGPoint=CGPoint(x:520,y:570),dark:Bool=false) {
 guard t>=a && t<b else{return}
 sticker(s,at:c,fill:dark ? highlight : accent,ink:dark ? ink : paper,face:.system(.semibold),size:38,degrees:0,p:still ? 1 : prog(t,a,a+0.25))
}
func rays(_ t:Double,from a:Double,at c:CGPoint,colour:Col) {
 let p=still ? 0.5 : prog(t,a,a+0.65)
 guard p>0 && p<1 else{return}
 for i in 0..<10 {let ang=Double(i)*Double.pi/5;let r=60+170*p
  let q=CGPoint(x:c.x+CGFloat(cos(ang)*r),y:c.y+CGFloat(sin(ang)*r))
  line(q,CGPoint(x:q.x+CGFloat(cos(ang))*20,y:q.y+CGFloat(sin(ang))*20),colour.alpha(CGFloat(1-p)),7)
 }
}
func drawnArrow(_ pts:[CGPoint],t:Double,from a:Double,colour:Col) {
 let p=still ? 1 : prog(t,a,a+0.7);stroke(partial(pts,p),colour,7)
 if p>=1,let z=pts.last {let q=pts[pts.count-2],ang=atan2(z.y-q.y,z.x-q.x)
  for o in [-0.55,0.55] {line(z,CGPoint(x:z.x-26*cos(ang+o),y:z.y-26*sin(ang+o)),colour,7)}
 }
}
func phone(_ screen:Screenshot,in box:CGRect,t:Double,from a:Double,side:CGFloat=0) {
 lift(box,t:t,from:a,side:side){drawScreen(screen,in:box,radius:38)}
}
func focus(_ screen:Screenshot,region:CGRect,in box:CGRect,t:Double,from a:Double) {
 ScreenMove(screen,[(a,screen.bounds),(a+0.65,region)]).draw(still ? a+1 : t,in:box,radius:32)
}
