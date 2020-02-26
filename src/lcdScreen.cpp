//
//  lcdScreen.cpp
//  lcd_Simulator
//
//  Created by Jildert Viet on 14-01-20.
//

#include "lcdScreen.hpp"

lcdScreen::lcdScreen(char id, glm::vec2 loc, glm::vec2 size){
    this->loc = loc;
    this->size = size;
    this->id = id;
    cout << loc << endl;
    cout << size << endl;
    cout << (int)id << endl;
//    f.allocate(size.x, size.y, GL_RGB);
//    f2.allocate(1, 2, GL_RGB);
    lcdOverlay.allocate(size.x, size.y, GL_RGBA);
    fillRect(0, 0, 1, 1, 1, 1, 1);
    
    for(char i=0; i<2; i++){
        for(char j=0; j<8; j++)
            backlightEnvelopes[i][j].active = false;
    }
}

void lcdScreen::update(){
    if(mode == 0){
        for(char i=0; i<2; i++){
            if(laggers[i].bActive){
                addValues[i] = laggers[i].process();
            }
            int maxValue = 0;
            for(char j=0; j<8; j++){
                backlightEnvelopes[i][j].process();
                if(backlightEnvelopes[i][j].value > maxValue)
                    maxValue = backlightEnvelopes[i][j].value;
            }
            if(addValues[i] > maxValue) // If the addValue is set (!=0), use this as max value
                maxValue = addValues[i];

            backLightValues[i] = maxValue;
        }
    } else{
        if(p){
//            f.begin();
//                tex->drawSubsection(0, 0, size.x, size.y, loc.x, loc.y);
//            f.end();
            
//            f2.begin();
//                f.draw(0, 0, 1, 2);
//            f2.end();
//            f2.readToPixels(p);
            backLightValues[0] = p->getColor(pixelReadPos.x, pixelReadPos.y).getBrightness();
            backLightValues[1] = p->getColor(pixelReadPos.x, pixelReadPos.y + 1).getBrightness();
        }
    }
//    f.readToPixels(p);
//    img.setFromPixels(p);
//    img.setImageType(OF_IMAGE_GRAYSCALE);
//    img.resize(1, 1);
}

void lcdScreen::display(){
    ofSetColor(255);
    ofNoFill();
    ofDrawRectangle(loc.x, loc.y, size.x, size.y);
    
//    if(mode == 0){
    ofFill();
//    backLightValues[0] = 255;
    ofSetColor(backLightValues[0]);
    lcdOverlay.getTexture().drawSubsection(loc.x, loc.y, size.x, size.y*0.5, 0, 0);
//    ofDrawRectangle(loc.x, loc.y, size.x, size.y*0.5);
//    backLightValues[1] = 255;
    ofSetColor(backLightValues[1]);
//    ofDrawRectangle(loc.x, loc.y+size.y*0.5, size.x, size.y*0.5);
    lcdOverlay.getTexture().drawSubsection(loc.x, loc.y+size.y*0.5, size.x, size.y*0.5, 0, size.y*0.5);
    
//    } else{
//        ofSetColor(255);
//        f2.draw(loc.x, loc.y, size.x, size.y);
//    }

    if(bDisplayInfo){
        ofSetColor(255);
        ofDrawBitmapString(ofToString((int)id), loc.x+size.x*0.5, loc.y+size.y*0.5);
    }
    
    if(bSelected){
        ofSetColor(255, 0, 0);
        ofNoFill();
        ofDrawRectangle(loc.x-5, loc.y-5, size.x+10, size.y+10);
    }
}

bool lcdScreen::isMouseInside(int x, int y){
    ofRectangle r;
    r.setX(loc.x);
    r.setY(loc.y);
    r.setWidth(size.x);
    r.setHeight(size.y);
    return r.inside(x, y);
}

void lcdScreen::select(){
    bSelected = true;
}

void lcdScreen::deselect(){
    bSelected = false;
}

void lcdScreen::move(glm::vec2 distance){
    loc += distance;
}

void lcdScreen::backLightEnv(char backLightId, vector<float> values, vector<float> times){
    for(int i=0; i<values.size(); i++)
        cout << values[i] << endl;
    for(char i=0; i<8; i++){
        if(backlightEnvelopes[backLightId][i].active == false){
            backlightEnvelopes[backLightId][i].trigger(values, times);
            break;
        }
    }
}

