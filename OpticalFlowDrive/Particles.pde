
float drag = 0.1;

float maxVel = 0.0;

class Particle {
    
  public PVector origin;
  public PVector position;
  public PVector prevPosition;
  public PVector velocity;
  
  Particle(float x, float y) {
    origin = new PVector(x,y);
    position = new PVector(x,y);
    prevPosition = new PVector(x,y);
    velocity = new PVector(0,0);
  }
  
  Particle(PVector p) {
    origin = new PVector(p.x, p.y);
    position = new PVector(p.x, p.y);
    prevPosition = new PVector(p.x,p.y);
    velocity = new PVector(0,0);
  }
  
  void Update(PVector newVel) {
    prevPosition = position;
    
    velocity.add(-drag * velocity.x, -drag * velocity.y);
    velocity.add(newVel);
    velocity.limit(min(width,height)/2);
    
    position.add(velocity);
    
    PVector dir = PVector.sub(origin, position);
    
    if(dir.mag() > 1.0) {
      dir.limit(3);
      position.add(dir);    
    }
    
    if(position.x < 0) {
      position.x = -position.x;
      velocity.x = -velocity.x;
    }
    
    if(position.x >= width) {
      position.x = 2*width - position.x;
      velocity.x = -velocity.x;
    }
    
    if(position.y < 0) {
      position.y = -position.y;
      velocity.y = -velocity.y;
    }
    
    if(position.y >= height) {
      position.y = 2*height - position.y;
      velocity.y = -velocity.y;
    }
  }
}

Particle[] createGrid(int sizeX, int sizeY, float minX, float minY, float maxX, float maxY) {
  
  float incX = (maxX - minX)/sizeX;
  float incY = (maxY - minY)/sizeY;
  
  Particle[] grid = new Particle[sizeX * sizeY];
  
  int idx = 0;
  for(int y = 0; y < sizeY; ++y) {
    for(int x = 0; x < sizeX; ++x) {
      grid[idx] = new Particle(minX + x*incX, minY + y*incY);
      ++idx;
    }
  }
  
  return grid;
}