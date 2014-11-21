//
//  AMBTrafficVehicle.h
//  CharacterTests
//
//  Created by Alex Taylor on 2014-11-20.
//  Copyright (c) 2014 Alex Taylor. All rights reserved.
//

#import "AMBCharacter.h"

typedef enum {
    VehicleIsStopped,
    VehicleIsDrivingStraight,
    VehicleCanTurn,
    VehicleIsTailgating,
} VehicleState;

@interface AMBTrafficVehicle : AMBCharacter

@property VehicleState state;
@property CGFloat speed;
@property BOOL isMoving;

@end
