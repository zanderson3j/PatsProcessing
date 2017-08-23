// Daniel Shiffman
// Tracking the average location beyond a given depth threshold
// Thanks to Dan O'Sullivan

// https://github.com/shiffman/OpenKinect-for-Processing
// http://shiffman.net/p5/kinect/

class KinectTracker {

  // Depth threshold
  int activationThreshold = 745;
  int trackingThreshold = 800;
  int visualizationThreshold = 850;

  // Raw location
  PVector loc;
  
  float trackingStrength;

  // Interpolated location
  PVector lerpedLoc;

  // Depth data
  int[] depth;
  
  // What we'll show the user
  PImage display;
  PImage screenImage;
  
  Kinect kinect;
  
  int framesUntilStart;
  
  color colorBackground;
  color colorTracking;
  color colorTrackingCircle;
  float minTrackingCircleRadius = 6;
  float maxTrackingCircleRadius = 40;
  
  int minDistance = 0;
   
  KinectTracker(Kinect k) {
    kinect = k;

    kinect.initDepth();
    kinect.enableMirror(true);
    // Make a blank image
    display = createImage(kinect.width, kinect.height, RGB);
    screenImage = createImage(width, height, RGB);
    // Set up the vectors
    loc = new PVector(0, 0);
    lerpedLoc = new PVector(0, 0);
    trackingStrength = 0.0;
    framesUntilStart = 10;
    
    colorBackground = color(255,255,255);
    colorTracking = color(128, 128, 128);
    colorTrackingCircle = color(0, 0, 255, 255);
  }

  void track() {
    // Get the raw depth as array of integers
    depth = kinect.getRawDepth();
    
    if(frameCount < framesUntilStart)
      return;

    // Being overly cautious here
    if (depth == null) return;

    float sumX = 0;
    float sumY = 0;
    float count = 0;
    trackingStrength = 0.0;
    minDistance = Integer.MAX_VALUE;

    for (int x = 0; x < kinect.width; x++) {
      for (int y = 0; y < kinect.height; y++) {
        
        int offset =  x + y*kinect.width;
        // Grabbing the raw depth
        int rawDepth = depth[offset];
        minDistance = min(minDistance, rawDepth);

        // Testing against threshold
        if (rawDepth < trackingThreshold) {
          float strength = 1.0 - float(rawDepth - activationThreshold)/float(trackingThreshold - activationThreshold); 
          sumX += x * strength;
          sumY += y * strength;
          count += strength;
          trackingStrength = max(trackingStrength, strength);
        }
      }
    }
    // As long as we found something
    if (count != 0) {
      loc = new PVector(sumX/count, sumY/count);
    }

    // Interpolating the location, doing it arbitrarily for now
    lerpedLoc.x = PApplet.lerp(lerpedLoc.x, loc.x, 0.3f);
    lerpedLoc.y = PApplet.lerp(lerpedLoc.y, loc.y, 0.3f);
  }

  boolean isActivated() {
    return trackingStrength >= 1.0;
  }
  
  PVector getLerpedPos() {
    return lerpedLoc;
  }

  PVector getPos() {
    return loc;
  }
  
  PVector getNormalizedPos() {
    return new PVector(loc.x/kinect.width, loc.y/kinect.height);
  }

  void displayBackground() {
    pushStyle();
    // Being overly cautious here
    if (depth == null) return;

    // Going to rewrite the depth image to show which pixels are in threshold
    // A lot of this is redundant, but this is just for demonstration purposes
    display.loadPixels();
    for (int x = 0; x < kinect.width; x++) {
      for (int y = 0; y < kinect.height; y++) {

        int offset = x + y * kinect.width;
        // Raw depth
        int rawDepth = depth[offset];
        int pix = x + y * display.width;
        if (rawDepth < visualizationThreshold) {
          float strength = float(rawDepth - activationThreshold)/float(visualizationThreshold - activationThreshold); 
          display.pixels[pix] = lerpColor(colorTracking, colorBackground, strength);
        } else {
          display.pixels[pix] = colorBackground;
        }
      }
    }
    display.updatePixels();

    // Draw the image
    noTint();
    screenImage.copy(display, 0, 0, kinect.width, kinect.height, 0, 0, width, height);
    background(screenImage);
    popStyle();
  }
  
  void displayTrackingCircle() {
    pushStyle();
    ellipseMode(RADIUS);
    PVector pos = getNormalizedPos();
    pos.x *= width;
    pos.y *= height;
    if(trackingStrength > 1.0) {
      noStroke();
      fill(colorTrackingCircle);
      ellipse(pos.x, pos.y, minTrackingCircleRadius, minTrackingCircleRadius);
    }
    else if(trackingStrength > 0.0) {
      color circleColor = lerpColor(color(0,0,0,0), colorTrackingCircle, trackingStrength);
      noFill();
      stroke(circleColor);
      strokeWeight(10);
      float radius = lerp(maxTrackingCircleRadius, minTrackingCircleRadius, constrain(trackingStrength, 0.0, 1.0));
      ellipseMode(RADIUS);
      ellipse(pos.x, pos.y, radius, radius);
    }
    popStyle();
  }

  int getThreshold() {
    return activationThreshold;
  }

  void setThreshold(int t) {
    activationThreshold =  t;
  }
}