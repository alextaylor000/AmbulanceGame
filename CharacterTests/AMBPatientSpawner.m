//
//  AMBPatientSpawner.m
//  CharacterTests
//
//  Created by Alex Taylor on 2014-09-20.
//  Copyright (c) 2014 Alex Taylor. All rights reserved.
//

#import "AMBPatientSpawner.h"

@implementation AMBPatientSpawner

- (instancetype)initPatientWithFirstSpawnAt:(NSTimeInterval)firstSpawnAt withFrequency:(NSTimeInterval)frequency frequencyUpperRange:(NSTimeInterval)frequencyUpperRange severity:(NSInteger)severity severityUpperRange:(NSInteger)severityUpperRange {
    
    if (self = [super initWithFirstSpawnAt:firstSpawnAt withFrequency:frequency frequencyUpperRange:frequencyUpperRange]) {
        
        _patientSeverity = severity;
        _patientSeverityUpperRange = severityUpperRange;
        
    }
    
    return self;
}


- (void)fireSpawnEvent {
    //
}

@end
