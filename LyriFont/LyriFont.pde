
import oscP5.*;
import netP5.*;

OscP5 oscP5;
NetAddress myRemoteLocation;

String text = "Ok";

void setup() {
  size(1500,500);
  frameRate(25);
  oscP5 = new OscP5(this,1234);
  myRemoteLocation = new NetAddress("127.0.0.1", 5005);
}

void draw() {
  background(0);
  textSize(64);
  text(text, 40, 120); 
}
  
void oscEvent(OscMessage theOscMessage) {
  
  if(theOscMessage.checkAddrPattern("/lyric")==true) {
      text = theOscMessage.get(0).stringValue();
   }
  
  if(theOscMessage.checkAddrPattern("/fontchange")==true) {
      //change font
   }
}
