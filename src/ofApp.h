#pragma once

#include "ofMain.h"
#include "ofxOsc.h"
#include "ofxCsv.h"
#include "lcdScreen.hpp"
#include "ofxGui.h"
#include "Visualizer.hpp"
#include "MsgParser.hpp"


#include "Song.hpp"

#include "Figgie.hpp"
#include "TimeForYou.hpp"
#include "Faith.hpp"
#include "MamaOtis.hpp"
#include "MaybeTomorrow.hpp"
#include "Juncture.hpp"
#include "JustBefore.hpp"
#include "TeachMe.hpp"
#include "BendStraws.hpp"
#include "CounterParts.hpp"
#include "Trying.hpp"
#include "eLive.hpp"
#include "Laura.hpp"
#include "Start.hpp"
#include "NewOpener.hpp"
#include "OnlyYours.hpp"
#include "GlassHouse.hpp"
#include "videoBars.hpp"
#include "Spheres.hpp"
#include "verses.hpp"
#include "model.hpp"
#include "imageFloat.hpp"
#include "jTxt.hpp"

class ofApp : public ofBaseApp{

	public:
		void setup();
		void update();
		void draw();
        void exit();
    
		void keyPressed(int key);
		void keyReleased(int key);
		void mouseMoved(int x, int y );
		void mouseDragged(int x, int y, int button);
		void mousePressed(int x, int y, int button);
		void mouseReleased(int x, int y, int button);
		void mouseEntered(int x, int y);
		void mouseExited(int x, int y);
		void windowResized(int w, int h);
		void dragEvent(ofDragInfo dragInfo);
		void gotMessage(ofMessage msg);
		
    ofxCsv database;
    vector<lcdScreen> screens;
    lcdScreen* selectedScreen = nullptr;
    
    bool bDisplayGui = false;
    ofxPanel newScreenGUI;
    ofxIntField idInput, locXInput, locYInput, sizeXInput, sizeYInput;
    ofxButton submitNewButton;
    void addNewScreen();
    
    void removeSelected();
    
    ofxOscReceiver receiver;
    ofFbo smallerFbo;
    ofPixels p;
    
    Visualizer* visualizer = nullptr;
    ofxOscReceiver GUIreceiver;
    ofxOscReceiver SCreceiver;
    ofxOscReceiver spaceNavReceiver;
    ofxOscSender GUIsender;
    ofxOscSender SCsenderII;
    bool bSendToSC = true;
    ofxOscSender SCsender;
    ofxOscMessage msg;
    bool bSCClientSet = false;
    bool bGUIClientSet = false;
    MsgParser* parser;
    void receive(ofxOscMessage m);
    Song* song;
    void loadSong(string name);
    vector<string> songs = {
        "Faith",
        "Figgie",
        "Juncture",
        "MamaOtis",
        "MaybeTomorrow",
        "TimeForYou",
        "JustBefore",
        "BendStraws",
        "TeachMe",
        "CounterParts",
        "Trying",
        "eLive",
        "Laura",
        "Start",
        "NewOpener",
        "OnlyYours",
        "GlassHouse",
        "videoBars",
        "Spheres",
        "verses",
        "model"
    };
    bool bShowFbo = false;
    ofShader shader;
    float shaderContrast = 1;
    ofxPanel gui;
    bool bDrawGui = true;
    ofxFloatSlider contrast;
    int shaderBrightnessAdd = 0;
};
