//
//  AMBPatientSpawner.h
//  CharacterTests
//
//  Created by Alex Taylor on 2014-09-20.
//  Copyright (c) 2014 Alex Taylor. All rights reserved.
//

#import "AMBSpawner.h"

@interface AMBPatientSpawner : AMBSpawner

@property (nonatomic) NSInteger patientSeverity;
@property (nonatomic) NSInteger patientSeverityUpperRange; // used to randomize the severity of a spawned patient

- (instancetype)initPatientWithFirstSpawnAt:(NSTimeInterval)firstSpawnAt withFrequency:(NSTimeInterval)frequency frequencyUpperRange:(NSTimeInterval)frequencyUpperRange severity:(NSInteger)severity severityUpperRange:(NSInteger)severityUpperRange;




@end
