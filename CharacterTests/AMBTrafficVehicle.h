//
//  AMBTrafficVehicle.h
//  CharacterTests
//
//  Created by Alex Taylor on 2014-11-20.
//  Copyright (c) 2014 Alex Taylor. All rights reserved.
//

#import "AMBMovingCharacter.h"

typedef enum {
    VehicleIsStopped,
    VehicleIsDrivingStraight,
    VehicleCanTurn,
    VehicleIsTailgating,
    VehicleIsAdjustingSpeed
} VehicleState;

typedef enum {
    VehicleTypeSedan = 1,
    VehicleTypeVan,
    VehicleTypeTruck,
    VehicleTypeRandom
} VehicleType;

typedef enum {
    VehicleSpeedSlow = 1,
    VehicleSpeedMedium,
    VehicleSpeedFast
} VehicleSpeed;


@interface AMBTrafficVehicle : AMBMovingCharacter

@property VehicleState state;
@property CGFloat nativeSpeed; // the speed of the vehicle when it was first created

+ (AMBTrafficVehicle *)createVehicle:(VehicleType)type withSpeed:(VehicleSpeed)speed atPoint:(CGPoint)point withRotation:(CGFloat)rotation;
- (void)updateWithTimeSinceLastUpdate:(CFTimeInterval)delta;
- (void)changeState:(VehicleState)newState;

@end
