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

static const float CHARACTER_MOVEMENT_POINTS_PER_SEC    = 600;
static const float CHARACTER_ROTATION_DEGREES_PER_SEC   = 300;

// controls easing
static const float CHARACTER_MOVEMENT_ACCEL_TIME_SECS   = 0.75;
static const float CHARACTER_MOVEMENT_DECEL_TIME_SECS   = 0.35;


@interface XXXCharacter ()

@property NSTimeInterval sceneDelta;

@property BOOL isMoving;                    // YES if the character is moving at speed; NO if it's not.
@property CGPoint characterDirection;       // a vector for the current direction the character's travelling.
@property CGFloat targetAngle;              // Degrees; updated when turning.
@property CGFloat characterSpeedMultiplier; // 0-1; velocity gets multiplied by this before the sprite is moved


@end

@implementation XXXCharacter


- (instancetype) init {
    self = [super initWithImageNamed:@"asset_ambulance_20140609"];
    self.name = @"player";
    self.size = CGSizeMake(self.size.width*0.75,self.size.height*0.75);
    self.anchorPoint = CGPointMake(0.35, 0.5);
    
    _characterDirection = CGPointMultiplyScalar(CGPointMake(0, 1), CHARACTER_MOVEMENT_POINTS_PER_SEC); // default direction, move up
    
    // add a "feeler" for calculating the next waypoint
//    SKSpriteNode *feeler = [SKSpriteNode spriteNodeWithColor:[SKColor lightGrayColor] size:CGSizeMake(self.size.width, 10)];
//    feeler.name = @"feeler";
//    feeler.anchorPoint = CGPointMake(1, 0.5);
//    feeler.position = CGPointMake(self.size.width*1.5, 0);
//    [self addChild:feeler];
    
    return self;
}


#pragma mark Game Loop
- (void)updateWithTimeSinceLastUpdate:(CFTimeInterval)delta {
    self.sceneDelta = delta;
    //NSLog(@"targetSpeed=%1f",_targetSpeed);
    
    if (_isMoving) {
        [self rotateSprite:self toAngle:_targetAngle rotateDegreesPerSec:CHARACTER_ROTATION_DEGREES_PER_SEC];
        [self moveSprite:self velocity:_characterDirection];
    }


}

#pragma mark (Public) Sprite Controls
-(void)startMoving {

    if (_isMoving == YES) return;

    _isMoving = YES;
    
    SKAction *startMoving = [SKAction customActionWithDuration:CHARACTER_MOVEMENT_ACCEL_TIME_SECS actionBlock:^(SKNode *node, CGFloat elapsedTime){
        float t = elapsedTime / CHARACTER_MOVEMENT_ACCEL_TIME_SECS;
        t = sinf(t * M_PI_2);
        _characterSpeedMultiplier = t;
    }];
    [self runAction:startMoving];
    
}

-(void)stopMoving {
    if ([self hasActions]) return;
    
    SKAction *stopMoving = [SKAction customActionWithDuration:CHARACTER_MOVEMENT_DECEL_TIME_SECS actionBlock:^(SKNode *node, CGFloat elapsedTime){
        float t = elapsedTime / CHARACTER_MOVEMENT_DECEL_TIME_SECS;
        t = sinf(t * M_PI_2);
        _characterSpeedMultiplier = 1 - t;
    }];
    [self runAction:stopMoving completion:^{_isMoving = NO;}];


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
    _characterDirection = CGPointMultiplyScalar(CGPointForAngle(sprite.zRotation), CHARACTER_MOVEMENT_POINTS_PER_SEC);

    
}


-(void)moveSprite:(SKSpriteNode *)sprite velocity:(CGPoint)velocity {

    CGPoint amountToMove = CGPointMultiplyScalar(velocity, self.sceneDelta);
    CGPoint amountToMoveSpeedMult = CGPointMultiplyScalar(amountToMove, _characterSpeedMultiplier);
    sprite.position = CGPointAdd(sprite.position, amountToMoveSpeedMult);

    
}


@end
