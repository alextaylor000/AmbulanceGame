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
    
    targetSpeed = targetVehicle.speedPointsPerSec * 0.75;
    
    // the speed should be adjusted to 75% of the target speed OR the vehicle's native speed
    targetSpeed = (targetSpeed > vehicle.nativeSpeed) ? vehicle.nativeSpeed : targetSpeed;
    
    NSLog(@" - targetSpeed=%f",targetSpeed);
    [vehicle adjustSpeedToTarget:targetSpeed];
}

- (void)exitState:(AMBTrafficVehicle *)vehicle {
    NSLog(@"%@ exitState: AMBTrafficVehicleIsAdjustingSpeed", vehicle.name);
}

- (AMBTrafficVehicleState *)updateWithTimeSinceLastUpdate:(CFTimeInterval)delta context:(AMBTrafficVehicle *)vehicle {
    if (vehicle.speedPointsPerSec == targetSpeed) {
        [self exitState:vehicle];
        
        if (targetSpeed > 0) {
            return [AMBTrafficVehicleIsDrivingStraight sharedInstance];
        } else {
            return [AMBTrafficVehicleIsStopped sharedInstance];
        }
    }
    
    return nil;
}


@end

@implementation AMBTrafficVehicleIsStopped {
    
}

+ (AMBTrafficVehicleIsStopped *)sharedInstance {
    static AMBTrafficVehicleIsStopped *_sharedInstance = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        _sharedInstance = [[AMBTrafficVehicleIsStopped alloc]init];
    });
    return _sharedInstance;
}

- (void)enterState:(AMBTrafficVehicle *)vehicle {
    NSLog(@"%@ enterState: AMBTrafficVehicleIsStopped", vehicle.name);
}

- (void)exitState:(AMBTrafficVehicle *)vehicle {
    NSLog(@"%@ exitState: AMBTrafficVehicleIsStopped", vehicle.name);
    vehicle.speedPointsPerSec = vehicle.nativeSpeed;
    
    // TODO: how do we have this wait a random amount of time? waitForDuration doesn't seem to have an effect on this.
    [vehicle startMoving];
    
    
}

- (AMBTrafficVehicleState *)endedCollision:(SKPhysicsContact *)contact context:(AMBTrafficVehicle *)vehicle {
    if (contact.bodyA.node == vehicle.collisionZoneTailgating || contact.bodyB.node == vehicle.collisionZoneTailgating) {
        
        [self exitState:vehicle];
        return [AMBTrafficVehicleIsDrivingStraight sharedInstance];

    } else {
        return nil; // if the blocking object has to exit the collision zone; if there's something in the stopping zone, don't move!
    }
    
}


@end