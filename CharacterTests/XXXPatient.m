//
//  XXXPatient.m
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

#import "XXXPatient.h"

@interface XXXPatient ()

@property NSTimeInterval spawnTime;
@property CGFloat lifetime;

@end

@implementation XXXPatient


- (instancetype) initWithSeverity:(PatientSeverity)severity position:(CGPoint)position {
    if (self = [super initWithImageNamed:@"patient01.png"]) {
        // TODO: Variable image (swap out with appropriate level # indicator)
        self.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:self.size];
        self.physicsBody.categoryBitMask = categoryPatient;
        self.physicsBody.collisionBitMask = 0x00000000;
        
        self.name = @"patient";
        self.position = position;

        self.severity = severity;
        self.state = PatientIsWaitingForPickup;

        self.spawnTime = CACurrentMediaTime();
        
        
#if DEBUG
        NSLog(@"init patient [severity=%ld, state=%u, spawned=%f", _severity.rating, _state, _spawnTime);
#endif

    }
    
    return self;
}


- (void)updatePatient {
    // check on time to live
    [self updatePatientLifetime];
    if (_lifetime > _severity.timeToLive)   {
        [self changeState:PatientIsDead];

    }
    
    
}

- (void)updatePatientLifetime {

    _lifetime = CACurrentMediaTime() - _spawnTime;
    
    #if DEBUG
    //NSLog(@"patient lifetime=%0.2f",_lifetime);
    #endif
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


@end
