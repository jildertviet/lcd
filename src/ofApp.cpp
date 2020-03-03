#include "ofApp.h"

//--------------------------------------------------------------
void ofApp::setup(){
    glm::vec2 size(1280, 800);
    ofSetWindowShape(size.x, size.y);
    
    visualizer = new Visualizer(size);
    visualizer->fitFadeScreen(size); // Also on window-resize!?
    

    smallerFbo.allocate(visualizer->fbo.getWidth() / 10, visualizer->fbo.getHeight() / 10, GL_RGBA); // Doesn't really make it faster...
    p.allocate(smallerFbo.getWidth(), smallerFbo.getHeight(), 4);
    
    database.load("database.csv");
    for(int i=0; i<database.getNumRows(); i++){
        screens.push_back(
                          lcdScreen(
                                    database.getRow(i).getInt(0),
                                    glm::vec2(database.getRow(i).getFloat(1), database.getRow(i).getFloat(2)),
                                    glm::vec2(database.getRow(i).getFloat(3), database.getRow(i).getFloat(4))
                                    )
                          );
        screens.back().p = &p;
        screens.back().sender = &SCsenderII;
        screens.back().pixelReadPos = ((screens.back().loc + (screens.back().size * 0.5))/size) * glm::vec2(p.getWidth(), p.getHeight());
    }
    cout << "num screens: " << screens.size() << endl;
    newScreenGUI.setup("Add new screen");
    newScreenGUI.add(idInput.setup("id", 0));
    newScreenGUI.add(locXInput.setup("locX", 0));
    newScreenGUI.add(locYInput.setup("locY", 0));
    newScreenGUI.add(sizeXInput.setup("sizeX", 39));
    newScreenGUI.add(sizeYInput.setup("sizeY", 30));
    newScreenGUI.add(submitNewButton.setup("submit"));
    submitNewButton.addListener(this, &ofApp::addNewScreen);
    
    gui.setup("");
    gui.add(contrast.setup("contrast", 1, 0, 10.));
//    std::exit(0);
    ofSetFrameRate(60);
    receiver.setup(5555);
    
    parser = new MsgParser(visualizer);
    
    GUIreceiver.setup(6060);
    SCreceiver.setup(6061);
    SCsenderII.setup("127.0.0.1", 3456);
    
    spaceNavReceiver.setup(8609);
    visualizer->receiver.setup(4040);
    parser->SCsender = &SCsender;
    visualizer->SCsender = &SCsender;
    if(!shader.load("shaders/brightnessAndSaturation")){
        cout << "Failed to load shader" << endl;
    }
}

//--------------------------------------------------------------
void ofApp::update(){
    ofSetWindowTitle(ofToString(ofGetFrameRate()));
    while(SCreceiver.hasWaitingMessages()){
        msg.clear();
        SCreceiver.getNextMessage(msg);
        if(!bSCClientSet){
            SCsender.setup(msg.getRemoteHost(), 6063);
            bSCClientSet = true;
        }
        parser->parseMsg(msg);
        receive(msg);
    }
    while(GUIreceiver.hasWaitingMessages()){
        msg.clear();
        GUIreceiver.getNextMessage(msg);
        if(!bGUIClientSet){
            GUIsender.setup(msg.getRemoteHost(), 6062);
            bGUIClientSet = true;
        }
        receive(msg);
    }
    while(spaceNavReceiver.hasWaitingMessages()){
        msg.clear();
        spaceNavReceiver.getNextMessage(msg);
//        receiveSpaceNav(msg);
    }

    while(receiver.hasWaitingMessages()){
        ofxOscMessage m;
        receiver.getNextMessage(m);
        if(m.getAddress() == "/setMode"){ // Global control msg from SC
            for(int i=0; i<screens.size(); i++)
                screens[i].mode = m.getArgAsInt(0);
        } else if(m.getAddress() == "/setContrast"){
            contrast = m.getArgAsFloat(0);
        } else{
            screens[m.getArgAsInt(0)].parseMsg(m); // Old syntax
        }
    }
    
    visualizer->update();
    smallerFbo.begin();
    shader.begin();
        shader.setUniform1f("contrast", contrast);
        shader.setUniform1f("brightness", shaderBrightnessAdd);
        visualizer->fbo.draw(0, 0, smallerFbo.getWidth(), smallerFbo.getHeight());
        shader.end();
    smallerFbo.end();
    smallerFbo.readToPixels(p);
    
    for(int i=0; i<screens.size(); i++)
        screens[i].update();
    
    if(bSendToSC){
        // Send all values per screen as an array?
        ofxOscMessage m;
        m.setAddress("/fromVisualizer");
        for(int i=0; i<screens.size(); i++){
            m.addIntArg(screens[i].backLightValues[0]);
            m.addIntArg(screens[i].backLightValues[1]);
        }
        SCsenderII.sendMessage(m);
    }
    
//    if(ofGetFrameNum() % 60 == 0){
//        cout << "frameRate: " << ofToString(ofGetFrameRate()) << endl;
//    }
}

