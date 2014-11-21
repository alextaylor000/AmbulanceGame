//
//  AMBMovingCharacter.h
//  CharacterTests
//
//  Created by Alex Taylor on 2014-11-20.
//  Copyright (c) 2014 Alex Taylor. All rights reserved.
//
//  A high-level superclass that handles moving sprites, like traffic and the player.

#import "AMBCharacter.h"

@interface AMBMovingCharacter : AMBCharacter

@property (nonatomic) BOOL isMoving; // YES if the character is moving at speed; NO if it's not.

@property (nonatomic) CGFloat speedPointsPerSec;
@property (nonatomic) CGPoint direction;
@property (nonatomic) CGFloat pivotSpeed; // how long it takes the character to rotate 90 degrees

@property (nonatomic) CGFloat accelTimeSeconds; // how long it takes for the character to get up to speed; controls easing
@property (nonatomic) CGFloat decelTimeSeconds;


- (void)updateWithTimeSinceLastUpdate:(CFTimeInterval)delta;
- (void)startMoving;
- (void)stopMoving;
- (void)rotateByAngle:(CGFloat)degrees;
- (void)moveBy:(CGVector)targetOffset;
- (void)adjustSpeedToTarget:(CGFloat)targetSpeed;


@end
