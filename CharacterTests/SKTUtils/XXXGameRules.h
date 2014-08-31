//
//  XXXGameRules.h
//  CharacterTests
//
//  Created by Alex Taylor on 2014-08-30.
//  Copyright (c) 2014 Alex Taylor. All rights reserved.
//

#pragma mark PATIENT - Severity
typedef struct {
    // Patient Severity
    NSInteger rating;
    NSInteger numMedicalSupplies;
    NSTimeInterval timeToLive;
} PatientSeverity;

extern PatientSeverity const LevelOne;
extern PatientSeverity const LevelTwo;
extern PatientSeverity const LevelThree;
extern PatientSeverity const LevelFour;
extern PatientSeverity const LevelFive;

#pragma mark PATIENT - State
typedef enum {
    WaitingForPickup,
    EnRoute,
    Delivered,
    Dead
} PatientState;






