//
//  lcdScreen.hpp
//  lcd_Simulator
//
//  Created by Jildert Viet on 14-01-20.
//

#ifndef lcdScreen_hpp
#define lcdScreen_hpp

#include <stdio.h>
#include "ofMain.h"
#include "Env.hpp"
#include "ofxOsc.h"

class lcdScreen{
public:
    lcdScreen(char id, glm::vec2 loc, glm::vec2 size);
    glm::vec2 loc, size;
    void display();
    void update();
    char id;
    bool isMouseInside(int x, int y);
    bool bSelected = false;
    void select();
    void deselect();
    void move(glm::vec2 distance);
    Env backlightEnvelopes[2][8];
    int backLightValues[2] = {0, 0};
    int addValue = 0;
    void backLightEnv(char backLightId, vector<float> values, vector<float> times);
    void parseMsg(ofxOscMessage& m);
    bool bDisplayInfo = true;
//    ofTexture* tex;
    ofFbo lcdOverlay;
//    ofImage img;
    ofPixels* p;
    glm::vec2 pixelReadPos;
    // Rectangle vector...
    char mode = 1;
    void fillRect(float x, float y, float w, float h, int r, int g, int b);
};
#endif /* lcdScreen_hpp */
