
import oscP5.*;
import netP5.*;
import ddf.minim.*;
import ddf.minim.analysis.*;

Minim minim;
AudioPlayer song;  
int frameLength = 1024;
AgentFeature feat;
AudioMetaData meta;

PFont font;

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
String text = "Load a song to start";
String metaTitle;
String metaArtist;
float txtSize = 64;
float txtColor = 50;
Object[] timestamps;
Object[] lrc;
Object[] fontPython;
int currentLine = -1;
boolean playing = false;
boolean firstPlay = true;
boolean songChosen = false;
int startTime = 0;
int elapsedTime = 0;
int restartTime = 0;
PImage playimg;
PImage pauseimg;
PImage pyimg;
float max_distance;
//ArrayList<String> receivedLyrics = new ArrayList<>();
ArrayList<Object> dynamicLyric;
ArrayList<Object> dynamicTime;

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
  
String[] splitTextIntoLines(String input, float lineWidth) {
  String[] words = input.split("\\s+");
  StringBuilder currentLine = new StringBuilder();
  ArrayList<String> lines = new ArrayList<>();

  for (String word : words) {
    if (textWidth(currentLine + word) <= lineWidth) {
      currentLine.append(word).append(" ");
    } else {
      lines.add(currentLine.toString().trim());
      currentLine = new StringBuilder(word + " ");
    }
  }

  if (currentLine.length() > 0) {
    lines.add(currentLine.toString().trim());
  }

  return lines.toArray(new String[0]);
}

void setup() {
  size(1500,500);
  max_distance = dist(0, 0, width, height);
  frameRate(25);
  playimg = loadImage("play.png");
  pauseimg = loadImage("pause.png");
  pyimg = loadImage("python.png");
  rectColor = color(255);
  rectHighlight = color(204);
  rectX = 20;
  rectY = 20;
  
  dynamicLyric = new ArrayList<Object>();
  dynamicTime = new ArrayList<Object>();
  
  uploadButton = loadImage("cloud-upload.png");  
  chooseX = width-chooseSize-20;
  chooseY = 20;
  //chooseColor = color(255,0,0);
  //chooseHighlight = color(127,0,0);
  
  font = createFont("Georgia", 38);
  
  minim = new Minim(this);
  
  oscP5 = new OscP5(this,1234);
  oscP52 = new OscP5(this,1234);
  myRemoteLocation = new NetAddress("127.0.0.1", 5005);
}

