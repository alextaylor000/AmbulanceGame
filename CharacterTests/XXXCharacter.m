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
#import "AMBLevelScene.h"
#import "XXXScoreKeeper.h"
#import "SKTUtils.h"


@interface XXXCharacter ()

@property NSTimeInterval sceneDelta;

@property BOOL isMoving;                    // YES if the character is moving at speed; NO if it's not.

@property CGFloat characterSpeedMultiplier; // 0-1; velocity gets multiplied by this before the sprite is moved

@property SKSpriteNode *sirens;
@property SKAction *sirensOn;

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
    self.zPosition = 100;
    
    // physics (for collisions)
    self.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:self.size];
    self.physicsBody.categoryBitMask = categoryPlayer;
    self.physicsBody.contactTestBitMask = categoryHospital | categoryPatient | categoryTraffic;
    self.physicsBody.collisionBitMask = categoryTraffic;

    
    _direction = CGPointMake(0, 1); // default direction, move up
    _targetAngleRadians = DegreesToRadians(90);
    
    _state = AmbulanceIsEmpty; // set initial ambulance state
    
    // sirens! wee-ooh, wee-oh, wee-ooh...
    SKTextureAtlas *sirenAtlas = [SKTextureAtlas atlasNamed:@"sirens"];
    SKTexture *sirenLeft = [sirenAtlas textureNamed:@"amulance_sirens_left.png"];
    SKTexture *sirenRight = [sirenAtlas textureNamed:@"amulance_sirens_right.png"];
    _sirensOn = [SKAction animateWithTextures:@[sirenLeft, sirenRight] timePerFrame:0.8];

    _sirens = [SKSpriteNode spriteNodeWithTexture:sirenLeft];
    _sirens.hidden = YES;
    _sirens.position = CGPointMake(25, 0);
    _sirens.size = CGSizeMake(self.size.width*0.75,self.size.height*0.75);

    [self addChild:_sirens];
    
//    [sirens runAction:[SKAction repeatActionForever:sirensOn]];
    
    
    return self;
}


#pragma mark Game Loop
- (void)updateWithTimeSinceLastUpdate:(CFTimeInterval)delta {
    self.sceneDelta = delta;
    
    if (_isMoving) {
        [self rotateSprite:self toAngle:_targetAngleRadians rotateDegreesPerSec:_CHARACTER_ROTATION_DEGREES_PER_SEC];
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

    _targetAngleRadians += DegreesToRadians(degrees);

    
    // wrap angles larger than +/- 360 degrees
    if (_targetAngleRadians >= ( 2 * M_PI )) {
        _targetAngleRadians -= (2 * M_PI);
    } else if (_targetAngleRadians < -(2 * M_PI)) {
        _targetAngleRadians += (2 * M_PI);
    }

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
    
    //Fixes the directions so that you dont end up with a situation where you have -0.00000.  I dont even know how that could happen.  BUT IT DOES
    if (_direction.x <= 0.0001 && _direction.x >= -0.0001) {//slightly more than 0 and slightly less than 0
        _direction.x = 0.0;
    }
    if (_direction.y <= 0.0001 && _direction.y >= -0.0001) {//slightly more than 0 and slightly less than 0
        _direction.y = 0.0;
    }
    
}


-(void)moveSprite:(SKSpriteNode *)sprite directionNormalized:(CGPoint)direction {

    CGPoint velocity = CGPointMultiplyScalar(direction, _CHARACTER_MOVEMENT_POINTS_PER_SEC);
    CGPoint amountToMove = CGPointMultiplyScalar(velocity, self.sceneDelta);
    
    // we're not currently using the speed multiplier, but it may come in handy so I'll leave it in
    CGPoint amountToMoveSpeedMult = CGPointMultiplyScalar(amountToMove, _characterSpeedMultiplier);
    sprite.position = CGPointAdd(sprite.position, amountToMoveSpeedMult);

    
}

#pragma mark Game Logic
-(void)changeState:(AmbulanceState)newState {
    _state = newState;
    
    switch (_state) {
        case AmbulanceIsEmpty:
            [_sirens removeActionForKey:@"sirensOn"];
            _sirens.hidden = YES;
            break;
            
        case AmbulanceIsOccupied:
            [_sirens runAction:[SKAction repeatActionForever:_sirensOn] withKey:@"sirensOn"];
            _sirens.hidden = NO;
            break;
    }
}


-(BOOL)loadPatient:(XXXPatient *)patient {
    // loads a given patient into the ambulance. returns true on success, false on failure (if the ambulance was already occupied)
    
    if (_state == AmbulanceIsEmpty) {
        [self changeState:AmbulanceIsOccupied];
        [patient changeState:PatientIsEnRoute];
        _patient = patient; // load the patient into the ambulance
        return YES;
    }
    
    return NO;
}

-(BOOL)unloadPatient {
    // unloads a patient from the ambulance (if there is one)
    if (_patient) {
        [self changeState:AmbulanceIsEmpty];
        [_patient changeState:PatientIsDelivered];
        _patient = nil;
        return YES;
    }
    
    return NO;
}




@end
