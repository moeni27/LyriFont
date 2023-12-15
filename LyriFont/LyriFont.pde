
import oscP5.*;
import netP5.*;
String value1;
String value2;

// To forskellige OSC objekter, til at sende hver deres besked:
OscP5 oscP5;
OscP5 oscP52;
NetAddress myRemoteLocation;

String text = "Ok";

void setup() {
  size(1500,500);
  frameRate(25);
  oscP5 = new OscP5(this,1234);
  oscP52 = new OscP5(this,1234);
  myRemoteLocation = new NetAddress("127.0.0.1", 5005);
}

void draw() {
  background(0);
  textSize(64);
  text(text, 40, 120); 
}
  
void oscEvent(OscMessage theOscMessage) {
  // Således ser det ud for modtagelse af kun én OSC besked:
  text = theOscMessage.get(0).stringValue();
  
  if(theOscMessage.checkAddrPattern("/fontchange")==true) {
      //change font
   }
}
