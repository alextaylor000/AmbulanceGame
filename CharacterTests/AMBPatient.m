//
//  AMBPatient.m
//  CharacterTests
//
//  Created by Alex Taylor on 2014-08-30.
//  Copyright (c) 2014 Alex Taylor. All rights reserved.

/*
 
 Patient Class
 
 Properties:
 - Severity Rating 
    - # medical supplies (defined elsewhere through severity)
    - Time to Live (defined elsewhere through severity)
 - Position
 - Sprite object (before they're picked up)
 - State
    - waiting for pickup
    - picked up
    - delivered
    - died
 
 
*/

#import "SKTUtils.h" // for RandomFloatRange
#import "AMBPatient.h"

@interface AMBPatient ()

@property CGFloat lifetime;

@end

@implementation AMBPatient

#pragma mark Assets
+ (void)loadSharedAssets {
    [super loadSharedAssets];
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // load shared assets here!
    });
}

+ (instancetype) patientWithSeverity:(PatientSeverity)severity {
    AMBPatient *patient = [[AMBPatient alloc]initWithSeverity:severity position:CGPointZero];
    return patient;
}

- (instancetype) initWithSeverity:(PatientSeverity)severity position:(CGPoint)position {
    NSString *patientImage = [NSString stringWithFormat:@"patient%ld.png", (long)severity];
    
    // TODO: load all graphics from atlases
    SKTexture *patientTexture = [SKTexture textureWithImageNamed:patientImage];
    
    
    if (self = [super initWithTexture:patientTexture]) {
        self.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:self.size];
        self.physicsBody.categoryBitMask = categoryPatient;
        self.physicsBody.collisionBitMask = 0x00000000;


        
        self.name = @"patient";
        self.position = position;

        self.severity = severity;
        self.state = PatientIsWaitingForPickup;
        
        [self storePatientUserData];

    }
    
    return self;
}


- (void)updatePatient {

    // update TTL
    NSTimeInterval newTimeToLive = CACurrentMediaTime() - self.spawnTime;
    [self.userData setObject:[NSNumber numberWithDouble:newTimeToLive] forKey:@"timeToLive"];

    if (newTimeToLive <= 0)   {
        [self changeState:PatientIsDead];
    }
    
    
}


- (void)changeState:(PatientState)newState {
    _state = newState;
    
    switch (_state) {
        case PatientIsWaitingForPickup:
            break;
        
        case PatientIsEnRoute:
            self.hidden = YES;
            
            #if DEBUG
                NSLog(@"patient is EN-ROUTE!");
            #endif
            break;
            
        case PatientIsDelivered:
            [self removeFromParent];
            break;
            
        case PatientIsDead:
            [self removeFromParent];

            #if DEBUG
                NSLog(@"patient has DIED!!");
            #endif
            
            break;
            
    }
}

- (void)storePatientUserData {
    // Defines severity data and stashes it in the node's userData property.
    NSInteger medicalSupplies;
    NSTimeInterval timeToLive;
    NSInteger points;
    
    if (self.severity == RandomSeverity) {
        self.severity = (int)RandomFloatRange(1, RandomSeverity - 1);
    }
    
    switch (self.severity) {
        case LevelOne:
            medicalSupplies = 5;
            timeToLive = 60;
            points = 100;
            break;
        
        case LevelTwo:
            medicalSupplies = 10;
            timeToLive = 45;
            points = 200;
            break;
            
        case LevelThree:
            medicalSupplies = 15;
            timeToLive = 30;
            points = 300;
            break;
        
        case RandomSeverity:
            // handled above
            break;
        
    }
    
    self.userData = [[NSMutableDictionary alloc]init];
    
    [self.userData setObject:[NSNumber numberWithInteger:medicalSupplies] forKey:@"medicalSupplies"];
    [self.userData setObject:[NSNumber numberWithDouble:timeToLive] forKey:@"timeToLive"];
    [self.userData setObject:[NSNumber numberWithInteger:points] forKey:@"points"];
}


@end
