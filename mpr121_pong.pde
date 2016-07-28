/*******************************************************************************

 Bare Conductive MPR121 pong game
 -------------------------------------------------------------------------------

 mpr121-pong.pde - Pong with input from TouchBoard and Pi Cap

 Requires Processing 3.0+

 Requires osc5 (version 0.9.8+) to be in your processing libraries folder:
 http://www.sojamo.de/libraries/oscP5/

 Connecting via OSC requires picap-datastream-osc on the Pi Cap

 Bare Conductive code written by Stefan Dzisiewski-Smith and Szymon Kaliski.
 Adapted with code from SimplePong.pde from openprocessing.org
 Code hacking by @paul_tanner to integrate the code and add features
 Hardware design/ build by @rossatkin and @spongefile

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

import oscP5.*;
import netP5.*;

final int numElectrodes  = 12;

boolean serialSelected = false;
boolean oscSelected    = false;
boolean firstRead      = true;
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


OscP5 oscP5;

int[] diffs;

int globalGraphPtr  = 0;
int electrodeNumber = 0;
int serialNumber    = 4;
int lastMillis      = 0;

void setup() {
  size(500, 500);
  noStroke();
  smooth();

  // setup OSC receiver on port 3000
  oscP5 = new OscP5(this, 3000);

  // other setup
  diffs = new int[numElectrodes];
}

void oscEvent(OscMessage oscMessage) {
  println("oscevent");

  if (firstRead && oscMessage.checkAddrPattern("/diff")) {
    firstRead = false;
  }
  else {
    if (oscMessage.checkAddrPattern("/diff")) {
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
 
  fill(200,0,0);
  diam = 20;
  ellipse(x, y, diam, diam);

  fill(200,0,0);
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
      fill(200,0,0);
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
      fill(200,0,0);
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

void updateArrayOSC(int[] array, Object[] data) {
  if (array == null || data == null) {
    return;
  }

  for (int i = 0; i < min(array.length, data.length); i++) {
    array[i] = (int)data[i];
  }
}
