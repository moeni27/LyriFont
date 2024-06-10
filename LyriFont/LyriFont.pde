/*
LyriFont is an interactive tool that transforms song lyrics into genre-specific text, offering users a multi-sensory, 360° experience. 

This script is used for the realization of the visual part. 
It is responsible for displaying the lyrics and the generated images and for all the graphics effects in the background, such that the coloured dots on the sides or the interactive visual blobs. 
Furthermore, all the visual elements are dinamically connected with the audio features of the song that is played.

Usage : Lyrifont.py then needs to be run first. Once that the system is correctly listening on the localhost server and is waiting for osc messages, Lyrifont.pde can be run as well.
*/

// Import libraries
import oscP5.*;
import netP5.*;
import ddf.minim.*;
import ddf.minim.analysis.*;
import geomerative.*;
import java.io.File;

// Define all variables
File folder;

// Audio loading variables
Minim minim;
AudioPlayer song;
int frameLength = 1024;
AgentFeature feat;
AudioMetaData meta;

// Font variables
PFont font;
RShape grp;
RPoint[] points;
String GeomFont;

// Graphics variables
int rectX, rectY;      // Position of square button
int rectSize = 90;     // Diameter of rect
color rectColor;
color rectHighlight;
boolean rectOver = false;
boolean geomActive = false;
boolean polimiOver = false;

int geomX, geomY;      // Position of square button
int geomSize = 90;     // Diameter of rect
color geomColor;
color geomHighlight;
boolean geomOver = false;

PImage uploadButton;
PImage switchButton;

int chooseX, chooseY;
int chooseSize = 90;

int switchX, switchY;
int switchSize = 90;
//color chooseColor;
//color chooseHighlight;
boolean chooseOver = false;

// OSC variables
OscP5 oscP5;
OscP5 oscP52;
NetAddress myRemoteLocation;

// Lyrics variables
String filepath;
String text = "Load a song to start";
String metaTitle;
String metaArtist;
int metaDuration;
float txtSize = 64;
float txtColor = 50;
Object[] timestamps;
Object[] lrc;
Object[] fontPython;
Object[] keywords;
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
PImage geomimg;
PImage noVectimg;
float max_distance;
ArrayList<Object> dynamicLyric;
ArrayList<Object> dynamicTime;
ArrayList<Object> dynamicKey;
World world;
int a;
ArrayList<Blob> blobs = new ArrayList<Blob>();

// Background images variables
PImage img;
PImage polilogo;
float PARTICLE_SIZE = 5;
float RESOLUTION = 5;
float MAX_FORCE = 5;
float MIN_FORCE = 0;
float COUNTER = 0;
boolean DEAD = false;
ArrayList<Particle> particles = new ArrayList<Particle>();
int currentIndex = 0;
int displayDuration = 5000; // 5 seconds in milliseconds
int previousTime = 0;
String[] imageFiles;

boolean shouldDisplayImages = false;

//["Pop","Rock","Metal","Hiphop","Reggae","Blues","Classical","Jazz","Disco","Country"]
float[] genreColors = {320, 200, 0, 130, 110, 240, 40, 60, 285, 15};
int genre = 0;

