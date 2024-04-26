class Particle {
  float x;
  float y;
  color c;
  float targetX;
  float targetY;
  float jigglefactor = 0.25;

  Particle(float x, float y, color c, PVector randomTarget) {
    this.x = x;
    this.y  = y;
    this.c = c;
    this.targetX = x+randomTarget.x;
    this.targetY = y+randomTarget.y;
  }
  
  void update() {
    
    if(COUNTER<1 && !DEAD) {
      COUNTER+=0.000001; 
    } else if (DEAD && COUNTER>0) {
      COUNTER-=0.000005;
    }
    
    PVector mouse = new PVector(mouseX, mouseY);
    PVector current = new PVector(this.x, this.y);
    PVector target = new PVector(this.targetX, this.targetY);
    
    PVector mouse2particle = PVector.sub(current, mouse);
    float distanceMouse = mouse2particle.mag();
    
    PVector particle2target = PVector.sub(target, current);
    float distanceTarget = particle2target.mag();
    
    PVector force = new PVector(0, 0);
    
    if (distanceMouse<100) {
      float repulsion = map(distanceMouse, 0, 100, MAX_FORCE, MIN_FORCE);
      mouse2particle.setMag(repulsion);
      force.add(mouse2particle);
    }
        
    if (distanceMouse>0) {
      float attraction = map(distanceTarget, 0, 100, MIN_FORCE, MAX_FORCE);
      particle2target.setMag(attraction/4);
      force.add(particle2target);
    }

    this.x += force.x+random(-jigglefactor, jigglefactor);
    this.y += force.y+random(-jigglefactor, jigglefactor);
    
  }
  
  void draw() {
    fill(c);
    noStroke();
    ellipse(this.x, this.y, PARTICLE_SIZE*COUNTER, PARTICLE_SIZE*COUNTER);
  }
  
}
