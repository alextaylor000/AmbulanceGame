//
//  AMBTrafficVehicleState.h
//  CharacterTests
//
//  Created by Alex Taylor on 2014-11-29.
//  Copyright (c) 2014 Alex Taylor. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AMBTrafficVehicle.h"



@interface AMBTrafficVehicleState : NSObject 

/** Called by the context object when switching states. */
- (void)enterState:(AMBTrafficVehicle *)vehicle;

/** Called by the state object when exiting the current state. */
- (void)exitState:(AMBTrafficVehicle *)vehicle;

/** State-specific method for handling new collision events. */
- (AMBTrafficVehicleState *)beganCollision:(SKPhysicsContact *)contact context:(AMBTrafficVehicle *)vehicle;

/** State-specific method for handling the end of collision events. */
- (AMBTrafficVehicleState *)endedCollision:(SKPhysicsContact *)contact context:(AMBTrafficVehicle *)vehicle;

/** State-specific update method. */
- (AMBTrafficVehicleState *)updateWithTimeSinceLastUpdate:(CFTimeInterval)delta context:(AMBTrafficVehicle *)vehicle;

@end



@interface AMBTrafficVehicleIsDrivingStraight : AMBTrafficVehicleState

+ (AMBTrafficVehicleIsDrivingStraight *)sharedInstance; // since this state doesn't have any unique properties of its own, we can use a static instance

@end

@interface AMBTrafficVehicleIsTurning : AMBTrafficVehicleState

@end

@interface AMBTrafficVehicleIsAdjustingSpeed : AMBTrafficVehicleState

/** Custom init for this state to set its target vehicle. */
- (instancetype)initWithTargetVehicle:(AMBMovingCharacter *)target;

@end