// saves the lyric that needs to be displayed at the correct time in the song
String getCurrentLine(Object[] timestamps, Object[] lines) {
  int current_time = millis()-startTime+elapsedTime;

  if (current_time > song.length()) {
    print(song.length());
    if (playing) {
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

  if (current_time > Integer.parseInt(timestamps[min(currentLine+1, timestamps.length-1)].toString())) {
    currentLine = min(currentLine+1, lines.length-1);
  }
  if (currentLine==0&&current_time<Integer.parseInt(timestamps[0].toString())) {
    return "";
  } else {
    return lines[currentLine].toString();
  }
}

// Splits sentences to long for the window into multiple lines
String[] splitTextIntoLines(String input, float lineWidth) {
  String[] words = input.split("\\s+");
  StringBuilder currentLine = new StringBuilder();
  ArrayList<String> lines = new ArrayList<String>();

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

// Setup function
void setup() {
  
  // Graphic setup
  size(1500, 750);
  surface.setResizable(true);
  max_distance = dist(0, 0, width, height);
  frameRate(25);
  playimg = loadImage("play.png");
  pauseimg = loadImage("pause.png");
  pyimg = loadImage("python.png");
  polilogo = loadImage("polimilogo.png");
  geomimg = loadImage("geom.png");
  noVectimg = loadImage("noVectorize.png");
  rectColor = color(255);
  rectHighlight = color(204);
  rectX = 20;
  rectY = 20;
  
  // Geomerative stuff
  geomColor = color(255);
  geomHighlight = color(204);
  geomX = width - geomSize - 20;
  geomY = height - geomSize - 20;
  RG.init(this);
  grp = RG.getText(text, "FontDataset/Font/Silkscreen-Regular.ttf", 120, CENTER);

  // Lyrics variables
  dynamicLyric = new ArrayList<Object>();
  dynamicTime = new ArrayList<Object>();
  
  // Graphic setup
  uploadButton = loadImage("upload.png");
  chooseX = width-chooseSize-20;
  chooseY = 20;
  
  // Font variable
  font = createFont("Georgia", 38);
  
  // Audio variables
  minim = new Minim(this);
  oscP5 = new OscP5(this, 1234);
  oscP52 = new OscP5(this, 1234);
  myRemoteLocation = new NetAddress("127.0.0.1", 5005);

  // Mouse blobs variables
  world = new World(20);
  a = 0;
}

// Draw function
void draw() {
  max_distance = dist(0, 0, width, height);
  chooseX = width-chooseSize-20;
  geomX = width - geomSize - 20;
  geomY = height - geomSize - 20;
  background(0);
  
  // controls blob population
  if (playing) {
    world.run(genreColors[genre]+centroidMapping(feat.centroid), spreadMapping(feat.spread), skewnessMapping(feat.skewness));
  } else {
    world.run(200,1,0);
  }
  //new one every 15 frames
  a = a + 1;
  if (a == 15) {
    world.born(random(width/8, width-width/8), random(height));
    a = 0;
  }
  // Check if shouldDisplayImages is true to display images
  if (shouldDisplayImages&&playing) {
    for (Particle obj : particles) {
      obj.update(flatnessMapping(feat.flatness));
      obj.draw();
    }

    displayDuration = metaDuration*50;

    //makes image fade out
    if (millis()-startTime+elapsedTime - previousTime >= displayDuration-1000&&!DEAD) {
      DEAD = true;
    }

    if (millis()-startTime+elapsedTime - previousTime >= displayDuration) {
      // Move to the next image after a certain amount of time
      currentIndex = (currentIndex + 1) % imageFiles.length;
      loadImageFromIndex(currentIndex);
      spawnParticles();
      previousTime = millis()-startTime+elapsedTime; // Update the time
    }
  }
  update();

  // draw the responsive dot grid on the sides of the window
  for (int i = 0; i <= width; i += 20) {
    if ((i >= 0 && i <= width / 8) || (i >= (width * 7) / 8 && i <= width)) {
      for (int j = 0; j <= height; j += 20) {

        if (playing) {
          float size = dist(width/2, height/2, i, j);
          // connect their size with the music's energy feature
          size = size*map(energyMapping(feat.energy), 0, 66, 0, 0.1)/max_distance*66;
          colorMode(HSB, 360, 100, 100);
          // color controlled by centroid and skew
          fill(genreColors[genre]+centroidMapping(feat.centroid), 100-skewnessMapping(feat.skewness), 100);
          stroke(0);
          ellipse(i, j, size, size);
          colorMode(RGB, 255, 255, 255);
        } else {
          float size = dist(width/2, height/2, i, j);
          size = size/(max_distance*2)*10;
          colorMode(HSB, 360, 100, 100);
          // color changes periodically when music isn't playing
          fill(360*abs(cos(millis()*0.0001)), 100, 100);
          stroke(0);
          ellipse(i, j, size, size);
          colorMode(RGB, 255, 255, 255);
        }
      }
    }
  }


  if (songChosen) {
    feat.reasoning(song.mix);
    // Calculate text settings from audio features
    txtSize = entropyMapping(feat.entropy);
    txtColor = genreColors[genre]+centroidMapping(feat.centroid);

    if (currentLine > -1 && playing) {
      text = getCurrentLine(timestamps, lrc);
    }
  }


  textAlign(CENTER, CENTER);
  textFont(font);

  float lineVerticalSpacing = 50;
  float margin = 900;

  if (firstPlay || text == "Ready!") {
    colorMode(RGB);
    fill(255, 255, 255);
    textSize(64);
    text(text, width / 2, height / 2);
  } else {
    if (playing) {
      if (!geomActive) {
        float textWidthWithMargin = textWidth(text) + margin;
        if (textWidthWithMargin > width) {
          String[] lines = splitTextIntoLines(text, width - margin);

          // shadow
          textSize(txtSize + 2);
          colorMode(HSB, 360, 100, 100);
          fill(txtColor, 100-skewnessMapping(feat.skewness), 100);

          float lineHeight = 40;
          for (int i = 0; i < lines.length; i++) {
            float y = height / 2 - (lines.length - 1) * (lineHeight + lineVerticalSpacing) / 2 + i * (lineHeight + lineVerticalSpacing);
            text(lines[i], width / 2, y);
          }

          // Lyrics
          textSize(txtSize);
          colorMode(RGB, 255, 255, 255);
          fill(255, 255, 255);

          for (int i = 0; i < lines.length; i++) {
            float y = height / 2 - (lines.length - 1) * (lineHeight + lineVerticalSpacing) / 2 + i * (lineHeight + lineVerticalSpacing);
            text(lines[i], width / 2, y);
          }
        } else {
          // shadow
          textSize(txtSize + 2);
          colorMode(HSB, 360, 100, 100);
          fill(txtColor, 100-skewnessMapping(feat.skewness), 100);
          text(text, width / 2, height / 2);

          // Lyrics
          textSize(txtSize);
          colorMode(RGB, 255, 255, 255);
          fill(255, 255, 255);
          text(text, width / 2, height / 2);
        }
      } else {
        colorMode(RGB, 255, 255, 255);
        fill(255, 255, 255);
        translate(width/2, 10);
        textShapesEffect();
        translate(-width/2, -10);
      }
    } else {
      fill(0, 0, 0);
    }
  }
  
  // code for correct button control
  
  if (polimiOver) {
    fill(rectHighlight);
  } else {
    fill(rectColor);
  }
  
  stroke(255);
  rect(rectX, height-rectY-rectSize, rectSize, rectSize, 28);
  image(polilogo, rectX+(rectSize-rectSize/1.1), height-rectY-rectSize+(rectSize-rectSize/1.1), rectSize/1.2, rectSize/1.2);
  
  if (rectOver) {
    fill(rectHighlight);
  } else {
    fill(rectColor);
  }

  stroke(255);
  rect(rectX, rectY, rectSize, rectSize, 28);

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


  if (geomOver) {
    fill(geomHighlight);
  } else {
    fill(geomColor);
  }
  stroke(255);
  rect(geomX, geomY, geomSize, geomSize, 28);

  if (!geomActive) {
    image(noVectimg, geomX-22, geomY-14, geomSize+42, geomSize+15);
  } else {
    image(geomimg, geomX-8, geomY+1, geomSize+17, geomSize-1);
  }

  // upload button
  if (mouseX > chooseX && mouseX < chooseX + chooseSize &&
    mouseY > chooseY && mouseY < chooseY + chooseSize) {
    fill(geomHighlight);
  } else {
    fill(geomColor);
  }

  // Draw the upload button image
  stroke(255);
  rect(chooseX, chooseY, chooseSize, chooseSize, 28);
  image(uploadButton, chooseX, chooseY, chooseSize, chooseSize);

}

// Loads images from index
void loadImageFromIndex(int index) {
  String imagePath = "Images/" + imageFiles[index];
  img = loadImage(imagePath);
}

// create the particle grid that represents the loaded image
void spawnParticles() {
  DEAD = false;
  COUNTER=0;
  particles.clear(); // Clear previous particles
  float offset = PARTICLE_SIZE/2;
  // select random center of attraction
  PVector randomTarget = new PVector(random(-(width*3)/8+img.width/2+PARTICLE_SIZE, (width*3)/8-img.width/2-PARTICLE_SIZE), random(-height/2+img.height/2, height/2-img.height/2));
  // create the grid
  for (int i = 0; i < img.width; i += RESOLUTION) {
    for (int j = 0; j < img.height; j += RESOLUTION) {
      // get color of the pixel assigned to the particle
      color c = img.get(i, j);
      particles.add(new Particle(i + (width / 2 - img.width / 2) + offset, j + (height / 2 - img.height / 2) + offset, c, randomTarget));
    }
  }
}


// Clear Images Folder when selecting a new song
void clearFolder() {
  // Specify the folder path you want to clear
  String folderPath = sketchPath("Images");

  // Initialize the folder
  folder = new File(folderPath);

  // Check if the folder exists
  if (folder.exists() && folder.isDirectory()) {
    // Get list of files in the folder
    File[] files = folder.listFiles();

    // Delete each file in the folder
    for (File file : files) {
      file.delete();
    }
    println("Folder cleared successfully.");
  } else {
    println("Folder does not exist or is not a directory.");
  }
}

// Update button state function
void update() {
  if ( overRect(rectX, rectY, rectSize, rectSize) ) {
    rectOver = true;
  } else {
    rectOver = false;
  }
  
    if ( overRect(rectX, height-rectY-rectSize, rectSize, rectSize) ) {
    polimiOver = true;
  } else {
    polimiOver = false;
  }

  if ( overRect(chooseX, chooseY, chooseSize, chooseSize) ) {
    chooseOver = true;
  } else {
    chooseOver = false;
  }

  if ( overRect(geomX, geomY, geomSize, geomSize) ) {
    geomOver = true;
  } else {
    geomOver = false;
  }
}

// Reset Function
void reset() {
  songChosen = false;
  if (playing) {
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
  previousTime = 0;
  text = "";
  font = createFont("Georgia", 38);
}

// Actions after file is selected
void fileSelected(File selection) {
  if (selection == null) {
    println("Window was closed or the user hit cancel.");
  } else {
    shouldDisplayImages = false;
    filepath = selection.getPath();
    println("User selected " + selection.getPath());
    reset();
    clearFolder();
    loadSong();
  }
}

// Load song and retrieves metadata
void loadSong() {
  song = minim.loadFile(filepath, frameLength);
  feat = new AgentFeature(song.bufferSize(), song.sampleRate());
  songChosen = true;

  meta = song.getMetaData();
  metaTitle = meta.title();
  metaArtist =  meta.author();
  metaDuration = song.length() / frameLength;
  println("Title: " + metaTitle);
  println("Artist: " + metaArtist);
  println("Duration: " +  String.valueOf(song.length() / frameLength) + "s");
  text = "Song loaded!";
}

// MousePressed function
void mousePressed() {
  if (rectOver) {
    if (firstPlay&&songChosen) {
      text = "Fetching lyrics . . .";
      OscMessage myMessage = new OscMessage("/load");
      if (metaArtist == "" || metaTitle == "") {
        myMessage.add(filepath);
      } else {
        myMessage.add(metaArtist + " - " + metaTitle+".mp3");
      }
      oscP5.send(myMessage, myRemoteLocation);
    } else if (songChosen) {
      shouldDisplayImages = !shouldDisplayImages;
      if (shouldDisplayImages) {
        // Load images from the folder when the boolean variable becomes true
        String folderPath = sketchPath("Images");
        File folder = new File(folderPath);
        if (!folder.exists() || !folder.isDirectory()) {
          println("Error: Images folder not found or is not a directory");
          return;
        }
        imageFiles = folder.list();
        if (imageFiles == null || imageFiles.length == 0) {
          println("Error: No image files found in the Images folder");
          return;
        }
        loadImageFromIndex(0);
        if(startTime==0){
          spawnParticles();
        }
      }
      if (playing) {
        song.pause();
        elapsedTime = millis()-startTime+restartTime;
        restartTime = elapsedTime;
        playing = false;
      } else {
        song.play();
        startTime = millis();
        playing = true;
      }
    }
  } else {
    if (mouseX>width/8 && mouseX<(width-width/8)) {
      world.born(float(mouseX), float(mouseY));
    }
    if (chooseOver) {
      if (playing&&songChosen) {
        song.pause();
        elapsedTime = millis()-startTime+restartTime;
        restartTime = elapsedTime;
        playing = false;
        shouldDisplayImages = false;
      }
      selectInput("Select a file to process:", "fileSelected");
    }
  }

  if (mouseX > geomX && mouseX < geomX + geomSize &&
    mouseY > geomY && mouseY < geomY + geomSize) {
    geomActive = !geomActive;
    println("Button pressed");
  }
  
  if (polimiOver){
    link("https://mae-creative-pc.github.io/");
  }
  
}

boolean overRect(int x, int y, int width, int height) {
  if (mouseX >= x && mouseX <= x+width &&
    mouseY >= y && mouseY <= y+height) {
    return true;
  } else {
    return false;
  }
}

// Handle osc event
void oscEvent(OscMessage theOscMessage) {

  if (theOscMessage.checkAddrPattern("/genre")==true) {
    genre = int(theOscMessage.arguments()[0].toString());
    print(genre);
  }
  
  if (theOscMessage.checkAddrPattern("/timestamps")==true) {
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

  if (theOscMessage.checkAddrPattern("/fontchange")==true) {
    fontPython = theOscMessage.arguments();
    println(fontPython[0].toString());
    GeomFont = "FontDataset/Font/" + fontPython[0].toString();
    font = createFont("FontDataset/Font/" + fontPython[0].toString(), 38);
    text = "Ready!";
  }

  if (theOscMessage.checkAddrPattern("/keywords") == true) {
    keywords = theOscMessage.arguments();
    println("Keywords:");
    println(keywords);
  }
}
// Mapping audio features functions 

// Entropy goes approximately from  0 (usually only when there is silence, otherwise it has a minimum value between around 50 and 200) to a maximum around 800/1000.
float entropyMapping(float entropy) {
  float output = 64;
  if (0 < entropy && entropy <= 200) {
    output = map(entropy, 0, 200, 63, 63.5);
  } else if (200 < entropy && entropy <= 400) {
    output = map(entropy, 200, 400, 63.5, 64);
  } else if (400 < entropy && entropy <= 600) {
    output = map(entropy, 400, 600, 64, 64.5);
  } else if (600 < entropy && entropy <= 800) {
    output = map(entropy, 600, 800, 64.5, 65);
  } else if (800 < entropy) {
    output = map(entropy, 800, 1000, 65, 66);
  }
  return output;
}

// Centroid is more stable than Energy and mantains values from around 1000/2000 to 5000/6000
float centroidMapping(float centroid) {
  float output = 0;
  if (1000 < centroid && centroid <= 2000) {
    output = map(centroid, 1000, 2000, -30, -20);
  } else if (2000 < centroid && centroid <= 3000) {
    output = map(centroid, 2000, 3000, -20, -10);
  } else if (3000 < centroid && centroid <= 4000) {
    output = map(centroid, 3000, 4000, -10, 0);
  } else if (5000 < centroid && centroid <= 6000) {
    output = map(centroid, 4000, 6000, 0, 20);
  } else if (6000 < centroid) {
    output = map(centroid, 6000, 10000, 20, 30);
  }
  return output;
}

//Energy mantains very high values that changes dramatically during the song. They goes from a minimum around 1000 to a maximum around 40000/50000
float energyMapping(float energy) {
  float output = 64;
  if (0 < energy && energy <= 200) {
    output = map(energy, 0, 200, 63, 63.5);
  } else if (200 < energy && energy <= 400) {
    output = map(energy, 200, 400, 63.5, 64);
  } else if (400 < energy && energy <= 600) {
    output = map(energy, 400, 600, 64, 64.5);
  } else if (600 < energy && energy <= 800) {
    output = map(energy, 600, 800, 64.5, 65);
  } else if (800 < energy) {
    output = map(energy, 800, 1000, 65, 66);
  }
  return output;
}

// Spread behaves more or less as the Centroid
float spreadMapping(float spread) {
  float output = 10;
  if (0 < spread && spread <= 200) {
    output = map(spread, 0, 200, 0, 5);
  } else if (200 < spread && spread <= 400) {
    output = map(spread, 200, 400, 5, 10);
  } else if (400 < spread && spread <= 600) {
    output = map(spread, 400, 600, 10, 12);
  } else if (600 < spread && spread <= 800) {
    output = map(spread, 600, 800, 12, 14);
  } else if (800 < spread) {
    output = map(spread, 800, 1000, 14, 15);
  }
  return output;
}

// Skew starts very low but then is in range -3 : 10 (usually 0:4)
float skewnessMapping(float skew) {
  float output = 0;
  if (0 < skew && skew <= 1) {
    output = map(skew, 0, 1, -5, -3);
  } else if (1 < skew && skew <= 5) {
    output = map(skew, 1, 5, -3, 3);
  } else if (5 < skew && skew <= 9) {
    output = map(skew, 5, 9, 3, 4);
  } else if (9 < skew) {
    output = map(skew, 9, 10, 4, 5);
  }
  return output;
}

// Flatness has a range of around 0-0.25
float flatnessMapping(float flatness) {
  float output = 1;
  if (0 < flatness && flatness <= 0.25) {
    output = map(flatness, 0, 0.25, 1, 1.25);
  } 
  return output;
}

// Text warping effect function
void textShapesEffect() {
  String[] lines = splitTextIntoLinesGeom(text, width - 900);
  float lineHeight = txtSize + 10; // Adjust the vertical spacing between lines as needed

  RG.setPolygonizer(RG.UNIFORMLENGTH);
  RG.setPolygonizerLength(map(energyMapping(feat.energy), 0, height, 0, 40));

  float totalTextHeight = lines.length * lineHeight;
  float yOffset = (height - totalTextHeight) / 2; // Calculate the vertical offset for centering

  for (int lineIndex = 0; lineIndex < lines.length; lineIndex++) {
    String line = lines[lineIndex];
    int vectorizeOffset = 12;
    grp = RG.getText(line, GeomFont, int(txtSize+4), CENTER);

    float lineY = vectorizeOffset + yOffset + lineIndex * (lineHeight+10) + totalTextHeight / 2 - (lines.length - 1) * lineHeight / 2;

    for (int j = 0; j < grp.countChildren(); j++) {
      points = grp.children[j].getPoints();
      // If there are any points
      if (points != null) {
        colorMode(HSB, 360, 100, 100);
        fill(txtColor, 100-skewnessMapping(feat.skewness), 100);
        beginShape();
        for (int i = 0; i < points.length; i++) {
          vertex(points[i].x, points[i].y + lineY);
        }
        endShape();
      }
    }

    grp = RG.getText(line, GeomFont, ceil(txtSize+1), CENTER);
    lineY = vectorizeOffset + yOffset + lineIndex * (lineHeight+10) + totalTextHeight / 2 - (lines.length - 1) * lineHeight / 2;

    for (int j = 0; j < grp.countChildren(); j++) {
      points = grp.children[j].getPoints();
      // If there are any points
      if (points != null) {
        colorMode(RGB, 255, 255, 255);
        fill(255, 255, 255);
        beginShape();
        for (int i = 0; i < points.length; i++) {
          vertex(points[i].x, points[i].y + lineY);
        }
        endShape();
      }
    }
  }
}

// Split sentences too long for the window in multiple lines for text warping
String[] splitTextIntoLinesGeom(String input, float lineWidth) {
  String[] words = input.split("\\s+");
  StringBuilder currentLine = new StringBuilder();
  ArrayList<String> lines = new ArrayList();

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

// MouseDragged function
void mouseDragged() {
  if (mouseX>width/8 && mouseX<(width-width/8)) {
    // generate blobs while holding down mouse button
    world.born(float(mouseX), float(mouseY));
  }
}
