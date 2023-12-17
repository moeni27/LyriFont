
import oscP5.*;
import netP5.*;
import ddf.minim.*;
import ddf.minim.analysis.*;

Minim minim;
AudioPlayer song;  
int frameLength = 1024;
AgentFeature feat;

PFont font;


// Feature Variables
float ener;
float entr;
float cnt;
float spr;

int rectX, rectY;      // Position of square button
int rectSize = 90;     // Diameter of rect
color rectColor;
color rectHighlight;
boolean rectOver = false;

PImage uploadButton;
int chooseX, chooseY;
int chooseSize = 90;
//color chooseColor;
//color chooseHighlight;
boolean chooseOver = false;

OscP5 oscP5;
OscP5 oscP52;
NetAddress myRemoteLocation;

String filepath;
String text = "";
Object[] timestamps;
Object[] lrc;
int currentLine = -1;
boolean playing = false;
boolean firstPlay = true;
boolean songChosen = false;
int startTime = 0;
int elapsedTime = 0;
int restartTime = 0;


String getCurrentLine(Object[] timestamps, Object[] lines) {
    int current_time = millis()-startTime+elapsedTime;

    if (current_time > song.length()) {
      print(song.length());
      if(playing){
        song.pause();
        playing = false;
       }
      startTime = 0;
      elapsedTime = 0;
      restartTime = 0;
      currentLine = 0;
      song.cue(0);
      return "";
    }
    
    if(current_time > Integer.parseInt(timestamps[min(currentLine+1, timestamps.length-1)].toString())){
      currentLine = min(currentLine+1, lines.length-1);
    }
    if(currentLine==0&&current_time<Integer.parseInt(timestamps[0].toString())) {
      return "";
    } else {
      return lines[currentLine].toString();
    }
  }

void setup() {
  size(1500,500);
  //print(a.getAbsolutePath());
  frameRate(25);
  rectColor = color(255);
  rectHighlight = color(204);
  rectX = 20;
  rectY = 20;
  
  uploadButton = loadImage("cloud-upload.png");  
  chooseX = width-chooseSize-20;
  chooseY = 20;
  //chooseColor = color(255,0,0);
  //chooseHighlight = color(127,0,0);
  
  font = createFont("../RubikDoodleShadow-Regular.ttf", 38);
  
  minim = new Minim(this);
  
  oscP5 = new OscP5(this,1234);
  oscP52 = new OscP5(this,1234);
  myRemoteLocation = new NetAddress("127.0.0.1", 5005);
}

void draw() {
  background(0);
  update(); 
  
  if (songChosen) {
  feat.reasoning(song.mix);  
   
  entr = feat.entropy;
  ener = feat.energy/1000;
  cnt = feat.centroid/1000;
  spr = feat.spread/1000;
  
    if (currentLine > -1 && playing) {
      text = getCurrentLine(timestamps, lrc);
    }
  }
  
  textAlign(CENTER, CENTER);
  textFont(font);
  if(firstPlay || text=="Ready!"){textSize(64);fill(255);}
  else{
    textSize(map(entr,0,100,60,64));
    fill(map(ener,0,10,0,255),map(cnt,0,10,0,255),map(spr,0,10,0,255));
    }
  text(text, width/2, height/2); 
  
  if (rectOver) {
    fill(rectHighlight);
  } else {
    fill(rectColor);
  }
  stroke(255);
  rect(rectX, rectY, rectSize, rectSize);
  
  //if (chooseOver) {
  //  fill(chooseHighlight);
  //} else {
  //  fill(chooseColor);
 // }
 // rect(chooseX, chooseY, chooseSize, chooseSize);
  
  
  // upload button
  if (mouseX > chooseX && mouseX < chooseX + chooseSize &&
      mouseY > chooseY && mouseY < chooseY + chooseSize) {
    tint(200, 200); // Dim the button when the mouse is over it
  } else {
    noTint();
  }
  
  // Draw the upload button image
  image(uploadButton, chooseX, chooseY, chooseSize, chooseSize);
} 
 
  
void update() {
  if ( overRect(rectX, rectY, rectSize, rectSize) ) {
    rectOver = true;
  } else {
    rectOver = false;
  }
  
  if ( overRect(chooseX, chooseY, chooseSize, chooseSize) ) {
    chooseOver = true;
  } else {
    chooseOver = false;
  }
}

void reset() {
  songChosen = false;
   if(playing){
        song.pause();
        playing = false;
   }
  firstPlay = true;
  startTime = 0;
  elapsedTime = 0;
  restartTime = 0;
  currentLine = 0;
  text = "";
}

void fileSelected(File selection) {
  if (selection == null) {
    println("Window was closed or the user hit cancel.");
  } else {
    filepath = selection.getPath();
    println("User selected " + selection.getPath());
    reset();
    loadSong();
  }
}

void loadSong() {
   song = minim.loadFile(filepath, frameLength);  
   feat = new AgentFeature(song.bufferSize(), song.sampleRate());
   songChosen = true;
}

void mousePressed() {
  if (rectOver) { 
    if(firstPlay&&songChosen){
        text = "Loading Lyrics";
        OscMessage myMessage = new OscMessage("/load");
        myMessage.add(filepath);
        oscP5.send(myMessage, myRemoteLocation); 
      }
    else if (songChosen) {
      if(playing){
        song.pause();
        elapsedTime = millis()-startTime+restartTime;
        restartTime = elapsedTime;
        playing = false;
      }
      else{
        song.play();
        startTime = millis();
        playing = true;
      }
    }
  } else {
      if (chooseOver) {
        selectInput("Select a file to process:", "fileSelected");
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
   }
   
  if(theOscMessage.checkAddrPattern("/lyrics")==true) {
      firstPlay = false;
      lrc = theOscMessage.arguments();
      text = "Ready!";
      currentLine = 0;
   }
   
  if(theOscMessage.checkAddrPattern("/fontchange")==true) {
      //change font
   }
}
