//
//  AMBMovingCharacter.m
//  CharacterTests
//
//  Created by Alex Taylor on 2014-11-20.
//  Copyright (c) 2014 Alex Taylor. All rights reserved.
//

#import "AMBMovingCharacter.h"
#import "SKTUtils.h"

@interface AMBMovingCharacter ()

@property NSTimeInterval sceneDelta;
@property CGFloat characterSpeedMultiplier; // 0-1; velocity gets multiplied by this before the sprite is moved

@end

@implementation AMBMovingCharacter

-(id)init {
    if (self = [super init]) {
        // set parameter defaults; to be overridden by subclasses
        self.speedPointsPerSec = 100;
        self.pivotSpeed = 0;
        self.direction = CGPointMake(1, 0);
        self.accelTimeSeconds = 0.75;
        self.decelTimeSeconds = 0.35;
    }
    return self;
}

#pragma mark Game Loop
- (void)updateWithTimeSinceLastUpdate:(CFTimeInterval)delta {
    self.sceneDelta = delta;
    
    if (self.isMoving) {
        [self moveSprite:self directionNormalized:self.direction];
    }
    
    
}

#pragma mark (Public) Sprite Controls
-(void)startMoving {
    
    if (self.isMoving == YES) return;
    
    self.isMoving = YES;
    
    SKAction *startMoving = [SKAction customActionWithDuration:self.accelTimeSeconds actionBlock:^(SKNode *node, CGFloat elapsedTime){
        float t = elapsedTime / self.accelTimeSeconds;
        t = sinf(t * M_PI_2);
        _characterSpeedMultiplier = t;
    }];
    [self runAction:startMoving];
    
}

-(void)stopMoving {
    //if ([self hasActions]) return; // TODO: commented this out to improve the snappiness of the controls. this results in a jerky motion
    
    SKAction *stopMoving = [SKAction customActionWithDuration:self.decelTimeSeconds actionBlock:^(SKNode *node, CGFloat elapsedTime){
        float t = elapsedTime / self.decelTimeSeconds;
        t = sinf(t * M_PI_2);
        _characterSpeedMultiplier = 1 - t;
    }];
    [self runAction:stopMoving completion:^{self.isMoving = NO;}];
    
    
}


#pragma mark (Private) Sprite Movement

- (void)rotateByAngle:(CGFloat)degrees {
    SKSpriteNode *sprite = self;
    
    // apply the rotation to the sprite
    CGFloat angle = sprite.zRotation + DegreesToRadians(degrees);
    
    // wrap angles larger than +/- 360 degrees
    if (angle >= ( 2 * M_PI )) {
        angle -= (2 * M_PI);
    } else if (angle < -(2 * M_PI)) {
        angle += (2 * M_PI);
    }
    
    NSLog(@"angle=%f",RadiansToDegrees(angle));
    
    SKAction *rotateSprite = [SKAction rotateToAngle:angle duration:self.pivotSpeed];
    [sprite runAction:rotateSprite completion:^(void) {
        // update the direction of the sprite
        self.direction = CGPointForAngle(sprite.zRotation);
        
    }];
    
    
    //Fixes the directions so that you dont end up with a situation where you have -0.00000.  I dont even know how that could happen.  BUT IT DOES
    if (self.direction.x <= 0.0001 && self.direction.x >= -0.0001) {//slightly more than 0 and slightly less than 0
        self.direction = CGPointMake(0, self.direction.y);
    }
    if (self.direction.y <= 0.0001 && self.direction.y >= -0.0001) {//slightly more than 0 and slightly less than 0
        self.direction = CGPointMake(self.direction.y, 0);
    }
    
    NSLog(@"vector=%1.0f,%1.0f|z rotation=%1.5f",self.direction.x, self.direction.y,sprite.zRotation);
}

- (void)moveBy:(CGVector)targetOffset {
    NSLog(@"<moveBy>");
    if ([self actionForKey:@"moveBy"]) { return; }
    
    SKAction *changeLanes = [SKAction moveBy:targetOffset duration:0.2];
    changeLanes.timingMode = SKActionTimingEaseInEaseOut;
    [self runAction:changeLanes withKey:@"moveBy"];
    
}

- (void)moveSprite:(SKSpriteNode *)sprite directionNormalized:(CGPoint)direction {
    
    CGPoint velocity = CGPointMultiplyScalar(direction, self.speedPointsPerSec);
    CGPoint amountToMove = CGPointMultiplyScalar(velocity, self.sceneDelta);
    
    // we're not currently using the speed multiplier, but it may come in handy so I'll leave it in
    CGPoint amountToMoveSpeedMult = CGPointMultiplyScalar(amountToMove, _characterSpeedMultiplier);
    sprite.position = CGPointAdd(sprite.position, amountToMoveSpeedMult);
    
    
}


@end
