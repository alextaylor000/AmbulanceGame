//
//  AMBMovingCharacter.h
//  CharacterTests
//
//  Created by Alex Taylor on 2014-11-20.
//  Copyright (c) 2014 Alex Taylor. All rights reserved.
//
//  A high-level superclass that handles moving sprites, like traffic and the player.

//#import "AMBConstants.h"
#import "AMBCharacter.h"


// control state enum
typedef enum {
    PlayerIsStopped,
    PlayerIsStoppedAtTIntersection,
    PlayerIsWithinTIntersection,
    PlayerIsAccelerating,
    PlayerIsDecelerating,
    PlayerIsDrivingStraight,
    PlayerIsTurning,
    PlayerIsChangingLanes
} PlayerControlState;



@interface AMBMovingCharacter : AMBCharacter

@property (nonatomic) BOOL isMoving; // YES if the character is moving at speed; NO if it's not.

/** the speed of the vehicle when it was first created. */
@property CGFloat nativeSpeed;

@property (nonatomic) CGFloat speedPointsPerSec;
@property (nonatomic) CGPoint direction;
@property (nonatomic) CGFloat pivotSpeed; // how long it takes the character to rotate 90 degrees

@property (nonatomic) CGFloat accelTimeSeconds; // how long it takes for the character to get up to speed; controls easing
@property (nonatomic) CGFloat decelTimeSeconds;
@property CGFloat characterSpeedMultiplier; // 0-1; velocity gets multiplied by this before the sprite is moved
@property (readonly, nonatomic) BOOL requestedMoveEvent; // YES if a move event has been requested but not yet completed
@property (readonly, nonatomic) CGFloat requestedMoveEventDegrees;

/** the current tile properties that the character is on. this allows us to ask each traffic vehicle if it's on an intersection. */
@property int currentTileGID;
@property (readonly, nonatomic) NSDictionary *currentTileProperties;


@property PlayerControlState controlState;


- (void)updateWithTimeSinceLastUpdate:(CFTimeInterval)delta;
- (void)startMoving;
- (void)stopMovingWithDecelTime:(CGFloat)decel;
- (void)rotateByAngle:(CGFloat)degrees;
- (void)moveBy:(CGVector)targetOffset;
- (void)authorizeMoveEvent: (CGFloat)degrees snapToLane:(BOOL)snap;
- (void)adjustSpeedToTarget:(CGFloat)targetSpeed;
- (CGPoint)getDirectionFromAngle:(CGFloat)angle;
+ (void)loadSharedAssets;
@end
