//
//  AMBPatient.h
//  CharacterTests
//
//  Created by Alex Taylor on 2014-08-30.
//  Copyright (c) 2014 Alex Taylor. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>
#import "AMBCharacter.h"
#import "AMBTimer.h"

typedef enum {
    PatientIsWaitingForPickup,
    PatientIsEnRoute,
    PatientIsDelivered,
    PatientIsDead
} PatientState;

typedef enum {
    LevelOne = 1,
    LevelTwo,
    LevelThree,
    RandomSeverity
} PatientSeverity;


@interface AMBPatient : AMBCharacter

//@property CGPoint position;
@property PatientSeverity severity;
@property PatientState state;
@property AMBTimer *patientTimer;


+ (instancetype) patientWithSeverity:(PatientSeverity)severity;
- (instancetype) initWithSeverity:(PatientSeverity)severity position:(CGPoint)position;
- (void)updatePatient;
- (void)changeState:(PatientState)newState;
- (NSTimeInterval)getPatientTTL;

@end
