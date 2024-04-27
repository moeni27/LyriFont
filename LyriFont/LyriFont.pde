import oscP5.*;
import netP5.*;
import ddf.minim.*;
import ddf.minim.analysis.*;
import geomerative.*;
import java.io.File;

File folder;

Minim minim;
AudioPlayer song;
int frameLength = 1024;
AgentFeature feat;
AudioMetaData meta;

PFont font;
RShape grp;
RPoint[] points;
String GeomFont;


int rectX, rectY;      // Position of square button
int rectSize = 90;     // Diameter of rect
color rectColor;
color rectHighlight;
boolean rectOver = false;
boolean geomActive = false;

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

OscP5 oscP5;
OscP5 oscP52;
NetAddress myRemoteLocation;

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
//ArrayList<String> receivedLyrics = new ArrayList<>();
ArrayList<Object> dynamicLyric;
ArrayList<Object> dynamicTime;
ArrayList<Object> dynamicKey;
World world;
int a;
ArrayList<Blob> blobs = new ArrayList<Blob>();

// BACKGROUND IMAGES
PImage img;
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


void setup() {
  size(1500, 500);
  max_distance = dist(0, 0, width, height);
  frameRate(25);
  playimg = loadImage("play.png");
  pauseimg = loadImage("pause.png");
  pyimg = loadImage("python.png");
  geomimg = loadImage("geom.png");
  noVectimg = loadImage("noVectorize.png");
  rectColor = color(255);
  rectHighlight = color(204);
  rectX = 20;
  rectY = 20;


  geomColor = color(255);
  geomHighlight = color(204);
  geomX = width - geomSize - 20;
  geomY = height - geomSize - 20;


  // Geomerative stuff
  RG.init(this);
  grp = RG.getText(text, "/Font/Silkscreen-Regular.ttf", 120, CENTER);


  dynamicLyric = new ArrayList<Object>();
  dynamicTime = new ArrayList<Object>();

  uploadButton = loadImage("upload.png");
  chooseX = width-chooseSize-20;
  chooseY = 20;
  //chooseColor = color(255,0,0);
  //chooseHighlight = color(127,0,0);
  //switchButton = loadImage("switch.png");
  //switchX = width - switchSize - 20;
  //switchY = height - switchSize - 20;

  font = createFont("Georgia", 38);

  minim = new Minim(this);

  oscP5 = new OscP5(this, 1234);
  oscP52 = new OscP5(this, 1234);
  myRemoteLocation = new NetAddress("127.0.0.1", 5005);

  world = new World(20);
  a = 0;
}

