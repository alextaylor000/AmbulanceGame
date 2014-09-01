//
//  XXXScore.m
//  CharacterTests
//
//  Created by Alex Taylor on 2014-09-01.
//  Copyright (c) 2014 Alex Taylor. All rights reserved.
//

#import "XXXScore.h"


@implementation XXXScore

- (id)init {
    if (self = [super init]) {
        _currentScore = 0;
    }
    
    return self;
}


- (void)updateScore:(NSInteger)score {
    _currentScore += score;
    
    #if DEBUG
        NSLog(@"[[    SCORE:   %ld    ]]", (long)_currentScore);
    #endif
}


- (BOOL)deliverPatientInAmbulance:(XXXCharacter *)ambulance {
    /* called when a patient is dropped off at a hospital

        - the patient needs to be in an ambulance;
        - the patient's time-to-live must still be positive
    */

    XXXPatient *patient = ambulance.patient;
    if (patient) {
        // update the scores
        [self updateScore:patient.severity.points]; // TODO: add a multiplier for speed getting patient to hospital; the higher their time-to-live, the more points
        
        
        #if DEBUG
        NSLog(@"patient delivered!");
        #endif
        
        // unload the patient
        [ambulance unloadPatient];
    }
    
    return NO;
}

@end