void draw() {
  background(0);
  update(); 
   
  for(int i = 0; i <= width; i += 20) {
    if ((i >= 0 && i <= width / 8) || (i >= (width * 7) / 8 && i <= width)) {
      for(int j = 0; j <= height; j += 20) {
        
        if (playing) {
          float size = dist(width/2, height/2, i, j);
          size = size*map(energyMapping(feat.energy), 0, 66, 0, 0.1)/max_distance*66;
          colorMode(HSB, 360, 100, 100);
          fill(centroidMapping(feat.centroid), 100, 100);
          ellipse(i, j, size, size);
          colorMode(RGB, 255, 255, 255);
        } else {
          float size = dist(width/2, height/2, i, j);
          size = size/(max_distance*2)*10;
          ellipse(i, j, size, size);
        }
        
      }
    }
  }
  
  if (songChosen) {
  feat.reasoning(song.mix);  
   
  // Calculate text settings from audio features
  txtSize = entropyMapping(feat.entropy);
  txtColor = centroidMapping(feat.centroid);
  
    if (currentLine > -1 && playing) {
      text = getCurrentLine(timestamps, lrc);
    }
  }
  
  
/*  
textAlign(CENTER, CENTER);
textFont(font);
    if(firstPlay || text=="Ready!"){
      colorMode(RGB);
      fill(255,255,255);
      textSize(64);
      text(text, width/2, height/2);
  }
    else{
      if (playing) {
        // Check if the length of the text is greater than 30
        if (text.length() > 30) {
            int middleIndex = text.length() / 2;
            int lastSpaceIndex = text.lastIndexOf(' ', middleIndex);
        
            // Check space
            if (lastSpaceIndex != -1) {
                String firstLine = text.substring(0, lastSpaceIndex);
                String secondLine = text.substring(lastSpaceIndex + 1);
                // Glow Effect
                textSize(txtSize+2);
                colorMode(HSB, 360, 100, 100);
                fill(txtColor,100,100);
                text(firstLine, width / 2, height / 2 - 20); 
                text(secondLine, width / 2, height / 2 + 20); 
                filter(BLUR, 1);
                
                // Lyrics
                textSize(txtSize);
                colorMode(RGB, 255, 255, 255);
                fill(255,255,255);
                text(firstLine, width / 2, height / 2 - 20); 
                text(secondLine, width / 2, height / 2 + 20); 
            } else {
                // Glow Effect
                textSize(txtSize+2);
                colorMode(HSB, 360, 100, 100);
                fill(txtColor,100,100);
                text(text, width/2, height/2); 
                filter(BLUR, 1);
                
                // Lyrics
                textSize(txtSize);
                colorMode(RGB, 255, 255, 255);
                fill(255,255,255);
                text(text, width / 2, height / 2);
            }
          } else {
            // Display the text as a single line
            
            // Glow Effect
            textSize(txtSize+2);
            colorMode(HSB, 360, 100, 100);
            fill(txtColor,100,100);
            text(text, width / 2, height / 2); 
            filter(BLUR, 1);
            
            // Lyrics 
            textSize(txtSize);
            colorMode(RGB, 255, 255, 255);
            fill(255,255,255);
            text(text, width / 2, height / 2);
          }
      } else {
        fill(0,0,0);
      }
    }
    
 */
 
textAlign(CENTER, CENTER);
textFont(font);

float lineVerticalSpacing = 10; 

if (firstPlay || text == "Ready!") {
  colorMode(RGB);
  fill(255, 255, 255);
  textSize(64);
  text(text, width / 2, height / 2);
} else {
  if (playing) {
    float textWidthWithMargin = textWidth(text) + 1200; 
    if (textWidthWithMargin > width) {
      String[] lines = splitTextIntoLines(text, width - 1200); 
      
      // Glow Effect
      textSize(txtSize + 2);
      colorMode(HSB, 360, 100, 100);
      fill(txtColor, 100, 100);

      float lineHeight = 40; 
      for (int i = 0; i < lines.length; i++) {
        float y = height / 2 - (lines.length - 1) * (lineHeight + lineVerticalSpacing) / 2 + i * (lineHeight + lineVerticalSpacing);
        text(lines[i], width / 2, y);
      }
      filter(BLUR, 1);

      // Lyrics
      textSize(txtSize);
      colorMode(RGB, 255, 255, 255);
      fill(255, 255, 255);

      for (int i = 0; i < lines.length; i++) {
        float y = height / 2 - (lines.length - 1) * (lineHeight + lineVerticalSpacing) / 2 + i * (lineHeight + lineVerticalSpacing);
        text(lines[i], width / 2, y);
      }
    } else {
      // Glow Effect
      textSize(txtSize + 2);
      colorMode(HSB, 360, 100, 100);
      fill(txtColor, 100, 100);
      text(text, width / 2, height / 2);
      filter(BLUR, 1);

      // Lyrics
      textSize(txtSize);
      colorMode(RGB, 255, 255, 255);
      fill(255, 255, 255);
      text(text, width / 2, height / 2);
    }
  } else {
    fill(0, 0, 0);
  }
}
  
  if (rectOver) {
    fill(rectHighlight);
  } else {
    fill(rectColor);
  }
  stroke(255);
  rect(rectX, rectY, rectSize, rectSize);
  
  if (!firstPlay&&!playing) {
  image(playimg, rectX+rectSize/4, rectY+rectSize/4, rectSize/2, rectSize/2);
  } else {
    if (playing) {
        image(pauseimg, rectX+rectSize/4, rectY+rectSize/4, rectSize/2, rectSize/2);
    }
  }
  
  if (firstPlay) {
      image(pyimg, rectX+rectSize/4, rectY+rectSize/4, rectSize/2, rectSize/2);
  }
  
  // upload button
  if (mouseX > chooseX && mouseX < chooseX + chooseSize &&
      mouseY > chooseY && mouseY < chooseY + chooseSize) {
    tint(200); // Dim the button when the mouse is over it
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
  dynamicTime.clear();
  dynamicLyric.clear();
  startTime = 0;
  elapsedTime = 0;
  restartTime = 0;
  currentLine = 0;
  text = "";
  font = createFont("Georgia", 38);
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
   
   meta = song.getMetaData();
   metaTitle = meta.title();
   metaArtist =  meta.author();
   println("Title: " + metaTitle);
   println("Artist: " + metaArtist);
   text = "Song loaded!";
}


void mousePressed() {
  if (rectOver) { 
    if(firstPlay&&songChosen){
        text = "Fetching lyrics . . .";
        OscMessage myMessage = new OscMessage("/load");
        if (metaArtist == "" || metaTitle == ""){
            myMessage.add(filepath);
          }
        else {
            myMessage.add(metaArtist + " - " + metaTitle+".mp3");
        }
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
      for (int i = 0; i < theOscMessage.arguments().length; i++) {
        if (theOscMessage.arguments()[i] instanceof Integer) {
          dynamicTime.add(theOscMessage.arguments()[i]);
        }
      }
      timestamps = dynamicTime.toArray();    
   }
   
  if (theOscMessage.checkAddrPattern("/lyrics") == true) {
      for (int i = 0; i < theOscMessage.arguments().length; i++) {
        if (theOscMessage.arguments()[i] instanceof String) {
          dynamicLyric.add(theOscMessage.arguments()[i]);
        }
      }
      lrc = dynamicLyric.toArray();
      
      firstPlay = false;
      currentLine = 0;
   }
   
  if(theOscMessage.checkAddrPattern("/fontchange")==true) {
      fontPython = theOscMessage.arguments();
      println(fontPython[0].toString());
      font = createFont("Font/" + fontPython[0].toString(), 38);
      text = "Ready!";
   }
}
// Features Functions 
 
// Entropy goes approximately from  0 (usually only when there is silence, otherwise it has a minimum value between around 50 and 200) to a maximum around 800/1000.
// 
float entropyMapping(float entropy){
  float output = 64;
  if (0 < entropy && entropy <= 200){output = map(entropy,0,200,63,63.5);}
  else if (200 < entropy && entropy <= 400){output = map(entropy,200,400,63.5,64);}
  else if (400 < entropy && entropy <= 600){output = map(entropy,400,600,64,64.5);}
  else if (600 < entropy && entropy <= 800){output = map(entropy,600,800,64.5,65);}
  else if (800 < entropy){output = map(entropy,800,1000,65,66);}
  return output;
}
// Centroid is more stable than Energy and mantains values from around 1000/2000 to 5000/6000
// TO DO BETTER
float centroidMapping(float centroid){
  float output = 50;
  if (1000 < centroid && centroid <= 2000){output = map(centroid,1000,2000,0,10);}
  else if (2000 < centroid && centroid <= 3000){output = map(centroid,2000,3000,10,20);}
  else if (3000 < centroid && centroid <= 4000){output = map(centroid,3000,4000,20,30);}
  else if (5000 < centroid && centroid <= 6000){output = map(centroid,4000,6000,30,50);}
  else if (6000 < centroid){output = map(centroid,6000,10000,50,100);}
  return output;
}
//Energy mantains very high values that changes dramatically during the song. They goes from a minimum around 1000 to a maximum around 40000/50000
// TO DO
float energyMapping(float energy){
  float output = 64;
  if (0 < energy && energy <= 200){output = map(energy,0,200,63,63.5);}
  else if (200 < energy && energy <= 400){output = map(energy,200,400,63.5,64);}
  else if (400 < energy && energy <= 600){output = map(energy,400,600,64,64.5);}
  else if (600 < energy && energy <= 800){output = map(energy,600,800,64.5,65);}
  else if (800 < energy){output = map(energy,800,1000,65,66);}
  return output;
}
// Spread behaves more or less as the Centroid
// TO DO
float spreadMapping(float spread){
  float output = 64;
  if (0 < spread && spread <= 200){output = map(spread,0,200,63,63.5);}
  else if (200 < spread && spread <= 400){output = map(spread,200,400,63.5,64);}
  else if (400 < spread && spread <= 600){output = map(spread,400,600,64,64.5);}
  else if (600 < spread && spread <= 800){output = map(spread,600,800,64.5,65);}
  else if (800 < spread){output = map(spread,800,1000,65,66);}
  return output;
}