void draw() {
  background(0);
  if (playing) {
    world.run(centroidMapping(feat.centroid));
  } else {
    world.run(200);
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
      obj.update();
      obj.draw();
    }
    //filter(GRAY);

    displayDuration = metaDuration*50;

    //makes image fade out
    if (millis()-startTime+elapsedTime - previousTime >= displayDuration-1000&&!DEAD) {
      DEAD = true;
      print(DEAD);
    }
    print("    "+str(millis()-startTime+elapsedTime - previousTime)+"   ");
    if (millis()-startTime+elapsedTime - previousTime >= displayDuration) {
      print("newpic");
      // Move to the next image after 5 seconds
      currentIndex = (currentIndex + 1) % imageFiles.length;
      loadImageFromIndex(currentIndex);
      spawnParticles();
      previousTime = millis()-startTime+elapsedTime; // Update the time
    }
  }
  update();

  for (int i = 0; i <= width; i += 20) {
    if ((i >= 0 && i <= width / 8) || (i >= (width * 7) / 8 && i <= width)) {
      for (int j = 0; j <= height; j += 20) {

        if (playing) {
          float size = dist(width/2, height/2, i, j);
          size = size*map(energyMapping(feat.energy), 0, 66, 0, 0.1)/max_distance*66;
          colorMode(HSB, 360, 100, 100);
          fill(centroidMapping(feat.centroid), 100, 100);
          stroke(0);
          ellipse(i, j, size, size);
          colorMode(RGB, 255, 255, 255);
        } else {
          float size = dist(width/2, height/2, i, j);
          size = size/(max_distance*2)*10;
          colorMode(HSB, 360, 100, 100);
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
    txtColor = centroidMapping(feat.centroid);

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

          // Glow Effect
          textSize(txtSize + 2);
          colorMode(HSB, 360, 100, 100);
          fill(txtColor, 100, 100);

          float lineHeight = 40;
          for (int i = 0; i < lines.length; i++) {
            float y = height / 2 - (lines.length - 1) * (lineHeight + lineVerticalSpacing) / 2 + i * (lineHeight + lineVerticalSpacing);
            text(lines[i], width / 2, y);
          }
          //filter(BLUR, 1);

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
          //filter(BLUR, 1);

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
        /*text(firstLine, width / 2, height / 2 - 20);
         text(secondLine, width / 2, height / 2 + 20);*/
        textShapesEffect();
        translate(-width/2, -10);
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
    tint(200); // Dim the button when the mouse is over it
  } else {
    noTint();
  }

  // Draw the upload button image
  rect(chooseX, chooseY, chooseSize, chooseSize, 28);
  image(uploadButton, chooseX, chooseY, chooseSize, chooseSize);


  //image(switchButton, switchX, switchY, switchSize, switchSize);
}

void loadImageFromIndex(int index) {
  String imagePath = "Images/" + imageFiles[index];
  img = loadImage(imagePath);
}

void spawnParticles() {
  DEAD = false;
  COUNTER=0;
  particles.clear(); // Clear previous particles
  float offset = PARTICLE_SIZE/2;
  PVector randomTarget = new PVector(random(-(width*3)/8+img.width/2+PARTICLE_SIZE, (width*3)/8-img.width/2-PARTICLE_SIZE), random(-height/2+img.height/2, height/2-img.height/2));
  for (int i = 0; i < img.width; i += RESOLUTION) {
    for (int j = 0; j < img.height; j += RESOLUTION) {
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

  if ( overRect(geomX, geomY, geomSize, geomSize) ) {
    geomOver = true;
  } else {
    geomOver = false;
  }
}

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
  metaDuration = song.length() / frameLength;
  println("Title: " + metaTitle);
  println("Artist: " + metaArtist);
  println("Duration: " +  String.valueOf(song.length() / frameLength) + "s");
  text = "Song loaded!";
}


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
      clearFolder();
      selectInput("Select a file to process:", "fileSelected");
    }
  }

  if (mouseX > geomX && mouseX < geomX + geomSize &&
    mouseY > geomY && mouseY < geomY + geomSize) {
    geomActive = !geomActive;
    println("Button pressed");
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

void oscEvent(OscMessage theOscMessage) {

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
    GeomFont = "Font/" + fontPython[0].toString();
    font = createFont("Font/" + fontPython[0].toString(), 38);
    text = "Ready!";
  }

  if (theOscMessage.checkAddrPattern("/keywords") == true) {
    keywords = theOscMessage.arguments();
    println("Keywords:");
    println(keywords);
  }
}
// Features Functions

// Entropy goes approximately from  0 (usually only when there is silence, otherwise it has a minimum value between around 50 and 200) to a maximum around 800/1000.
//
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
// TO DO BETTER
float centroidMapping(float centroid) {
  float output = 50;
  if (1000 < centroid && centroid <= 2000) {
    output = map(centroid, 1000, 2000, 0, 10);
  } else if (2000 < centroid && centroid <= 3000) {
    output = map(centroid, 2000, 3000, 10, 20);
  } else if (3000 < centroid && centroid <= 4000) {
    output = map(centroid, 3000, 4000, 20, 30);
  } else if (5000 < centroid && centroid <= 6000) {
    output = map(centroid, 4000, 6000, 30, 50);
  } else if (6000 < centroid) {
    output = map(centroid, 6000, 10000, 50, 100);
  }
  return output;
}
//Energy mantains very high values that changes dramatically during the song. They goes from a minimum around 1000 to a maximum around 40000/50000
// TO DO
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
// TO DO
float spreadMapping(float spread) {
  float output = 64;
  if (0 < spread && spread <= 200) {
    output = map(spread, 0, 200, 63, 63.5);
  } else if (200 < spread && spread <= 400) {
    output = map(spread, 200, 400, 63.5, 64);
  } else if (400 < spread && spread <= 600) {
    output = map(spread, 400, 600, 64, 64.5);
  } else if (600 < spread && spread <= 800) {
    output = map(spread, 600, 800, 64.5, 65);
  } else if (800 < spread) {
    output = map(spread, 800, 1000, 65, 66);
  }
  return output;
}


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
        fill(txtColor, 100, 100);
        beginShape();
        for (int i = 0; i < points.length; i++) {
          vertex(points[i].x, points[i].y + lineY);
        }
        endShape();
        //filter(BLUR, 1);
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


String[] splitTextIntoLinesGeom(String input, float lineWidth) {
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

void mouseDragged() {
  if (mouseX>width/8 && mouseX<(width-width/8)) {
    world.born(float(mouseX), float(mouseY));
  }
}
