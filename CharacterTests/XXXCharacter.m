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
        
        [self rotateSprite:self toFaceDirection:_targetDirection rotateRadiansPerSec:4 * M_PI];

        [self moveSprite:self velocity:characterDirection];
    }


}

-(void)moveSprite:(SKSpriteNode *)sprite velocity:(CGPoint)velocity {
    
    CGPoint amountToMove = CGPointMultiplyScalar(velocity, self.sceneDelta);
    sprite.position = CGPointAdd(sprite.position, amountToMove);
    
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
