//
//  XXXCharacter.m
//  CharacterTests
//
//  Created by Alex Taylor on 2014-07-06.
//  Copyright (c) 2014 Alex Taylor. All rights reserved.
//
#define SK_DEGREES_TO_RADIANS(__ANGLE__) ((__ANGLE__) * 0.01745329252f) // PI / 180
#define SK_RADIANS_TO_DEGREES(__ANGLE__) ((__ANGLE__) * 57.29577951f) // PI * 180

#import "XXXCharacter.h"
#import "XXXMyScene.h"
#import "SKTUtils.h"


/*  the relationship between these two numbers is important to 
    obtain realistic turning motion. the rotation should always
    be less than the speed, or else the car will not appear
    to describe an arc as it turns.
 
    centripetal force probably has something to do with this ratio...
 */

static const float CHARACTER_MOVEMENT_POINTS_PER_SEC    = 200;
static const float CHARACTER_ROTATION_DEGREES_PER_SEC   = 150;

@interface XXXCharacter ()

@property NSTimeInterval sceneDelta;
@property BOOL isMoving;
@property CGFloat targetAngle;

@end

@implementation XXXCharacter
{
    
    CGPoint characterDirection;
    
}


- (instancetype) init {
    self = [super initWithImageNamed:@"asset_ambulance_20140609"];
    self.anchorPoint = CGPointMake(0.4, 0.5);

    characterDirection = CGPointMultiplyScalar(CGPointMake(0, 1), CHARACTER_MOVEMENT_POINTS_PER_SEC); // default direction, move up

    
    return self;
}


#pragma mark Game Loop
- (void)updateWithTimeSinceLastUpdate:(CFTimeInterval)delta {
    self.sceneDelta = delta;
    
    
    if (_isMoving) {
        [self rotateSprite:self toAngle:_targetAngle rotateDegreesPerSec:CHARACTER_ROTATION_DEGREES_PER_SEC];
        [self moveSprite:self velocity:characterDirection];
    }


}

#pragma mark (Public) Sprite Controls
-(void)startMoving {
    _isMoving = YES;
}

-(void)stopMoving {
    _isMoving = NO;
}


-(void)turnByAngle:(CGFloat)degrees {
/** Initiates a turn from the current position to a new position based on the degrees specified. */
    
    _targetAngle += DegreesToRadians(degrees);
    
    // wrap angles larger than +/- 360 degrees
    if (_targetAngle >= ( 2 * M_PI )) {
        _targetAngle -= (2 * M_PI);
    } else if (_targetAngle < 0) {
        _targetAngle += (2 * M_PI);
    }
    
    
}


#pragma mark (Private) Sprite Movement

-(void)rotateSprite:(SKSpriteNode *)sprite toAngle:(CGFloat)angle rotateDegreesPerSec:(CGFloat)degreesPerSec {

    CGFloat radiansPerSec = SK_DEGREES_TO_RADIANS(degreesPerSec);
    
    // determine how much we need to rotate in the current frame
    CGFloat amtToRotate = radiansPerSec * self.sceneDelta;
    CGFloat shortest = ScalarShortestAngleBetween(sprite.zRotation, angle);
    if (fabsf(shortest) < amtToRotate) amtToRotate = fabsf(shortest); // if we can make it to the target rotation in 1 frame, just do it
    
    // apply the rotation to the sprite
    sprite.zRotation += ScalarSign(shortest) * amtToRotate;

    // update the direction of the sprite
    characterDirection = CGPointMultiplyScalar(CGPointForAngle(sprite.zRotation), CHARACTER_MOVEMENT_POINTS_PER_SEC);

    
}


-(void)moveSprite:(SKSpriteNode *)sprite velocity:(CGPoint)velocity {
    
    CGPoint amountToMove = CGPointMultiplyScalar(velocity, self.sceneDelta);
    sprite.position = CGPointAdd(sprite.position, amountToMove);
    
}


@end
