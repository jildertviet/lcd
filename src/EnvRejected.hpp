//
//  Env.hpp
//  Visualizer_2_4
//
//  Created by Jildert Viet on 25-09-17.
//
//

#ifndef Env_hpp
#define Env_hpp

#include <stdio.h>
#include "ofMain.h"

class Pointer{
public:
    Pointer(float* valF){
        this->valF = valF;
    }
    Pointer(int* valI){
        this->valI = valI;
    }
    Pointer(ofColor* valC){
        this->valC = valC;
    }
    
    void writeValue(float value);
    
    float* valF = nullptr;
    int* valI = nullptr;
    ofColor* valC = nullptr;
    int id;
    
    void* getPtr();
};

class Env{
public:
typedef unsigned char uint8;
    Env();
    ~Env();
    Env(vector<float> levels, vector<float> times);
    Env(vector<float> levels, vector<float> times, float* f, char curve);
    Env(vector<float> levels, vector<float> times, int* i, char curve);
    Env(vector<float> levels, vector<float> times, ofColor* c, char curve);
    
    void trigger(vector<float> levels, vector<float> times);
    uint8 id = 0;
    
    vector<float> levels;
    vector<float> times;
    int totalRunTime = 0;
    uint8 timesIndex = 0;
    bool process();
    Pointer* ptr = nullptr;
    float value = 0;
    int startTime;
    bool active = false;
    char curve = 0;
    bool direction = 1;
    
    void getDirection(uint8 ti = 0);
    void setLoop(bool b = true);
    
    // For saving the env to a file... (To use in Blender w/ Python)
    bool bSave = false;
    float* saveBuffer = nullptr;
    string fileName = "";
    int saveBufferWritePos = 0;
    int saveBufferSize = 0;
    unsigned int* parentID = nullptr;
private:
    bool loop = false;
};
#endif /* Env_hpp */
