import gab.opencv.*;
import processing.video.*;

int displayOption = 1;
boolean displayFPS = false;

Capture camera;
OpenCV opencv;

Particle[] grid;

PVector[] velocityGrid;

int captureWidth = 320;
int captureHeight = 240;
int velGridWidth = captureWidth / 5;
int velGridHeight = captureHeight / 5;
int partGridWidth = 0;
int partGridHeight = 0;

int dotSize = 12;

color beginColor = color(255);
color endColor = color(255);




void setup() {
  fullScreen();
  //size(640, 480);
  camera = new Capture(this, captureWidth, captureHeight);
  opencv = new OpenCV(this, captureWidth, captureHeight);
  camera.start();
  
  smooth();
  noStroke();

  background(0); 
  
  velocityGrid = new PVector[velGridWidth * velGridHeight];
  for(int idx = 0; idx < velocityGrid.length; ++idx) {
    velocityGrid[idx] = new PVector(0,0);
  }
  
  partGridWidth = (width - 20) / 20;
  partGridHeight = (height - 20) / 20;
  grid = createGrid(partGridWidth, partGridHeight, 10, 10, width - 10, height - 10);
}

void drawGridDots() {
  background(0);
  noStroke();
  fill(255);
  
  int halfDotSize = dotSize/2;
  
  for(int idx = 0; idx < grid.length; ++idx) {
    rect(grid[idx].position.x - halfDotSize, grid[idx].position.y - halfDotSize, dotSize, dotSize);
  }
}

void drawGridBlend() {
  fill(0, 10); // semi-transparent white
  rect(0, 0, width, height);
  noStroke();
  fill(255);
  
  int halfDotSize = dotSize/2;
  
  for(int idx = 0; idx < grid.length; ++idx) {
    rect(grid[idx].position.x - halfDotSize, grid[idx].position.y - halfDotSize, dotSize, dotSize);
  }
}

void drawGridSpeedColor() {
  fill(0, 10); // semi-transparent white
  rect(0, 0, width, height);
  noStroke();
  
  int halfDotSize = dotSize/2;
  
  for(int idx = 0; idx < grid.length; ++idx) {
    float t = constrain(grid[idx].velocity.mag()/20,0,1);
    fill(lerpColor(color(128,128,255), color(255,128,128), t));
    rect(grid[idx].position.x - halfDotSize, grid[idx].position.y - halfDotSize, dotSize, dotSize);
  }
}

void updateColor() {
  beginColor = endColor;
  endColor = color(random(64,255), random(64,255), random(64,255)); 
}

void drawGridCycleColor() {
  fill(0, 10); // semi-transparent white
  rect(0, 0, width, height);
  noStroke();

  if(frameCount % 10 == 0)
    updateColor();
    
  color c = lerpColor(beginColor, endColor, float(frameCount % 10) / 10.0);
  
  for(int idx = 0; idx < grid.length; ++idx) {
    float t = constrain(grid[idx].velocity.mag()/20,0,1);
    fill(c);
    rect(grid[idx].position.x - dotSize, grid[idx].position.y - dotSize, dotSize, dotSize);
  }
}

void drawFPS() {
  fill(0);
  rect(0, height-12, 40, 12);
  fill(255);
  text("FPS:", 0 , height);
  text(Integer.toString(int(frameRate)), 22, height);
}

void calculateVelGrid() {
  if(camera.available()) {
    camera.read();
    opencv.loadImage(camera);
    opencv.flip(OpenCV.HORIZONTAL);
    opencv.calculateOpticalFlow();
    
    int regWidth = captureWidth / velGridWidth;
    int regHeight = captureHeight / velGridHeight;
    
    int idx = 0;
    for(int y = 0; y < velGridHeight; ++y) {
      for(int x = 0; x < velGridWidth; ++x) {
        velocityGrid[idx] = opencv.getAverageFlowInRegion(x * regWidth, y * regHeight, regWidth, regHeight);
        if(Float.isNaN(velocityGrid[idx].x)) {
          velocityGrid[idx].x = 0;
        }
        if(Float.isNaN(velocityGrid[idx].y)) {
          velocityGrid[idx].y = 0;
        }
        ++idx;
      }
    }
  }
}

void updateParticles() {
  int regWidth = width / velGridWidth;
  int regHeight = height / velGridHeight;

  for(int idx = 0; idx < grid.length; ++idx) {
    int x = constrain(int(grid[idx].position.x / regWidth), 0, velGridWidth - 1);
    int y = constrain(int(grid[idx].position.y / regHeight), 0, velGridHeight - 1);
    
    int vidx = x + y * velGridWidth;

    if(velocityGrid[vidx] == null)
      println("null", vidx, x, y);
    grid[idx].Update(velocityGrid[vidx]);
  }  
}

void drawStuff() {
  if(displayOption == 1)
    drawGridDots();
  else if(displayOption == 2)
    drawGridBlend();
  else if(displayOption == 3)
    drawGridSpeedColor();
  else if(displayOption == 4)
    drawGridCycleColor();
}


void draw() {
  calculateVelGrid();
  updateParticles();
  drawStuff();
  
  if(displayFPS) drawFPS();
}

void keyPressed() {
  if (key=='f' || key=='F') {
    displayFPS = !displayFPS;
  }
  else if (key=='1') {
    displayOption = 1;
  }
  else if (key=='2') {
    displayOption = 2;
  }
  else if (key=='3') {
    displayOption = 3;
  }
  else if (key=='4') {
    displayOption = 4;
  }
}