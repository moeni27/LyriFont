
import oscP5.*;
import netP5.*;

int rectX, rectY;      // Position of square button
int rectSize = 90;     // Diameter of rect
color rectColor;
color rectHighlight;
boolean rectOver = false;
OscP5 oscP5;
OscP5 oscP52;
NetAddress myRemoteLocation;

String text = "";

void setup() {
  size(1500,500);
  frameRate(25);
  
  rectColor = color(255);
  rectHighlight = color(204);
  rectX = 20;
  rectY = 20;
  
  oscP5 = new OscP5(this,1234);
  oscP52 = new OscP5(this,1234);
  myRemoteLocation = new NetAddress("127.0.0.1", 5005);
}

void draw() {
  update(mouseX, mouseY);  
  background(0);
  
  textSize(64);
  textAlign(CENTER, CENTER);
  text(text, width/2, height/2); 
  
  if (rectOver) {
    fill(rectHighlight);
  } else {
    fill(rectColor);
  }
  stroke(255);
  rect(rectX, rectY, rectSize, rectSize);
}
  
  
void update(int x, int y) {
  if ( overRect(rectX, rectY, rectSize, rectSize) ) {
    rectOver = true;
  } else {
    rectOver = false;
  }
}

void mousePressed() {
  if (rectOver) {
    text = "hi";
    OscMessage myMessage = new OscMessage("/stop");
    oscP5.send(myMessage, myRemoteLocation);
  }
}

boolean overRect(int x, int y, int width, int height)  {
  if (mouseX >= x && mouseX <= x+width && 
      mouseY >= y && mouseY <= y+height) {
    return true;
  } else {
    return false;
  }
}
  
void oscEvent(OscMessage theOscMessage) {
  
  if(theOscMessage.checkAddrPattern("/lyric")==true) {
      text = theOscMessage.get(0).stringValue();
   }
  
  if(theOscMessage.checkAddrPattern("/fontchange")==true) {
      //change font
   }
}
