//
//  XXXScoreKeeper.h
//  CharacterTests
//
//  Created by Alex Taylor on 2014-09-05.
//  Copyright (c) 2014 Alex Taylor. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SpriteKit/SpriteKit.h>

/* Game rules used by other classes */
static const uint32_t categoryPlayer =      0x1 << 0;
static const uint32_t categoryPatient =     0x1 << 1;
static const uint32_t categoryHospital =    0x1 << 2;
static const uint32_t categoryTraffic =     0x1 << 3;

typedef struct {
    NSInteger rating;
    NSInteger numMedicalSupplies;
    NSTimeInterval timeToLive;
    NSInteger points;
} PatientSeverity;

typedef enum {
    PatientIsWaitingForPickup,
    PatientIsEnRoute,
    PatientIsDelivered,
    PatientIsDead
} PatientState;

typedef enum {
    AmbulanceIsOccupied,
    AmbulanceIsEmpty
} AmbulanceState;


@interface XXXScoreKeeper : NSObject

@property (readonly) NSInteger score;
@property SKLabelNode *labelScore;

@property (readonly) PatientSeverity patientLevelOne;
@property (readonly) PatientSeverity patientLevelTwo;
@property (readonly) PatientSeverity patientLevelThree;
@property (readonly) PatientSeverity patientLevelFour;
@property (readonly) PatientSeverity patientLevelFive;

@property (readonly) NSArray *patientSeverityLevels; // an array of the levels above for when they need to be randomly selected

+ (XXXScoreKeeper *)sharedInstance;

/* Labels */
-(SKLabelNode *)createScoreLabelWithPoints:(NSInteger)points atPos:(CGPoint)position;


/* Scoring Events */
- (void) scoreEventPatientDeliveredPoints:(NSInteger)points timeToLive:(NSTimeInterval)timeToLive;

/* Misc. game logic */
- (PatientSeverity)randomPatientSeverity;

@end
