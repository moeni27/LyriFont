class Particle {
  float x;
  float y;
  color c;
  float targetX;
  float targetY;
  float factor = 0.25;
  float jigglefactor = 0.25;

  // interactive particle system which displays the generated background images
  Particle(float x, float y, color c, PVector randomTarget) {
    this.x = x;
    this.y  = y;
    this.c = c;
    // central target position of the whole grid set relatively to the single particle
    this.targetX = x+randomTarget.x;
    this.targetY = y+randomTarget.y;
  }
  
  // update function for each generated frame
  void update(float flatness) {
    
    // makes particles disappear after a certain amount of time (if song is playing)
    if(COUNTER<1&&!DEAD) {
      COUNTER+=0.000001; 
    } else if (DEAD && COUNTER>0) {
      COUNTER-=0.000005;
    }
    
    PVector mouse = new PVector(mouseX, mouseY);
    PVector current = new PVector(this.x, this.y);
    PVector target = new PVector(this.targetX, this.targetY);
    
    // distance between the mouse and the single particle, used to calculate the repulsive force
    PVector mouse2particle = PVector.sub(current, mouse);
    float distanceMouse = mouse2particle.mag();
    
    // distance between the relative target and the single particle, used to calculate the attractive force
    PVector particle2target = PVector.sub(target, current);
    float distanceTarget = particle2target.mag();
    
    // vector containing the total force applied to the particle
    PVector force = new PVector(0, 0);
    
    //MIN/MAX_FORCE control how fast particles are repulsed/attracted
    //if the mouse gets inside a certain circumference around the particle, a repulsive force is applied
    if (distanceMouse<100) {
      float repulsion = map(distanceMouse, 0, 100, MAX_FORCE, MIN_FORCE);
      mouse2particle.setMag(repulsion);
      force.add(mouse2particle);
    }
    
    //if the mouse gets inside a certain circumference around the particle, a repulsive force is applied
    if (distanceMouse>0) {
      float attraction = map(distanceTarget, 0, 100, MIN_FORCE, MAX_FORCE);
      particle2target.setMag(attraction/4);
      force.add(particle2target);
    }

    // extra motion is applied onto the particles, loosely following the music according to its computed flatness
    jigglefactor = factor*flatness;
    this.x += force.x+random(-jigglefactor, jigglefactor);
    this.y += force.y+random(-jigglefactor, jigglefactor);
    
  }
  
  // particles is draw with the appropriate color, with the size indicated in the main file 
  // (shrunk/enlarged by the counter in case we're in the transition between images)
  void draw() {
    fill(c);
    noStroke();
    ellipse(this.x, this.y, PARTICLE_SIZE*COUNTER, PARTICLE_SIZE*COUNTER);
  }
  
}
