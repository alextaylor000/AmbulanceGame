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
#import "AMBScoreKeeper.h"


@interface AMBPatient ()

@property CGFloat lifetime;


@end

@implementation AMBPatient {
    NSTimeInterval patientTTL;
    SKLabelNode *debugPatientTTL;
    AMBScoreKeeper *scoreKeeper;
}

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
        [self setScale:0.5];
        self.severity = severity;
        self.state = PatientIsWaitingForPickup;
        [self storePatientUserData];
        
        
        
    }
    
    return self;
}

- (NSTimeInterval)getPatientTTL {
    return patientTTL;
}

- (void)updatePatient {
    if (_state == PatientIsEnRoute) {
        // update TTL
        [_patientTimer update:CACurrentMediaTime()];

        patientTTL = _patientTimer.timeRemaining;
//        NSNumber *ttl = [NSNumber numberWithDouble:patientTTL];
        
        if (patientTTL <= 0)   {
            
            [self changeState:PatientIsDead];
            
        }
        
    }
    
    
    
}




- (void)changeState:(PatientState)newState {
    _state = newState;
    
    switch (_state) {
        case PatientIsWaitingForPickup:
//            self.spawnTime = CACurrentMediaTime(); // reset spawn time when a copy is made
            scoreKeeper = [AMBScoreKeeper sharedInstance]; 
            break;
        
        case PatientIsEnRoute:
//            self.spawnTime = CACurrentMediaTime(); // reset spawn time when patient is picked up
            [_patientTimer startTimer];
            patientTTL = _patientTimer.timeRemaining;
            
            self.hidden = YES;
            [self.minimapAvatar removeFromParent];
            #if DEBUG_PATIENT
                NSLog(@"[patient] patient is EN-ROUTE!");
            #endif
            break;
            
        case PatientIsDelivered:

            [self removeFromParent];
            
#if DEBUG_PATIENT
            NSLog(@"[patient] Patient DELIVERED. Time remaining: %1.0f", patientTTL);
#endif

            break;
            
        case PatientIsDead:
            
            [self.minimapAvatar removeFromParent];
            [self removeFromParent];

            #if DEBUG_PATIENT
                NSLog(@"[patient] patient has DIED!!");
            #endif
            


            
            
            break;
            
    }
}


- (void)labelDisplay:(NSString *)text {
    SKLabelNode *label = [SKLabelNode labelNodeWithFontNamed:@"Upheaval Pro"];
    label.text = text;
    label.fontColor = [SKColor yellowColor];
    label.fontSize = 80;
    label.alpha = 0;
    label.zPosition = 1000;
    [self.parent addChild:label];
    
    SKAction *action;
    action = [SKAction sequence:@[[SKAction fadeInWithDuration:0.075],[SKAction waitForDuration:2.0],[SKAction fadeOutWithDuration:0.075]]];
    [label runAction:action];

}

- (void)storePatientUserData {
    // Defines severity data and stashes it in the node's userData property.
    NSTimeInterval timeToLive;
    NSInteger points;
    
    if (self.severity == RandomSeverity) {
        self.severity = (int)RandomFloatRange(1, RandomSeverity - 1);
    }
    
    switch (self.severity) {
        case LevelOne:
            timeToLive = 40;
            points = 100;
            break;
        
        case LevelTwo:
            timeToLive = 45;
            points = 200;
            break;
            
        case LevelThree:
            timeToLive = 30;
            points = 300;
            break;
        
        case RandomSeverity:
            // handled above
            break;
        
    }
    
    self.userData = [[NSMutableDictionary alloc]init];
    
    [self.userData setObject:[NSNumber numberWithDouble:timeToLive] forKey:@"timeToLive"];
    [self.userData setObject:[NSNumber numberWithInteger:points] forKey:@"points"];
    [self.userData setObject:[NSNumber numberWithInteger:self.severity] forKey:@"severity"];
}





@end
