//
//  Env.cpp
//  Visualizer_2_4
//
//  Created by Jildert Viet on 25-09-17.
//
//

#include "Env.hpp"

Env::Env(){
    startTime = ofGetElapsedTimeMillis();
}

Env::~Env(){
    
}

Env::Env(vector<float> levels, vector<float> times){
    this->levels = levels; this->times = times; startTime = ofGetElapsedTimeMillis();
    totalRunTime = times[0]; getDirection();
}

void Env::trigger(vector<float> levels, vector<float> times){
    this->levels = levels; this->times = times; startTime = ofGetElapsedTimeMillis();
    totalRunTime = times[0]; getDirection();
    active = true; timesIndex = 0;
}

Env::Env(vector<float> levels, vector<float> times, float* f, char curve){
    this->levels = levels; this->times = times; ptr = new Pointer(f); this->curve = curve; startTime = ofGetElapsedTimeMillis();
    timesIndex = 0;
    totalRunTime = times[0]; getDirection();
}

Env::Env(vector<float> levels, vector<float> times, int* i, char curve){
    this->levels = levels; this->times = times; ptr = new Pointer(i); this->curve = curve; startTime = ofGetElapsedTimeMillis(); totalRunTime = times[0]; getDirection();
}

Env::Env(vector<float> levels, vector<float> times, ofColor* c, char curve){
    this->levels = levels; this->times = times; ptr = new Pointer(c); this->curve = curve; startTime = ofGetElapsedTimeMillis();
    totalRunTime = times[0]; getDirection();
}

bool Env::process(){
    if(active){
//        cout << "timesIndex: " << timesIndex << endl;
//        cout << times[timesIndex] << endl;
        if(ofGetElapsedTimeMillis() > startTime + totalRunTime){
            timesIndex++;
            if(timesIndex >= times.size()){
                if(ptr)
                    ptr->writeValue(levels[timesIndex]);
                if(!loop){
                    active = false;
                    if(ptr)
                        ptr->writeValue(levels.back());
                    value = levels.back();
                    return false;
                } else{
                    timesIndex = 0;
                    startTime = ofGetElapsedTimeMillis();
                    totalRunTime = times[0]; getDirection();
                    return true;
                }
            }
//            getDirection(timesIndex);
            totalRunTime += times[timesIndex];
//            cout << "totalRunTime: " << totalRunTime << endl;
        }
        
        // Get ratio:
        float ratio;
        ratio = ((int)ofGetElapsedTimeMillis() - startTime - totalRunTime + times[timesIndex]);
        ratio /= times[timesIndex];
        
        value = levels[timesIndex] + ofMap(ratio, 0., 1., 0., levels[timesIndex+1]-levels[timesIndex]);
        
        if(ptr)
            ptr->writeValue(value);
    }
    return true;
}

void Env::getDirection(uint8 ti){
    if(levels[ti] - levels[ti+1] < 0){
        // Direction is up
        direction = 1;
    } else{
        direction = 0;
    }
//    cout << "direction: " << direction << endl;
}

void Env::setLoop(bool b){
    loop = b;
}

void Pointer::writeValue(float value){
    if(valF){
        *valF = value;
        //        cout << "Write float to: " << value << endl;
    } else if(valI){
        *valI = value;
    } else if(valC){
        ofColor c = *valC;
        c.a = value;
        //        cout << c << endl;
        (*valC) = c;
    }
}

void* Pointer::getPtr(){
    if(valF){
        return valF;
    } else if(valI){
        return valI;
    } else if(valC){
        return valC;
    }
return nullptr;
}
