String str1 = "LyriFont";
PGraphics[] letters = new PGraphics[str1.length()];
float[] charScale = new float[str1.length()];
int fontSize = 120;

void setup() { 
  size(1000, 500);
  textSize(fontSize);
  for (int i = 0; i < letters.length; ++i) {
    letters[i] = createGraphics(int(textWidth(str1.charAt(i))), fontSize); 
    letters[i].beginDraw(); 
    letters[i].textSize(fontSize); 
    letters[i].text(str1.charAt(i), 0, .833 * fontSize); 
    letters[i].endDraw();
  }
}

void draw() {
  background(0);
  int letterX = 0;
  for (int i = 0; i < letters.length; ++i) {
    charScale[i] = (1 + sin(radians(frameCount) + map(i, 0, letters.length, 0, PI))) * 1.5;
    image(letters[i], letterX, 0, letters[i].width * charScale[i], letters[i].height); 
    letterX += (letters[i].width * charScale[i]);
  }
}
