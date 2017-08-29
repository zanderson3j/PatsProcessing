import gab.opencv.*;
import processing.video.*;

// Setting for dislay 
int displayOption = 1; // 1-4
boolean displayFPS = false;
boolean displayBorder = false;
boolean flipHorizontal = false;

Capture camera;
OpenCV opencv;
FlowThread flowThread;

// Define the cameras. Uncomment the one you want to use 
//String cameraName = "Built-in iSight";
//int cameraWidth = 320;
//int cameraHeight = 240;

String cameraName = "HUE HD Camera";
int cameraWidth = 320;
int cameraHeight = 180;

// The velocity grid is a 2D array of average pixel velocities
// computed from OpenCVs optical flow functions
int velGridWidth = cameraWidth / 5;
int velGridHeight = cameraHeight / 5;
PVector[] velocityGrid;

int sideBarSize = 50;
int sideBarInc = 1;

// The approximate number of particles to display. The
// particles are layed out in a grid whose width and height
// are propotional to the display area size.
int totalNumParticles = 10000;
Particle[] grid;
// Size of the rectangle display for each particle
int dotSize = 8;

// Used by the color cycling display
color beginColor = color(255);
color endColor = color(255);

// Create all the particles
void setupParticles() {
  
  int displayAreaWidth = width - (sideBarSize + dotSize) * 2;
  int displayAreaHeight = height - dotSize * 2;
  
  int partGridWidth = int(sqrt(totalNumParticles * displayAreaWidth / displayAreaHeight));
  int partGridHeight = totalNumParticles/partGridWidth;
  println("grid width = ", partGridWidth, ", grid height = ", partGridHeight);
  grid = createGrid(partGridWidth, partGridHeight, 
          sideBarSize + dotSize, 
          dotSize, 
          width - sideBarSize - dotSize, 
          height - dotSize);
}


void setup() {
  fullScreen();
  
  String[] camList = Capture.list();
  for(int i = 0; i < camList.length; ++i)
    println(camList[i]);

  camera = new Capture(this, cameraWidth, cameraHeight, cameraName, 30);
  opencv = new OpenCV(this, cameraWidth, cameraHeight);
  
  smooth();
  noStroke();

  background(0); 
  
  // Create and initialize the grid of velocities
  velocityGrid = new PVector[velGridWidth * velGridHeight];
  for(int idx = 0; idx < velocityGrid.length; ++idx) {
    velocityGrid[idx] = new PVector(0,0);
  }
  
  setupParticles();

  // start a background thread that grabs
  // the camera image and computes the regional
  // velocities
  flowThread = new FlowThread();
  flowThread.start();
}

// displayOption = 1
void drawGridDots() {
  background(0);
  noStroke();
  fill(255);
  
  int halfDotSize = dotSize/2;
  
  for(int idx = 0; idx < grid.length; ++idx) {
    rect(grid[idx].position.x - halfDotSize, grid[idx].position.y - halfDotSize, dotSize, dotSize);
  }
}

// displayOption = 2
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

// displayOption = 3
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

// displayOption = 4
void drawGridCycleColor() {
  fill(0, 10); // semi-transparent white
  rect(0, 0, width, height);
  noStroke();

  if(frameCount % 60 == 0)
    updateColor();
    
  color c = lerpColor(beginColor, endColor, float(frameCount % 10) / 10.0);
  
  for(int idx = 0; idx < grid.length; ++idx) {
    fill(c);
    rect(grid[idx].position.x - dotSize, grid[idx].position.y - dotSize, dotSize, dotSize);
  }
}

// Draw the number of frames per second
void drawFPS() {
  fill(0);
  rect(0, height-12, 40, 12);
  fill(255);
  text("FPS:", 0 , height);
  text(Integer.toString(int(frameRate)), 22, height);
}

// Draw the side bar border
void drawSideBarBorder() {
  fill(255, 0, 0);
  rect(sideBarSize, 0, 10, height);
  rect(width - sideBarSize - 10, 0, 10, height);
}

// Calculate the new region velocities from the camera image
void calculateVelGrid() {
  if(camera.available()) {
    camera.read();
    opencv.loadImage(camera);
    if(flipHorizontal)
      opencv.flip(OpenCV.HORIZONTAL);
    opencv.calculateOpticalFlow();
    
    int regionWidth = cameraWidth / velGridWidth;
    int regionHeight = cameraHeight / velGridHeight;
    
    int idx = 0;
    for(int y = 0; y < velGridHeight; ++y) {
      for(int x = 0; x < velGridWidth; ++x) {
        velocityGrid[idx] = opencv.getAverageFlowInRegion(x * regionWidth, y * regionHeight, regionWidth, regionHeight);
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

// loop through all the particles and impart the 
// velocity from the region they are positioned over
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

// Draw baed on the displayOption setting
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

// Main draw function
void draw() {
  updateParticles();
  drawStuff();
  
  if(displayFPS) {
    drawFPS();
  }
  if(displayBorder) {
    drawSideBarBorder();
  }
}

// Handle keyboard input
void keyPressed() {
  if (key=='f' || key=='F') {
    displayFPS = !displayFPS;
  }
  else if(key == 'h' || key == 'H') {
    flipHorizontal = !flipHorizontal;
  }
  if (key=='b' || key=='B') {
    sideBarInc = 1;
    displayBorder = !displayBorder;
    if(!displayBorder) {
      setupParticles();
    }
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
  else if(displayBorder && keyCode == RIGHT) {
    if(sideBarSize < width/2 - 100) {
      sideBarSize += sideBarInc;
      
      if(sideBarInc < 10)
        sideBarInc += 1;
    }
  }
  else if(displayBorder && keyCode == LEFT) {
    if(sideBarSize > 0) {
      sideBarSize -= sideBarInc;

      if(sideBarInc < 10)
        sideBarInc += 1;
    }
  }
}

// Thread calss for background image processing
class FlowThread implements Runnable {
  Thread thread;
  
  public FlowThread() { 
  }
  
  public void start() {
    thread = new Thread(this);
    thread.start();
  }
  
  public void run() {
    println("Thread running");
    camera.start();
    while(true) {  
      if(camera.available() == true)
      {
        calculateVelGrid();
      }
      else {
        try {
          Thread.sleep(10);
        }
        catch(InterruptedException e) {
        }
      }
    }
  }
  
  public void stop() {
    thread = null;
  }
  
  public void dispose() {
    stop();
  }
}