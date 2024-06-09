class World {
  World(int num) {
    //make i init blobs
    //used to create an initial population
    for (int i = 0; i < num; i++) {
      PVector l = new PVector(random(width/8, width-width/8), random(height));
      Float[] randgene = {1.1};
      // gene of each blob is generated
      DNA dna = new DNA(randgene);
      // gene is passed to the Blob class, along with the vector to define its initial position
      blobs.add(new Blob(l, dna));
    }
  }

  //new blob
  void born(Float x, Float y) {
    Float[] randgene = {1.1};
    // gene of each blob is generated
    DNA dna = new DNA(randgene);
    // gene is passed to the Blob class, along with the vector to define its initial position
    PVector l = new PVector(x,y); 
    blobs.add(new Blob(l, dna));
  }

// function to update the status of the whole blob population present inside the window
 void run(float centroidcolor, float spread, float skew) {

    for (int i = blobs.size() - 1; i >= 0; i--) {
      Blob b = blobs.get(i);
      // individual blob is updated
      b.run(centroidcolor, spread, skew);
      
      // population cleanup, if the health of a blob drops below a certain level it's removed from the list
      if (b.dead()) {
        b.makeSmall();
        blobs.remove(i);
      }
      
      //create new blob from parent according to the current reproduction chance
      Blob child = b.reproduce();
      if (child != null) blobs.add(child);
    }
  }
}

public class Blob {
  
  public PVector position;
  public int health;
  public Float xoff;
  public Float yoff;
  public DNA dna;
  public Float maxspeed;
  public Float r;
  
  Blob(PVector l, DNA dna_) {
    position = l; //location
    health = 200; //timer
    xoff = random(1000);
    yoff = random(1000);
    dna = dna_;//determines size and maximum speed (bigger = slower)
    maxspeed = map(dna.genes[0], 0, 1, 15, 0); //max speed determined by the gene
    r = map(dna.genes[0], 0, 1, 0, 50); //size determined by the gene
  }

  // update status and visual appearance of blob
  void run(float centroidcolor, float spread, float skew) {
    this.update(spread);
    this.display(centroidcolor, skew);
  }

  Blob reproduce() {
    //asexual reproduction
    if (random(1) < 0.0005) { 
      //child is exact copy
      DNA childDNA = this.dna;
      //DNA can mutate
      childDNA.mutate(0.01);
      return new Blob(this.position, childDNA);
    } else {
      return null;
    }
  }

  // reduce size of blob when dead (smooths transition)
  void makeSmall() {
    while (this.r>0) {
      this.r -= 0.01;
    }
  }

  
  void update(float spread) {
    //random movement of the particles in the window is updated
    //based on perlin noise
    Float vx = map(noise(this.xoff), 0, 1, -this.maxspeed, this.maxspeed);
    Float vy = map(noise(this.yoff), 0, 1, -this.maxspeed, this.maxspeed);
    
    //stops blobs if they reach the lateral edges
    if (position.x > width-width / 8-this.r || position.x < width / 8+this.r) {
      vx *= -1;
      vx = 0.0;
    }

    //spread of the song influences the motion of the blobs (spread here is set to 1 if song isnt playing, movement unaffected)
    PVector velocity = new PVector(vx, vy);
    this.xoff += 0.01*spread;
    this.yoff += 0.01*spread;

    this.position.add(velocity);
    
    //reduces health of the blob as it's being updated, as well as its radius
    this.health -= 1.2;
    if (r-0.25<0){
      this.r = 0.0;
    } else {
      this.r -= 0.25;
    }
  }
  
  //visual update of the blob (circle size and color)
  void display(float centroidcolor, float skew) {
    ellipseMode(CENTER);
    
    // periodic (cos function) color of the blobs if the song isn't playing
    if(centroidcolor==200&&!playing){
      colorMode(HSB, 360, 100, 100);
          stroke(360*abs(cos(millis()*0.0001)), this.health-skew,this.health);
          fill(360*abs(cos(millis()*0.0001)), this.health-skew,this.health);
      colorMode(RGB, 255, 255, 255);
      //color controlled by the centroid of the track, saturation and brightness controlled by skew and health of the blob (gets darker as it dies)
    } else {
      colorMode(HSB, 360, 100, 100);
          stroke(centroidcolor, this.health-skew,this.health);
          fill(centroidcolor, this.health-skew,this.health);
      colorMode(RGB, 255, 255, 255);
    }
    //draw the blob
    ellipse(this.position.x, this.position.y, this.r, this.r);
  }

 //updates status of the blob by checking its health value
 boolean dead() {
    if (this.health < 0.0) {
      return true;
    } else {
      return false;
    }
  }
}

// simple class for the genetic makeup of the blobs
public class DNA {
  public Float[] genes;
  
  DNA(Float[] newgenes) {
    if (newgenes[0] != 1.1) {
      genes = newgenes;
    } else {
      //genetic sequence is a random value between 0 and 1
      genes = new Float[1];
      for (int i = 0; i < genes.length; i++) {
        genes[i] = random(0, 1);
      }
    }
  }

  DNA copy() {
    Float[] newgenes = new Float[1];
    for (int i = 0; i < this.genes.length; i++) {
      newgenes[i] = this.genes[i];
    }

    return new DNA(newgenes);
  }

  //picks a new random character in array spots
  void mutate(Float m) {
    for (int i = 0; i < this.genes.length; i++) {
      if (random(1) < m) {
        this.genes[i] = random(0, 1);
      }
    }
  }
}
