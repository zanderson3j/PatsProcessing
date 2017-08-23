

import org.openkinect.freenect.*;
import org.openkinect.freenect2.*;
import org.openkinect.processing.*;
import org.openkinect.tests.*;


Kinect kinect;
KinectTracker tracker;
float angle;

void setup() {  
  //size(600, 600);
  fullScreen();
  kinect = new Kinect(this);
  tracker = new KinectTracker(kinect);
  angle = kinect.getTilt();
}

void draw() {
  tracker.track();
  tracker.displayBackground();
  
  textSize(64);
  text(String.valueOf(tracker.minDistance), width/2, height/2);
  
  
  tracker.displayTrackingCircle();

  
  
}

void keyPressed() {
  if (key == CODED) {
    if (keyCode == UP) {
      angle++;
    } else if (keyCode == DOWN) {
      angle--;
    }
    angle = constrain(angle, 0, 30);
    kinect.setTilt(angle);
    println(angle);
  }
}
  