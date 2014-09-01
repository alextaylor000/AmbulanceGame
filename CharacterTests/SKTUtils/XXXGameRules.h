//
//  XXXGameRules.h
//  CharacterTests
//
//  Created by Alex Taylor on 2014-08-30.
//  Copyright (c) 2014 Alex Taylor. All rights reserved.
//
/*
 
 Encapsulates everything to do with points, scores and states within the game world. Keeping all this logic in one class allows easy balancing of the game and tweaking of rules.
 
 This class probably won't ever have any methods, it's just a place to store global variables and structures.
 
 */



#pragma mark SCENE - Collisions
static const uint32_t categoryPlayer =      0x1 << 0;
static const uint32_t categoryPatient =     0x1 << 1;
static const uint32_t categoryHospital =    0x1 << 2;
static const uint32_t categoryTraffic =     0x1 << 3;


#pragma mark PATIENT - Severity
typedef struct {
    // Patient Severity
    NSInteger rating;
    NSInteger numMedicalSupplies;
    NSTimeInterval timeToLive;
    NSInteger points;
} PatientSeverity;

extern PatientSeverity const LevelOne;
extern PatientSeverity const LevelTwo;
extern PatientSeverity const LevelThree;
extern PatientSeverity const LevelFour;
extern PatientSeverity const LevelFive;


#pragma mark PATIENT - State
typedef enum {
    PatientIsWaitingForPickup,
    PatientIsEnRoute,
    PatientIsDelivered,
    PatientIsDead
} PatientState;

#pragma mark AMBULANCE - State
typedef enum {
    AmbulanceIsOccupied,
    AmbulanceIsEmpty
} AmbulanceState;