void lcdScreen::parseMsg(ofxOscMessage& m){
    if(m.getArgType(1) == 98){ // New, raw syntax: same as send to ESP32
        cout << "Raw char buffer" << endl;
        ofBuffer msg = m.getArgAsBlob(1);
        unsigned char* data = new unsigned char[msg.size()];
        for(char i=0; i<msg.size(); i++){
            data[i] = (unsigned char)msg.getData()[i];
            cout << (int)data[i] << " ";
        }
        int numMsgs = (data[6]);
//        cout << "\nnumMsgs: " << numMsgs << endl;
        unsigned short readPos = 7; // Starts @ length-byte of msg
        for(int i=0; i<numMsgs; i++){
            parseArray(data, readPos);
            unsigned char msgLength = (data[readPos]);
//            cout << "msgLength: " << (int)msgLength << endl;
            readPos += msgLength;
        }
        cout << endl;
        delete[] data;
    } else{
        switch(m.getArgAsInt(1)){
            case 0: // SetVal
                    addValues[0] = addValues[1] = m.getArgAsInt(2);
                break;
            case 1: // SetValLag
    //            ofSerial
                break;
            case 2: // Whole backlight env
                // Should this reset the addVal!?
                backLightEnv(
                             0,
                             vector<float>{m.getArgAsFloat(2), m.getArgAsFloat(3), m.getArgAsFloat(4), m.getArgAsFloat(5)},
                             vector<float>{m.getArgAsFloat(6), m.getArgAsFloat(7), m.getArgAsFloat(8)}
                             );
                backLightEnv(
                             1,
                             vector<float>{m.getArgAsFloat(2), m.getArgAsFloat(3), m.getArgAsFloat(4), m.getArgAsFloat(5)},
                             vector<float>{m.getArgAsFloat(6), m.getArgAsFloat(7), m.getArgAsFloat(8)}
                             );
                break;
            case 3:
                fillRect(m.getArgAsFloat(2), m.getArgAsFloat(3), m.getArgAsFloat(4), m.getArgAsFloat(5), m.getArgAsInt(6), m.getArgAsInt(7), m.getArgAsInt(8));
                break;
        }
    }
}

void lcdScreen::parseArray(unsigned char* buffer, int readPos){
    unsigned short delayTime;
    memcpy(&delayTime, buffer + readPos + 1, 2);
    unsigned char msgId = *(buffer + readPos + 3);
    unsigned char type = *(buffer + readPos + 4);
    switch(type){
        case MSG_TEST:
            break;
        case MSG_BL_SET:{
            cout << "MSG_BL_SET" << endl;
            unsigned char ledID = *(buffer + readPos + 5);
            unsigned char value = *(buffer + readPos + 6);
            if(ledID == 2){ // Both
                addValues[0] = value;
                addValues[1] = value;
            } else{
                addValues[ledID] = value;
            }
        }
            break;
        case MSG_BL_LAG:{
            // Msg: led-id, value, lagTime[0], lagTime[1]
            unsigned char ledID = *(buffer + readPos + 5);
            unsigned char value = *(buffer + readPos + 6);
            unsigned short lagTime;
            memcpy(&lagTime, buffer + readPos + 7, 2);
            if(ledID == 2){
                for(char i=0; i<2; i++)
                    laggers[i].trigger(addValues[i], value, lagTime);
            } else{
                laggers[ledID].trigger(addValues[ledID], value, lagTime);
            }
        }
            break;
        case MSG_BL_ENV:{
            unsigned char ledID = *(buffer + readPos + 5);
            unsigned short attack, sustain, release;
            unsigned char value = *(buffer + readPos + 12);
            memcpy(&attack, buffer + readPos + 6, 2);
            memcpy(&sustain, buffer + readPos + 8, 2);
            memcpy(&release, buffer + readPos + 10, 2);
            if(ledID == 2){
                for(char i=0; i<2; i++){
                    backLightEnv(
                                 i,
                                 vector<float>{0, (float)value, (float)value, 0},
                                 vector<float>{(float)attack, (float)sustain, (float)release}
                                 );
                }
            } else{
            backLightEnv(
                         ledID,
                         vector<float>{0, (float)value, (float)value, 0},
                         vector<float>{(float)attack, (float)sustain, (float)release}
                         );
            }
        }
            break;
        case MSG_LCD_FILLRECT_SHOW:
        case MSG_LCD_FILLRECT:{
            unsigned char x = *(buffer + readPos + 5);
            unsigned char y = *(buffer + readPos + 6);
            unsigned char w = *(buffer + readPos + 7);
            unsigned char h = *(buffer + readPos + 8);
            unsigned char r = *(buffer + readPos + 9);
            unsigned char g = *(buffer + readPos + 10);
            unsigned char b = *(buffer + readPos + 11);
            fillRect(x / 255., y / 255., w / 255., h / 255., r, g, b); // Unsigned char becomes float ratio, gets multiplied by size[2];
        }
            break;
        case MSG_OTA_SINGLE:
            break;
        case MSG_OTA_SERVER:
            break;
        case EVENT_RECT:
            break;
        case EVENT_EXPRAND:
            break;
    }
//    cout << "delayTime: " << delayTime << endl;
//    cout << "msgID: " << (int)msgId << endl;
    
}

void lcdScreen::fillRect(float x, float y, float w, float h, int r, int g, int b){
    lcdOverlay.begin();
        ofSetColor(r * 255, g * 255, b * 255);
        ofFill();
        ofDrawRectangle(size.x * x, size.y * y, size.x * w, size.y * h);
    lcdOverlay.end();
}
