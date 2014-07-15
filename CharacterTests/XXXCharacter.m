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

static const float CHARACTER_ROTATE_DEGREES_PER_SEC = 4 * M_PI;

@interface XXXCharacter ()

@property NSTimeInterval sceneDelta;

@end

@implementation XXXCharacter
{
    
    CGPoint characterDirection;
    
}


- (instancetype) init {
    self = [super initWithImageNamed:@"asset_ambulance_20140609_facingup"];
    
    _movementSpeed = kMovementSpeed;

    return self;
}


- (void)updateWithTimeSinceLastUpdate:(CFTimeInterval)delta {
    self.sceneDelta = delta;
    CGFloat rot = self.zRotation;

    
    if (_isMoving) {
        if (_moveLeft) {
            self.zRotation += SK_DEGREES_TO_RADIANS(90);
            _moveLeft = NO;
            
        } else if (_moveRight) {
            self.zRotation -= SK_DEGREES_TO_RADIANS(90);
            _moveRight = NO;
        }
        
        
        self.position = CGPointMake(self.position.x + -sinf(rot)*_movementSpeed,
                                    self.position.y + cosf(rot)*_movementSpeed);
    }


}


-(void)rotateSprite:(SKSpriteNode *)sprite toFaceDirection:(CGPoint)direction rotateRadiansPerSec:(CGFloat)radiansPerSec {

    CGFloat amtToRotate = radiansPerSec * self.sceneDelta;

    CGFloat targetAngle = CGPointToAngle(direction);
    CGFloat shortest = ScalarShortestAngleBetween(sprite.zRotation, targetAngle);
    
    if (fabsf(shortest) < amtToRotate) {
        amtToRotate = fabsf(shortest);
    }
    
    sprite.zRotation += ScalarSign(shortest) * amtToRotate;
    
    
}

@end
