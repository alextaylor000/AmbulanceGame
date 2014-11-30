//
//  AMBTrafficVehicleState.m
//  CharacterTests
//
//  Created by Alex Taylor on 2014-11-29.
//  Copyright (c) 2014 Alex Taylor. All rights reserved.
//

#import "AMBTrafficVehicleState.h"

@implementation AMBTrafficVehicleState

- (void)enterState:(AMBTrafficVehicle *)vehicle {
    // overridden by subclasses.
}

- (void)exitState:(AMBTrafficVehicle *)vehicle {
    // overridden by subclasses.
}

- (AMBTrafficVehicleState *)beganCollision:(SKPhysicsContact *)contact context:(AMBTrafficVehicle *)vehicle {
    // overridden by subclasses.
    return nil;
}

- (AMBTrafficVehicleState *)endedCollision:(SKPhysicsContact *)contact context:(AMBTrafficVehicle *)vehicle {
    // overridden by subclasses.
    return nil;
}

- (AMBTrafficVehicleState *)updateWithTimeSinceLastUpdate:(CFTimeInterval)delta context:(AMBTrafficVehicle *)vehicle {
    // overridden by subclasses.
    return nil;
}

@end


#pragma mark States


@implementation AMBTrafficVehicleIsDrivingStraight

+ (AMBTrafficVehicleIsDrivingStraight *)sharedInstance {
    static AMBTrafficVehicleIsDrivingStraight *_sharedInstance = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        _sharedInstance = [[AMBTrafficVehicleIsDrivingStraight alloc]init];
    });
    return _sharedInstance;
}

- (void)enterState:(AMBTrafficVehicle *)vehicle {
    if (!vehicle.isMoving) {
        [vehicle startMoving];
    }
}


- (AMBTrafficVehicleState *)beganCollision:(SKPhysicsContact *)contact context:(AMBTrafficVehicle *)vehicle {
    return nil;
    
}

- (AMBTrafficVehicleState *)endedCollision:(SKPhysicsContact *)contact context:(AMBTrafficVehicle *)vehicle {
    
    return nil;
}

- (AMBTrafficVehicleState *)updateWithTimeSinceLastUpdate:(CFTimeInterval)delta context:(AMBTrafficVehicle *)vehicle {
    
    return nil;
}



@end