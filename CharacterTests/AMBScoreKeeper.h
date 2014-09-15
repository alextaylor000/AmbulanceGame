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


typedef enum {
    AmbulanceIsOccupied,
    AmbulanceIsEmpty
} AmbulanceState;


@interface AMBScoreKeeper : NSObject

@property (readonly) NSInteger score;
@property SKLabelNode *labelScore;

@property (readonly) PatientSeverity patientLevelOne;
@property (readonly) PatientSeverity patientLevelTwo;
@property (readonly) PatientSeverity patientLevelThree;
@property (readonly) PatientSeverity patientLevelFour;
@property (readonly) PatientSeverity patientLevelFive;

@property (readonly) NSArray *patientSeverityLevels; // an array of the levels above for when they need to be randomly selected

+ (AMBScoreKeeper *)sharedInstance;

/* Labels */
-(SKLabelNode *)createScoreLabelWithPoints:(NSInteger)points atPos:(CGPoint)position;


/* Scoring Events */
- (void) scoreEventPatientDeliveredPoints:(NSInteger)points timeToLive:(NSTimeInterval)timeToLive;

/* Misc. game logic */
- (PatientSeverity)randomPatientSeverity;

@end
