/* --------------------------------------------------------------------------
 * SimpleOpenNI AlternativeViewpoint3d Test
 * --------------------------------------------------------------------------
 * Processing Wrapper for the OpenNI/Kinect library
 * http://code.google.com/p/simple-openni
 * --------------------------------------------------------------------------
 * prog:  Max Rheiner / Interaction Design / zhdk / http://iad.zhdk.ch/
 * date:  06/11/2011 (m/d/y)
 * ----------------------------------------------------------------------------
 */

import SimpleOpenNI.*;

SimpleOpenNI context;
int          width = 1024;
int          height = 768;
float        zoomF =0.6f;
float        rotX = radians(180);  // by default rotate the hole scene 180deg around the x-axis,
                                   // the data from openni comes upside down
float        rotY = radians(-20);

/// box

int boxSize = 100;
float halfBoxSize = boxSize / 2;
PVector boxCenter = new PVector(200, 0, 600);
// 0x0474ba
int r = 0x04;
int g = 0x74;
int b = 0xba;

/// text

PFont f = createFont("Arial",16,true);
String originalMessage = "LXJS\n2013"; 
String message = originalMessage;

/// snapping
boolean snapping = false;
int startedSnappingTime = 0;

boolean sketchFullScreen() {
  return true;
}

void setup()
{
  size(width,height,P3D);

  //context = new SimpleOpenNI(this,SimpleOpenNI.RUN_MODE_SINGLE_THREADED);
  context = new SimpleOpenNI(this);

  // disable mirror
  context.setMirror(true);

  // enable depthMap generation
  if(context.enableDepth() == false)
  {
     println("Can't open the depthMap, maybe the camera is not connected!");
     exit();
     return;
  }

  if(context.enableRGB() == false)
  {
     println("Can't open the rgbMap, maybe the camera is not connected or there is no rgbSensor!");
     exit();
     return;
  }

  // align depth data to image data
  context.alternativeViewPointDepthToImage();

  stroke(255,255,255);
  smooth();
  perspective(radians(45),
              float(width)/float(height),
              10,150000);
}

void draw()
{
  // update the cam
  context.update();

  background(0,0,0);

  translate(width/2, height/2, 0);
  rotateX(rotX);
  rotateY(rotY);
  scale(zoomF);

  PImage  rgbImage = context.rgbImage();
  int[]   depthMap = context.depthMap();
  int     steps   = 5;  // to speed up the drawing, draw every third point
  int     index;
  PVector realWorldPoint;
  color   pixelColor;

  strokeWeight(steps);

  translate(0,0,-1000);  // set the rotation center of the scene 1000 infront of the camera

  PVector[] realWorldMap = context.depthMapRealWorld();
  for(int y=0;y < context.depthHeight();y+=steps)
  {
    for(int x=0;x < context.depthWidth();x+=steps)
    {
      index = x + y * context.depthWidth();
      if(depthMap[index] > 0)
      {
        // get the color of the point
        pixelColor = rgbImage.pixels[index];
        stroke(pixelColor);

        // draw the projected point
        realWorldPoint = realWorldMap[index];
        point(realWorldPoint.x,realWorldPoint.y,realWorldPoint.z);  // make realworld z negative, in the 3d drawing coordsystem +z points in the direction of the eye
      }
    }
  }

 /// box stuff

 int depthPointsInBox = 0;
 for(int i=0; i < realWorldMap.length; i += 10) {
   PVector currentPoint = realWorldMap[i];

   if (currentPoint.x > boxCenter.x - halfBoxSize
       && currentPoint.x < boxCenter.x + halfBoxSize)
   {
     if (currentPoint.y > boxCenter.y - halfBoxSize
         && currentPoint.y < boxCenter.y + halfBoxSize)
     {
       if (currentPoint.z > boxCenter.z - halfBoxSize
           && currentPoint.z < boxCenter.z + halfBoxSize)
       {
         depthPointsInBox ++;
       }
     }
   }
 }
 

 float boxAlpha = map(depthPointsInBox, 0, 200, 0, 255);
 translate(boxCenter.x, boxCenter.y, boxCenter.z);
 fill(r, g, b, boxAlpha);
 stroke(r, g, b);
 box(boxSize);
 
 /// font
 
 translate(0,0,0);
 textFont(f,36);
 fill(255);
 rotateX(rotX);
 text(message, -45, -10, halfBoxSize + 10);

 if (snapping || depthPointsInBox >= 200) {
   snapping();
 } 
  // draw the kinect cam
  //context.drawCamFrustum();
}


void keyPressed()
{
  switch(key)
  {
  case ' ':
    snap();
    //context.setMirror(!context.mirror());
    break;
  }

  switch(keyCode)
  {
  case LEFT:
    rotY += 0.1f;
    break;
  case RIGHT:
    // zoom out
    rotY -= 0.1f;
    break;
  case UP:
    if(keyEvent.isShiftDown())
      zoomF += 0.02f;
    else
      rotX += 0.1f;
    break;
  case DOWN:
    if(keyEvent.isShiftDown())
    {
      zoomF -= 0.02f;
      if(zoomF < 0.01)
        zoomF = 0.01;
    }
    else
      rotX -= 0.1f;
    break;
  }
}

void snapping() {
  int now = millis();
  /// too soon?
  if (! snapping && startedSnappingTime > 0) {
    int diff = (now - startedSnappingTime) / 1000; 
    if (diff > 10)
      startedSnappingTime = 0;
    else return;
  }
  
  // we're snapping!!!
  snapping = true;
  if (startedSnappingTime == 0) {
    startedSnappingTime = millis();
  }
  int diff = (now - startedSnappingTime) / 1000;
  if (diff < 1) {
    message = "snapping\npic";
  } else if (diff < 5) {
    message = (new Integer(4 - diff)).toString();
  } else if (diff < 6) {
    message = "smile!";
  } else if (diff < 7) {
    message = originalMessage;
  } else if (diff < 8) {
    snap();
  } else {
    snapping = false;
  }
}

void snap() {
  Date d = new Date();
  long current = d.getTime()/1000;
  String filename = "photo-" + current + ".png"; 
  save(filename);
}
