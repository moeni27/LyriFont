
import oscP5.*;
import netP5.*;
import ddf.minim.*;
import ddf.minim.analysis.*;

Minim minim;
AudioPlayer song;  
int frameLength = 1024;
AgentFeature feat;

int rectX, rectY;      // Position of square button
int rectSize = 90;     // Diameter of rect
color rectColor;
color rectHighlight;
boolean rectOver = false;
OscP5 oscP5;
OscP5 oscP52;
NetAddress myRemoteLocation;

String text = "";
Object[] timestamps;
Object[] lrc;

boolean playing = false;
boolean firstPlay = true;

void setup() {
  size(1500,500);
  frameRate(25);
  
  rectColor = color(255);
  rectHighlight = color(204);
  rectX = 20;
  rectY = 20;
  
  minim = new Minim(this);
  song = minim.loadFile("../The Beatles - A Hard Day's Night.mp3",frameLength);  
  feat = new AgentFeature(song.bufferSize(), song.sampleRate());
   
  
  oscP5 = new OscP5(this,1234);
  oscP52 = new OscP5(this,1234);
  myRemoteLocation = new NetAddress("127.0.0.1", 5005);
}

void draw() {
  feat.reasoning(song.mix);  
  
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
    if(firstPlay){
        text = "Loading Lyrics";
        OscMessage myMessage = new OscMessage("/load");
        oscP5.send(myMessage, myRemoteLocation);   
      }
    else{
      if(playing){
        song.pause();
        // stop lyrics
        playing = false;
      }
      else{
        song.play();
        // play lyrics
        playing = true;
      }
    }
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
  
  if(theOscMessage.checkAddrPattern("/timestamps")==true) {
      timestamps = theOscMessage.arguments();
      
      // For Debugging
      //for (Object item : lrc) {
      //  println(item);
      //}
   }
   
  if(theOscMessage.checkAddrPattern("/lyrics")==true) {
      firstPlay = false;
      Object[] lrc = theOscMessage.arguments();
      
      // For Debugging
      //for (Object item : lrc) {
      //  println(item);
      //}
        
      // start lyrics and song
      // song.play();
      // playing = true;
   }
   
  if(theOscMessage.checkAddrPattern("/fontchange")==true) {
      //change font
   }
}