//--------------------------------------------------------------
void ofApp::draw(){
    ofBackground(0);
//    visualizer->display();

    if(bShowFbo)
        smallerFbo.draw(0, 0, ofGetWidth(), ofGetHeight());
    for(int i=0; i<screens.size(); i++)
        screens[i].display();
    
    ofSetColor(255);
    if(bDisplayGui)
        newScreenGUI.draw();
    if(bDrawGui)
        gui.draw();
}

void ofApp::exit(){
    submitNewButton.removeListener(this, &ofApp::addNewScreen);
    cout << "Save all to csv" << endl;
    database.load("database.csv");
    database.clear();
    for(int i=0; i<screens.size(); i++){
        ofxCsvRow r;
        r.addInt(screens[i].id);
        r.addFloat(screens[i].loc.x);
        r.addFloat(screens[i].loc.y);
        r.addFloat(screens[i].size.x);
        r.addFloat(screens[i].size.y);
        database.addRow(r);
    }
    database.save();
}

//--------------------------------------------------------------
void ofApp::keyPressed(int key){
    switch(key){
        case OF_KEY_RIGHT:
            if(selectedScreen)
                selectedScreen->move(glm::vec2(10, 0));
            break;
        case OF_KEY_LEFT:
            if(selectedScreen)
                selectedScreen->move(glm::vec2(-10, 0));
            break;
        case OF_KEY_UP:
            if(selectedScreen)
                selectedScreen->move(glm::vec2(0, -10));
            break;
        case OF_KEY_DOWN:
            if(selectedScreen)
                selectedScreen->move(glm::vec2(0, 10));
            break;
        case OF_KEY_BACKSPACE:
            if(selectedScreen)
                removeSelected();
                break;
        case 'n':
            if(bDisplayGui){ // Toggle
                bDisplayGui = false;
                break;
            }
            idInput = screens.size();
            bDisplayGui = true;
            break;
        case 't':
            screens[ofRandom(screens.size())].backLightEnv(ofRandom(2), vector<float>{0, 255, 255, 0}, vector<float>{10, 1000, 1000});
            break;
        case 'i':{
            for(int i=0; i<screens.size(); i++){
                screens[i].bDisplayInfo = !screens[i].bDisplayInfo;
            }
        }
            break;
        case 'v':
            bShowFbo = !bShowFbo;
            break;
        case 'g':
            bDrawGui = !bDrawGui;
            break;
    }
}

//--------------------------------------------------------------
void ofApp::keyReleased(int key){

}

//--------------------------------------------------------------
void ofApp::mouseMoved(int x, int y ){

}

//--------------------------------------------------------------
void ofApp::mouseDragged(int x, int y, int button){
    if(selectedScreen)
        selectedScreen->loc = glm::vec2(x, y) - (selectedScreen->size * 0.5); // Center based
}

//--------------------------------------------------------------
void ofApp::mousePressed(int x, int y, int button){
    bool bAnythingSelected = false;
    for(int i=0; i<screens.size(); i++){
        if(screens[i].isMouseInside(x, y)){
            cout << "CLICK" << endl;
            screens[i].select();
            selectedScreen = &screens[i];
            bAnythingSelected = true;
        } else{
            screens[i].deselect();
        }
    }
    if(!bAnythingSelected)
        selectedScreen = nullptr;
}

//--------------------------------------------------------------
void ofApp::mouseReleased(int x, int y, int button){

}

//--------------------------------------------------------------
void ofApp::mouseEntered(int x, int y){

}

//--------------------------------------------------------------
void ofApp::mouseExited(int x, int y){

}

//--------------------------------------------------------------
void ofApp::windowResized(int w, int h){

}

//--------------------------------------------------------------
void ofApp::gotMessage(ofMessage msg){

}

//--------------------------------------------------------------
void ofApp::dragEvent(ofDragInfo dragInfo){ 

}

void ofApp::addNewScreen(){
    cout << "Add new" << endl;
    bDisplayGui = false;
    char id = idInput; // Check if ID is unique?
    bool bUniqueID = false;
    while(!bUniqueID){
        bUniqueID = true;
        for(int i=0; i<screens.size(); i++){
            if(screens[i].id == id){
                bUniqueID = false;
                id += 1;
                break; // Break for, not while...
            }
        }
    }
    glm::vec2 loc = glm::vec2((int)locXInput, (int)locYInput);
    glm::vec2 size = glm::vec2((int)sizeXInput, (int)sizeYInput) * 2;
    screens.push_back(lcdScreen(id, loc, size));
    screens.back().p = &p;
    screens.back().sender = &SCsenderII;
    screens.back().pixelReadPos = (screens.back().loc/size) * glm::vec2(p.getWidth(), p.getHeight());
}

