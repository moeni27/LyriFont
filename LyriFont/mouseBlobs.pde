class World {
  World(int num) {
    //make i init blobs
    for (int i = 0; i < num; i++) {
      PVector l = new PVector(random(width/8, width-width/8), random(height));
      Float[] randgene = {1.1};
      DNA dna = new DNA(randgene);
      blobs.add(new Blob(l, dna));
    }
  }

  //new blob
  void born(Float x, Float y) {
    Float[] randgene = {1.1};
    DNA dna = new DNA(randgene);
    PVector l = new PVector(x,y); 
    blobs.add(new Blob(l, dna));
  }

 void run(float centroidcolor, float spread, float skew) {

    for (int i = blobs.size() - 1; i >= 0; i--) {
      Blob b = blobs.get(i);
      b.run(centroidcolor, spread, skew);
      if (b.dead()) {
        b.makeSmall();
        blobs.remove(i);
      }
      //create new blob from parent
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
    maxspeed = map(dna.genes[0], 0, 1, 15, 0);
    r = map(dna.genes[0], 0, 1, 0, 50);
  }

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

  void makeSmall() {
    while (this.r>0) {
      this.r -= 0.01;
    }
  }

  void update(float spread) {
    //based on perlin noise
    Float vx = map(noise(this.xoff), 0, 1, -this.maxspeed, this.maxspeed);
    Float vy = map(noise(this.yoff), 0, 1, -this.maxspeed, this.maxspeed);
    
    if (position.x > width-width / 8-this.r || position.x < width / 8+this.r) {
      vx *= -1;
      vx = 0.0;
    }

    PVector velocity = new PVector(vx, vy);
    this.xoff += 0.01*spread;
    this.yoff += 0.01*spread;

    this.position.add(velocity);
    
    this.health -= 1.2;
    if (r-0.25<0){
      this.r = 0.0;
    } else {
      this.r -= 0.25;
    }
  }

  void display(float centroidcolor, float skew) {
    ellipseMode(CENTER);
    if(centroidcolor==200&&!playing){
      colorMode(HSB, 360, 100, 100);
          stroke(360*abs(cos(millis()*0.0001)), this.health-skew,this.health);
          fill(360*abs(cos(millis()*0.0001)), this.health-skew,this.health);
      colorMode(RGB, 255, 255, 255);
    } else {
      colorMode(HSB, 360, 100, 100);
          stroke(centroidcolor, this.health-skew,this.health);
          fill(centroidcolor, this.health-skew,this.health);
      colorMode(RGB, 255, 255, 255);
    }
    ellipse(this.position.x, this.position.y, this.r, this.r);
  }

 boolean dead() {
    if (this.health < 0.0) {
      return true;
    } else {
      return false;
    }
  }
}

public class DNA {
  public Float[] genes;
  
  DNA(Float[] newgenes) {
    if (newgenes[0] != 1.1) {
      genes = newgenes;
    } else {
      //genetic sequence is random floating point values between 0 and 1
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
