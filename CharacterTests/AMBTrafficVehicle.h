//
//  AMBTrafficVehicle.h
//  CharacterTests
//
//  Created by Alex Taylor on 2014-11-20.
//  Copyright (c) 2014 Alex Taylor. All rights reserved.
//
#import "AMBConstants.h"
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


@property SKSpriteNode *collisionZoneTailgating; // if a vehicle enters this zone in front of this vehicle, this vehicle's speed will be adjusted.
@property SKSpriteNode *collisionZoneStopping; // if a vehicle enters this zone in front of this vehicle, this vehicle will stop quickly.
@property BOOL shouldTurnAtIntersections;
@property CGPoint originalPosition; // stores the original spawn point of the vehicle so we can reset it
@property CGFloat originalRotation;
@property CGPoint originalDirection;

+ (AMBTrafficVehicle *)createVehicle:(VehicleType)type withSpeed:(VehicleSpeed)speed atPoint:(CGPoint)point withRotation:(CGFloat)rotation shouldTurnAtIntersections:(BOOL)shouldTurn;
- (void)beganCollision:(SKPhysicsContact *)contact;
- (void)endedCollision:(SKPhysicsContact *)contact;
- (void)updateWithTimeSinceLastUpdate:(CFTimeInterval)delta;
- (void)changeState:(VehicleState)newState;
- (void)swapTexture; // randomly picks a new texture for the traffic vehicle

@end
