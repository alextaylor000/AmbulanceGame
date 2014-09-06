//
//  XXXCharacter.h
//  CharacterTests
//
//  Created by Alex Taylor on 2014-07-06.
//  Copyright (c) 2014 Alex Taylor. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>
#import "XXXPatient.h"

@interface XXXCharacter : SKSpriteNode

/*  the relationship between these two numbers is important to
 obtain realistic turning motion. the rotation should always
 be less than the speed, or else the car will not appear
 to describe an arc as it turns.
 
 centripetal force probably has something to do with this ratio...
 */
@property (readonly, nonatomic) float CHARACTER_MOVEMENT_POINTS_PER_SEC;
@property (readonly, nonatomic) float CHARACTER_ROTATION_DEGREES_PER_SEC;
@property (readonly, nonatomic) float CHARACTER_TURN_RADIUS;
@property CGFloat targetAngleRadians;
@property (readonly, nonatomic) CGPoint direction;

// controls easing
@property (readonly, nonatomic) float CHARACTER_MOVEMENT_ACCEL_TIME_SECS;
@property (readonly, nonatomic) float CHARACTER_MOVEMENT_DECEL_TIME_SECS;

@property AmbulanceState state;
@property XXXPatient *patient;

- (void)updateWithTimeSinceLastUpdate:(CFTimeInterval)delta;
- (void)startMoving;
- (void)stopMoving;
- (void)turnByAngle:(CGFloat)degrees;
- (void)changeState:(AmbulanceState)newState;
- (BOOL)loadPatient:(XXXPatient *)patient;
- (BOOL)unloadPatient;
@end
