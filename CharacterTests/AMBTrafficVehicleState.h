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

- (void)enterState:(AMBTrafficVehicle *)vehicle;
- (void)exitState:(AMBTrafficVehicle *)vehicle;
- (AMBTrafficVehicleState *)beganCollision:(SKPhysicsContact *)contact context:(AMBTrafficVehicle *)vehicle;
- (AMBTrafficVehicleState *)endedCollision:(SKPhysicsContact *)contact context:(AMBTrafficVehicle *)vehicle;
- (AMBTrafficVehicleState *)updateWithTimeSinceLastUpdate:(CFTimeInterval)delta context:(AMBTrafficVehicle *)vehicle;

@end



@interface AMBTrafficVehicleIsDrivingStraight : AMBTrafficVehicleState

+ (AMBTrafficVehicleIsDrivingStraight *)sharedInstance; // since this state doesn't have any unique properties of its own, we can use a static instance

@end



