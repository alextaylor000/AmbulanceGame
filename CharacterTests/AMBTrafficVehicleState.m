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
#if DEBUG
    NSLog(@"%@ enterState: AMBTrafficVehicleIsDrivingStraight", vehicle.name);
#endif
    [vehicle startMoving];

}

- (void)exitState:(AMBTrafficVehicle *)vehicle {
    NSLog(@"%@ exitState: AMBTrafficVehicleIsDrivingStraight", vehicle.name);
}

- (AMBTrafficVehicleState *)beganCollision:(SKPhysicsContact *)contact context:(AMBTrafficVehicle *)vehicle {
    SKNode *node = contact.bodyA.node;
    AMBMovingCharacter *other = (node == vehicle.collisionZoneTailgating || node == vehicle.collisionZoneStopping) ? (AMBMovingCharacter *)contact.bodyB.node : (AMBMovingCharacter *)contact.bodyA.node;
    
    // this vehicle collided with either another traffic vehicle or the player (otherwise the collision wouldn't have been triggered)
    if (other) {
        [self exitState:vehicle];
        return [[AMBTrafficVehicleIsAdjustingSpeed alloc]initWithTargetVehicle:other];
        
    } else {
        return nil; // should never fall through to this, but it's here for safety
    }

}

- (AMBTrafficVehicleState *)endedCollision:(SKPhysicsContact *)contact context:(AMBTrafficVehicle *)vehicle {
    
    return nil;
}

- (AMBTrafficVehicleState *)updateWithTimeSinceLastUpdate:(CFTimeInterval)delta context:(AMBTrafficVehicle *)vehicle {

    // are we at an intersection?
    if (vehicle.currentTileProperties[@"intersection"]) {
        //[self exitState:vehicle];
        //return [[AMBTrafficVehicleIsTurning alloc]init];
    }
    
    return nil;
}


@end

@implementation AMBTrafficVehicleIsTurning {
    
}

- (void)enterState:(AMBTrafficVehicle *)vehicle {
    NSLog(@"%@ enterState: AMBTrafficVehicleIsTurning", vehicle.name);
}

@end

@implementation AMBTrafficVehicleIsAdjustingSpeed {
    AMBMovingCharacter *targetVehicle;
    CGFloat targetSpeed;
}

- (instancetype)initWithTargetVehicle:(AMBMovingCharacter *)target {
    if([super init]) {
        targetVehicle = target;
    }
    
    return self;
}

- (void)enterState:(AMBTrafficVehicle *)vehicle {
    NSLog(@"%@ enterState: AMBTrafficVehicleIsAdjustingSpeed", vehicle.name);
    
    // the speed should be adjusted to 75% of the target speed OR the fastest a traffic vehicle can travel
    targetSpeed = fmaxf(targetVehicle.speedPointsPerSec * 0.75, VehicleSpeedFast);
    NSLog(@"    targetSpeed=%f",targetSpeed);
    [vehicle adjustSpeedToTarget:targetSpeed];
}

- (void)exitState:(AMBTrafficVehicle *)vehicle {
    NSLog(@"%@ exitState: AMBTrafficVehicleIsAdjustingSpeed", vehicle.name);
}

- (AMBTrafficVehicleState *)updateWithTimeSinceLastUpdate:(CFTimeInterval)delta context:(AMBTrafficVehicle *)vehicle {
    if (vehicle.speedPointsPerSec == targetSpeed) {
        [self exitState:vehicle];
        return [AMBTrafficVehicleIsDrivingStraight sharedInstance];
    }
    
    return nil;
}


@end