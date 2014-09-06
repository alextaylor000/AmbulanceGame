//
//  XXXScoreKeeper.m
//  CharacterTests
//
//  Created by Alex Taylor on 2014-09-05.
//  Copyright (c) 2014 Alex Taylor. All rights reserved.
//

#import "XXXScoreKeeper.h"

@implementation XXXScoreKeeper

+ (XXXScoreKeeper *)sharedInstance {
    static XXXScoreKeeper *_sharedInstance = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        _sharedInstance = [[XXXScoreKeeper alloc]init];
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

-(PatientSeverity)newPatientLevelRating:(NSInteger)rating numMedicalSupplies:(NSInteger)numMedicalSupplies timeToLive:(NSTimeInterval)timeToLive points:(NSInteger)points {
    
    PatientSeverity newPatient;
    newPatient.rating = rating;
    newPatient.numMedicalSupplies = numMedicalSupplies;
    newPatient.timeToLive = timeToLive;
    newPatient.points = points;
    
    return newPatient;
}


@end
