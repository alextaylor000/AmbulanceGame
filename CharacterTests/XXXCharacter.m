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


@interface XXXCharacter ()

@property NSTimeInterval sceneDelta;

@property BOOL isMoving;                    // YES if the character is moving at speed; NO if it's not.
@property CGFloat targetAngleDegrees;              // Degrees; updated when turning.
@property CGFloat characterSpeedMultiplier; // 0-1; velocity gets multiplied by this before the sprite is moved


@end

@implementation XXXCharacter




- (instancetype) init {
    self = [super initWithImageNamed:@"asset_ambulance_20140609"];
    
    // set constants
    _CHARACTER_MOVEMENT_POINTS_PER_SEC = 600;
    _CHARACTER_ROTATION_DEGREES_PER_SEC = 275;
    _CHARACTER_TURN_RADIUS = _CHARACTER_MOVEMENT_POINTS_PER_SEC /
                            ( 2 * M_PI * ( _CHARACTER_ROTATION_DEGREES_PER_SEC / 360 )  );
    
    _CHARACTER_MOVEMENT_ACCEL_TIME_SECS = 0.75;
    _CHARACTER_MOVEMENT_DECEL_TIME_SECS = 0.35;
    

    
    self.name = @"player";
    self.size = CGSizeMake(self.size.width*0.75,self.size.height*0.75);
    self.anchorPoint = CGPointMake(0.35, 0.5);
    self.zRotation = DegreesToRadians(90);
    
    _direction = CGPointMake(0, 1); // default direction, move up
    _targetAngleDegrees = DegreesToRadians(90);
        
    return self;
}


#pragma mark Game Loop
- (void)updateWithTimeSinceLastUpdate:(CFTimeInterval)delta {
    self.sceneDelta = delta;
    
    if (_isMoving) {
        [self rotateSprite:self toAngle:_targetAngleDegrees rotateDegreesPerSec:_CHARACTER_ROTATION_DEGREES_PER_SEC];
        [self moveSprite:self directionNormalized:_direction];
    }


}

#pragma mark (Public) Sprite Controls
-(void)startMoving {

    if (_isMoving == YES) return;

    _isMoving = YES;
    
    SKAction *startMoving = [SKAction customActionWithDuration:_CHARACTER_MOVEMENT_ACCEL_TIME_SECS actionBlock:^(SKNode *node, CGFloat elapsedTime){
        float t = elapsedTime / _CHARACTER_MOVEMENT_ACCEL_TIME_SECS;
        t = sinf(t * M_PI_2);
        _characterSpeedMultiplier = t;
    }];
    [self runAction:startMoving];
    
}

-(void)stopMoving {
    if ([self hasActions]) return;
    
    SKAction *stopMoving = [SKAction customActionWithDuration:_CHARACTER_MOVEMENT_DECEL_TIME_SECS actionBlock:^(SKNode *node, CGFloat elapsedTime){
        float t = elapsedTime / _CHARACTER_MOVEMENT_DECEL_TIME_SECS;
        t = sinf(t * M_PI_2);
        _characterSpeedMultiplier = 1 - t;
    }];
    [self runAction:stopMoving completion:^{_isMoving = NO;}];


}


-(void)turnByAngle:(CGFloat)degrees {
/** Initiates a turn from the current position to a new position based on the degrees specified. */
    
    _targetAngleDegrees += DegreesToRadians(degrees);
    
    // wrap angles larger than +/- 360 degrees
    if (_targetAngleDegrees >= ( 2 * M_PI )) {
        _targetAngleDegrees -= (2 * M_PI);
    } else if (_targetAngleDegrees < 0) {
        _targetAngleDegrees += (2 * M_PI);
    }
    
    
    // this is a start for calculating the center position, but it only works some of the time.. probably b/c of positive vs. negative angles. look up that video again.
    CGPoint centerPoint = CGPointMake(self.position.x - _CHARACTER_TURN_RADIUS * cosf(_targetAngleDegrees),
                                      self.position.y + _CHARACTER_TURN_RADIUS * sinf(_targetAngleDegrees));
    
    
    SKSpriteNode *centerPointSprite = [SKSpriteNode spriteNodeWithColor:[SKColor redColor] size:CGSizeMake(10, 10)];
    centerPointSprite.position = centerPoint;
    [self.parent addChild:centerPointSprite];
    
    
    // DEBUG
    CGPoint targetPoint = CGPointMake(self.position.x + _CHARACTER_TURN_RADIUS, self.position.y + _CHARACTER_TURN_RADIUS); // 63.69 is based on calculating the radius of the circle assuming that the circular velocity is 100 and the time period is 4 (because we can traverse 90 degrees in a second, so it would take 4 seconds to traverse the whole circle). Only thing I'm not sure about is if 100 is correct for the velocity, since that's the straight velocity and not circular..

    NSLog(@"radius=%1.3f, targetPoint=%1.3f,%1.3f",_CHARACTER_TURN_RADIUS,targetPoint.x,targetPoint.y);

}


#pragma mark (Private) Sprite Movement

-(void)rotateSprite:(SKSpriteNode *)sprite toAngle:(CGFloat)angle rotateDegreesPerSec:(CGFloat)degreesPerSec {

    CGFloat radiansPerSec = SK_DEGREES_TO_RADIANS(degreesPerSec);
    
    // determine how much we need to rotate in the current frame
    //CGFloat amtToRotate = radiansPerSec * self.sceneDelta;
    CGFloat amtToRotate = radiansPerSec * self.sceneDelta;
    CGFloat shortest = ScalarShortestAngleBetween(sprite.zRotation, angle);
    if (fabsf(shortest) < amtToRotate) amtToRotate = fabsf(shortest); // if we can make it to the target rotation in 1 frame, just do it
    
    // apply the rotation to the sprite
    sprite.zRotation += ScalarSign(shortest) * amtToRotate;

    // update the direction of the sprite
    _direction = CGPointForAngle(sprite.zRotation);
    
}


-(void)moveSprite:(SKSpriteNode *)sprite directionNormalized:(CGPoint)direction {

    CGPoint velocity = CGPointMultiplyScalar(direction, _CHARACTER_MOVEMENT_POINTS_PER_SEC);
    CGPoint amountToMove = CGPointMultiplyScalar(velocity, self.sceneDelta);
    
    // we're not currently using the speed multiplier, but it may come in handy so I'll leave it in
    CGPoint amountToMoveSpeedMult = CGPointMultiplyScalar(amountToMove, _characterSpeedMultiplier);
    sprite.position = CGPointAdd(sprite.position, amountToMoveSpeedMult);

    
}


@end
