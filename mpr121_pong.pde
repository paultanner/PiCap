/*******************************************************************************

 Bare Conductive MPR121 pong game
 -------------------------------------------------------------------------------

 mpr121-pong.pde - Pong with input from TouchBoard and Pi Cap

 Requires Processing 3.0+

 Requires controlp5 (version 2.2.5+) to be in your processing libraries folder:
 http://www.sojamo.de/libraries/controlP5/

 Requires osc5 (version 0.9.8+) to be in your processing libraries folder:
 http://www.sojamo.de/libraries/oscP5/

 Connecting via OSC requires picap-datastream-osc on the Pi Cap

 Bare Conductive code written by Stefan Dzisiewski-Smith and Szymon Kaliski.
 Adapted with code from SimplePong.pde by ???
 Code hacking by @paul_tanner
 Hardware build by Ross and Tina

 This work is licensed under a Creative Commons Attribution-ShareAlike 3.0
 Unported License (CC BY-SA 3.0) http://creativecommons.org/licenses/by-sa/3.0/

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.

*******************************************************************************/

import processing.serial.*;
import controlP5.*;
import oscP5.*;
import netP5.*;

final int baudRate = 57600;

final int numElectrodes  = 12;
final int numGraphPoints = 300;
final int tenBits        = 1024;

final int graphsLeft           = 20;
final int graphsTop            = 20;
final int graphsWidth          = 984;
final int graphsHeight         = 540;
final int numVerticalDivisions = 8;

final int filteredColour = color(255, 0,   0,   200);
final int baselineColour = color(0,   0,   255, 200);
final int touchedColour  = color(255, 128, 0,   200);
final int releasedColour = color(0,   128, 128, 200);
final int textColour     = color(60);
final int touchColour    = color(255, 0,   255, 200);
final int releaseColour  = color(255, 255, 255, 200);

final int graphFooterLeft = 20;
final int graphFooterTop  = graphsTop + graphsHeight + 20;

final int numFooterLabels = 6;

boolean serialSelected = false;
boolean oscSelected    = false;
boolean firstRead      = true;
boolean paused         = false;
boolean soloMode       = false;

boolean gameStart = false; //true;
 
float x = 150;
float y = 150;
float speedX = random(3, 5);
float speedY = random(3, 5);
int leftColor = 128;
int rightColor = 128;
int diam;
int rectSize = 150;
float diamHit;
int vpos1 = 0;
int vpos2 = 0;

ControlP5 cp5;
ScrollableList electrodeSelector, serialSelector;
Textlabel labels[], startPrompt, instructions, pausedIndicator;
Button oscButton;

OscP5 oscP5;

Serial inPort;        // the serial port
String[] serialList;
String inString;      // input string from serial port
String[] splitString; // input string array after splitting
int lf = 10;          // ASCII linefeed

int[] filteredData, baselineVals, diffs, touchThresholds, releaseThresholds, status, lastStatus;
int[][] filteredGraph, baselineGraph, touchGraph, releaseGraph, statusGraph;

int globalGraphPtr  = 0;
int electrodeNumber = 0;
int serialNumber    = 4;
int lastMillis      = 0;

void setup() {
  size(500, 500);
  noStroke();
  smooth();

  // init cp5
  cp5 = new ControlP5(this);

  // setup OSC receiver on port 3000
  oscP5 = new OscP5(this, 3000);

  // init serial
  serialList = Serial.list();

  // other setup??
  //setupGraphs();
  //setupStartPrompt();
  //setupRunGUI();
  //setupLabels();
  diffs = new int[numElectrodes];
}

void oscEvent(OscMessage oscMessage) {
  println("oscevent");

  if (firstRead && oscMessage.checkAddrPattern("/diff")) {
    firstRead = false;
  }
  else {
    if (oscMessage.checkAddrPattern("/touch")) {
      updateArrayOSC(status, oscMessage.arguments());
    }
    else if (oscMessage.checkAddrPattern("/tths")) {
      updateArrayOSC(touchThresholds, oscMessage.arguments());
    }
    else if (oscMessage.checkAddrPattern("/rths")) {
      updateArrayOSC(releaseThresholds, oscMessage.arguments());
    }
    else if (oscMessage.checkAddrPattern("/fdat")) {
      updateArrayOSC(filteredData, oscMessage.arguments());
    }
    else if (oscMessage.checkAddrPattern("/bval")) {
      updateArrayOSC(baselineVals, oscMessage.arguments());
    }
    else if (oscMessage.checkAddrPattern("/diff")) {
      // simulate mouse in original game
      updateArrayOSC(diffs, oscMessage.arguments());
      vpos1=diffs[10]-diffs[1]+100; // guesswork
      vpos1*=2.5;
      if (vpos1 > 450) vpos1=450;    // limits
      if (vpos1 < 80) vpos1=80;
      vpos2=diffs[0]-diffs[11]+100; // guesswork
      vpos2*=2.0;
      if (vpos2 > 450) vpos2=450;    // limits
      if (vpos2 < 80) vpos2=80; 
      print(vpos1, vpos2);
      println();
    }
  }
}

void draw() {
  background(255);
 
  fill(128,128,128);
  diam = 20;
  ellipse(x, y, diam, diam);

//  fill(leftColor);
//  rect(0, 0, 20, height);
  fill(leftColor);
  //rect(0, 0, 20, height);
  rect(width-30, vpos1-rectSize/2, 10, rectSize);
  rect(30, vpos2-rectSize/2, 10, rectSize);
  
    if (gameStart) {
 
    x = x + speedX;
    y = y + speedY;
 
    // if ball hits movable bar, invert X direction and apply effects
    if ( x > width-30 && x < width-20 && y > vpos1-rectSize/2 && y < vpos1+rectSize/2 ) {
      speedX = speedX * -1;
      x = x + speedX;
      rightColor = 0;
      fill(random(0,128),random(0,128),random(0,128));
      diamHit = random(75,150);
      ellipse(x,y,diamHit,diamHit);
      rectSize = rectSize-10;
      rectSize = constrain(rectSize, 10,150);     
    }
    
    // similar if ball hits the other movable bar (2 players)
    else if ( x > 20 && x < 30 && y > vpos2-rectSize/2 && y < vpos2+rectSize/2 ) {
      speedX = speedX * -1;
      x = x + speedX;
      rightColor = 0;
      fill(random(0,128),random(0,128),random(0,128));
      diamHit = random(75,150);
      ellipse(x,y,diamHit,diamHit);
      rectSize = rectSize-10;
      rectSize = constrain(rectSize, 10,150);     
    }
 
    // if ball hits wall, change direction of X (single player only)
    else if (false && x < 25) {
      speedX = speedX * -1.1;
      x = x + speedX;
      leftColor = 0;
    }
 
    else {    
      leftColor = 128;
      rightColor = 128;
    }

    // resets things if ball hits either wall - you lose
    if (x > width || x < 0) {
      gameStart = false;
      //delay(5000);  // auto-restart
      //gameStart = true;
      x = 150;
      y = 150;
      speedX = random(3, 5);
      speedY = random(3, 5);
      rectSize = 150;
    }
  
    // if ball hits up or down, change direction of Y  
    if ( y > height || y < 0 ) {
      speedY = speedY * -1;
      y = y + speedY;
    }
  }
}

void mousePressed() {
  gameStart = !gameStart;
}