void ofApp::removeSelected(){
    int index = 0;
    for(int i=0; i<screens.size(); i++){
        if(&screens[i] == selectedScreen){
            index = i;
            break;
        }
    }
    screens.erase(screens.begin() + index);
}

void ofApp::receive(ofxOscMessage m){
//    cout << "r" << endl;
    string a = m.getAddress();
    if(a == "/DeviceNote" || a == "/GUI"){
        if(song)
            song->doFunc(m.getArgAsInt(0)); // func(int)
    } else if (a == "/DeviceControl"){
        if(song)
            song->doControlFunc(m.getArgAsInt(0), m.getArgAsInt(1));
    } else if(a == "/loadSong"){
        loadSong(m.getArgAsString(0));
    } else if(a == "/setFade"){
        visualizer->fade->setBrightness(m.getArgAsInt(0));
    } else if(a == "/killAll"){
        visualizer->killAll();
    } else if(a == "/bMirror"){
        visualizer->bAddMirror = !(visualizer->bAddMirror);
    } else if(a == "/requestColors"){
        if(song){
            cout << "Received /requestColors" << endl;
            ofxOscMessage m;
            m = song->getColorsAsOSC();
            m.setAddress("/fromVisualizer");
            //            m.addStringArg(song->getColorsAsJson().getRawString());
            GUIsender.sendMessage(m, false);
        }
    } else if(a == "/setColor"){
        cout << "setColor" << endl;
        int index = m.getArgAsInt(0);
        ofColor color = ofColor(m.getArgAsInt(1), m.getArgAsInt(2), m.getArgAsInt(3), m.getArgAsInt(4));
        if(song)
            song->setColor(index, color);
    } else if(a == "/setBackground"){
        ofColor c = ofColor(m.getArgAsInt(0), m.getArgAsInt(1), m.getArgAsInt(2));
        visualizer->alphaScreen->setColor(c);
        visualizer->alphaScreen->setActiveness(true);
    } else if(a == "/setMaskBrightness"){
        //        cout << m.getArgAsInt(0) << endl;
        unsigned char b = m.getArgAsInt(0);
        if(b == 0){
            visualizer->bMask = false;
        } else{
            if(!visualizer->bMask){
                visualizer->bMask = true;
            }
            visualizer->maskBrightness = b;
        }
    } else if(a == "/loadMask"){
        visualizer->mask.load(m.getArgAsString(0));
        ofFile f;
        f.open("./maskFile.txt", ofFile::Mode::WriteOnly); // Save the path as a default for next start-up :)
        f.clear();
        ofBuffer b;
        b.set(m.getArgAsString(0));
        cout << "Load mask: " << m.getArgAsString(0) << endl;
        f.writeFromBuffer(b);
        f.close();
    } else if(a == "/cmd"){
        if(m.getArgAsString(0) == "make"){
            if(m.getArgAsString(1) == "imageFloat"){
                Event* iF;
                iF = new imageFloat(m.getArgAsString(2));
                visualizer->addEvent(iF);
            } else if(m.getArgAsString(1) == "imageFloaterH" || m.getArgAsString(1) == "imageFloaterV"){
                if(m.getNumArgs() > 5){
                    imageFloater* img;
                    imageFloat* src = (imageFloat*)visualizer->getEventById(m.getArgAsInt(2));
                    bool bHorizontal = false;
                    if(m.getArgAsString(1) == "imageFloaterH")
                        bHorizontal = true;
                    if(src){
                        img = new imageFloater(src);
                        img->loc = ofVec3f(m.getArgAsFloat(3), m.getArgAsFloat(4), m.getArgAsFloat(5));
                        img->size = ofVec3f(m.getArgAsFloat(6), m.getArgAsFloat(7), 0);
                        img->addEnvAlpha(visualizer->vec(0, m.getArgAsFloat(11), 0), visualizer->vec(m.getArgAsFloat(8), m.getArgAsFloat(9), m.getArgAsFloat(10)),  0);
                        img->direction = ofVec3f(m.getArgAsFloat(12), m.getArgAsFloat(13), 0);
                        img->speed = m.getArgAsFloat(14);
                        if(bHorizontal){
                            img->roiSpeed = ofVec2f(ofRandom(0.1, 1.0) - 0.5, 0.);
                            img->roi = ofVec2f(ofRandom(src->getWidth() - img->size.x), 0.); //
                        } else{
                            img->roiSpeed = ofVec2f(0, ofRandom(0.1, 1.0) - 0.5);
                            img->roi = ofVec2f(0., ofRandom(src->getHeight() - img->size.y)); //
                        }
                        visualizer->addEvent((Event*)img);
                    } else{
                        cout << "Img src is nullptr" << endl;
                    }
                }
            } else if(m.getArgAsString(1) == "jText"){
                jText* txt = new jText(&visualizer->verdana30);
                txt->txt = m.getArgAsString(2);
                txt->loc = ofVec2f(m.getArgAsFloat(3), m.getArgAsFloat(4));
                txt->addEnvAlpha(visualizer->vec(0, m.getArgAsFloat(8), 0), visualizer->vec(m.getArgAsFloat(5), m.getArgAsFloat(6), m.getArgAsFloat(7)),  0);
                txt->setColor(ofColor(m.getArgAsFloat(9), m.getArgAsFloat(10), m.getArgAsFloat(11)));
                visualizer->addEvent((Event*)txt);
            }
        } else if(m.getArgAsString(0) == "/camRotEnv"){
            float dur = m.getArgAsFloat(1);
            dur *= 0.5;
            float max = m.getArgAsFloat(2);
            vector<float> values = {0., max, 0.};
            vector<float> times = {dur, dur};
            visualizer->camController->addEnv(values, times, &(visualizer->camController->rotationSpeed.x), 0);
        } else if(m.getArgAsString(0) == "/camBoomEnv"){
            float dur = m.getArgAsFloat(1);
            dur *= 0.5;
            float max = m.getArgAsFloat(2);
            vector<float> values = {0., max, 0.};
            vector<float> times = {dur, dur};
            visualizer->camController->addEnv(values, times, &(visualizer->camController->boomSpeed), 0);
        } else if(m.getArgAsString(0) == "/camTruckEnv"){
            float dur = m.getArgAsFloat(1);
            dur *= 0.5;
            float max = m.getArgAsFloat(2);
            vector<float> values = {0., max, 0.};
            vector<float> times = {dur, dur};
            visualizer->camController->addEnv(values, times, &(visualizer->camController->truckSpeed), 0);
        } else if(m.getArgAsString(0) == "/camDollyEnv"){
            float dur = m.getArgAsFloat(1);
            dur *= 0.5;
            float max = m.getArgAsFloat(2);
            vector<float> values = {0., max, 0.};
            vector<float> times = {dur, dur};
            visualizer->camController->addEnv(values, times, &(visualizer->camController->dollySpeed), 0);
        }
    } else if(a == "/getAllEvents"){
        ofxOscMessage m = visualizer->getAllEvents(); // '/allEvents'
        GUIsender.sendMessage(m);
    }
}

