//
//  XXXScoreKeeper.m
//  CharacterTests
//
//  Created by Alex Taylor on 2014-09-05.
//  Copyright (c) 2014 Alex Taylor. All rights reserved.
//

#import "AMBScoreKeeper.h"
#import "AMBLevelScene.h" // TODO: decouple scene
#import "SKTUtils.h" // for RandomFloatRange

@implementation AMBScoreKeeper

/**
 Instantiates a ScoreKeeper instance, and ensures that only one instance can be created.
 */
+ (AMBScoreKeeper *)sharedInstance {
    static AMBScoreKeeper *_sharedInstance = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        _sharedInstance = [[AMBScoreKeeper alloc]init];
    });
    
    return _sharedInstance;
}

-(id)init {
    if (self = [super init]) {
        /* Initialize anything needed for game logic */
        _score = 0;

        // patient severity levels
        _patientLevelOne =      [self newPatientLevelRating:1 numMedicalSupplies:5 timeToLive:60 points:100];
        _patientLevelTwo =      [self newPatientLevelRating:2 numMedicalSupplies:10 timeToLive:50 points:200];
        _patientLevelThree =    [self newPatientLevelRating:3 numMedicalSupplies:15 timeToLive:40 points:300];
        _patientLevelFour =     [self newPatientLevelRating:4 numMedicalSupplies:20 timeToLive:30 points:400];
        _patientLevelFive =     [self newPatientLevelRating:5 numMedicalSupplies:25 timeToLive:20 points:500];
        
    }
    
   return self;
}

-(SKLabelNode *)createScoreLabelWithPoints:(NSInteger)points atPos:(CGPoint)position {
    
    _labelScore = [SKLabelNode labelNodeWithFontNamed:@"Courier-Bold"];
    _labelScore.horizontalAlignmentMode = SKLabelHorizontalAlignmentModeLeft;
    _labelScore.text = [NSString stringWithFormat:@"SCORE: %ld", (long)points];
    _labelScore.fontColor = [SKColor yellowColor];
    
    _labelScore.position = position;
    
    _labelScore.zPosition = 999;
    
    return _labelScore;

}

-(void)updateScoreLabelWithPoints:(NSInteger)points {
    _labelScore.text = [NSString stringWithFormat:@"SCORE: %ld", (long)points];
}


-(PatientSeverity)newPatientLevelRating:(NSInteger)rating numMedicalSupplies:(NSInteger)numMedicalSupplies timeToLive:(NSTimeInterval)timeToLive points:(NSInteger)points {
    
    PatientSeverity newPatient;
    newPatient.rating = rating;
    newPatient.numMedicalSupplies = numMedicalSupplies;
    newPatient.timeToLive = timeToLive;
    newPatient.points = points;
    
    return newPatient;
}

- (void) updateScore:(NSInteger)points {
    _score += points;
    
    // TODO: decouple the label update, maybe through delegation?
    [self updateScoreLabelWithPoints:_score];

    #if DEBUG
        NSLog(@"[[    SCORE:   %ld    ]]", (long)_score);
    #endif

}

#pragma mark Scoring Events
- (void) scoreEventPatientDeliveredPoints:(NSInteger)points timeToLive:(NSTimeInterval)timeToLive {
    [self updateScore:points];
}

#pragma mark Misc. Game Logic
//- (PatientSeverity)randomPatientSeverity {
//    NSInteger numSeverityLevels = [_patientSeverityLevels count];
//    NSUInteger randIndex = RandomFloatRange(0, numSeverityLevels - 1);
//
//}


@end