void ofApp::loadSong(string name){
    cout << "Load song: " << name << endl;
    
    bool bStop = true;
    for(int i=0; i<songs.size(); i++){
        if(name==songs[i]){
            bStop = false;
        }
    }
    if(bStop){
        cout << "Song not found" << endl;
        return;
    }
    
    if(song){
        song->exit();
        visualizer->initCam();
        delete song;
    }
    
    if(name=="Faith"){
        song = new Faith(visualizer);
    } else if(name=="Figgie"){
        song = new Figgie(visualizer);
    } else if(name=="Juncture"){
        song = new Juncture(visualizer);
    } else if(name=="MamaOtis"){
        song = new MamaOtis(visualizer);
    } else if(name=="MaybeTomorrow"){
        song = new MaybeTomorrow(visualizer);
    } else if(name=="TimeForYou"){
        song = new TimeForYou(visualizer);
    } else if(name=="JustBefore"){
        song = new JustBefore(visualizer);
    } else if(name=="BendStraws"){
        song = new BendStraws(visualizer);
    } else if(name=="TeachMe"){
        song = new TeachMe(visualizer);
    } else if(name=="CounterParts"){
        song = new CounterParts(visualizer);
    } else if(name=="Trying"){
        song = new Trying(visualizer);
    } else if(name=="Laura"){
        song = new Laura(visualizer);
    } else if(name=="Start"){
        song = new Start(visualizer);
    } else if(name=="NewOpener"){
        song = new NewOpener(visualizer);
    } else if(name=="OnlyYours"){
        song = new OnlyYours(visualizer);
    } else if(name=="GlassHouse"){
        song = new GlassHouse(visualizer);
    } else if(name =="videoBars"){
        song = new videoBars(visualizer);
    } else if(name == "Spheres"){
        song = new Spheres(visualizer);
    } else if(name == "verses"){
        song = new verses(visualizer);
    } else if(name == "model"){
        song = new model(visualizer);
    }
    //    ofSetWindowShape(ofGetWidth(), ofGetHeight());
}
