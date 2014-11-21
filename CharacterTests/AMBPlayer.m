//
//  XXXCharacter.m
//  CharacterTests
//
//  Created by Alex Taylor on 2014-07-06.
//  Copyright (c) 2014 Alex Taylor. All rights reserved.
//
#define SK_DEGREES_TO_RADIANS(__ANGLE__) ((__ANGLE__) * 0.01745329252f) // PI / 180
#define SK_RADIANS_TO_DEGREES(__ANGLE__) ((__ANGLE__) * 57.29577951f) // PI * 180

#import "AMBPlayer.h"
#import "AMBLevelScene.h"
#import "AMBScoreKeeper.h"
#import "SKTUtils.h"


@interface AMBPlayer ()

//@property NSTimeInterval sceneDelta;


@property SKSpriteNode *sirens;
@property SKAction *sirensOn;

@end

@implementation AMBPlayer


- (instancetype) init {
    self = [super initWithImageNamed:@"asset_ambulance_20140609"];
    
    // set constants
    self.speedPointsPerSec = 600;
    self.pivotSpeed = 0;

    self.accelTimeSeconds = 0.75;
    self.decelTimeSeconds = 0.35;
    
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

    
    self.direction = CGPointMake(0, 1); // default direction, move up
    
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


//#pragma mark Game Loop
//- (void)updateWithTimeSinceLastUpdate:(CFTimeInterval)delta {
//    self.sceneDelta = delta;
//    
//    if (self.isMoving) {
//        [self moveSprite:self directionNormalized:self.direction];
//    }
//
//
//}
//
//#pragma mark (Public) Sprite Controls
//-(void)startMoving {
//
//    if (self.isMoving == YES) return;
//
//    self.isMoving = YES;
//    
//    SKAction *startMoving = [SKAction customActionWithDuration:self.accelTimeSeconds actionBlock:^(SKNode *node, CGFloat elapsedTime){
//        float t = elapsedTime / self.accelTimeSeconds;
//        t = sinf(t * M_PI_2);
//        _characterSpeedMultiplier = t;
//    }];
//    [self runAction:startMoving];
//    
//}
//
//-(void)stopMoving {
//    //if ([self hasActions]) return; // TODO: commented this out to improve the snappiness of the controls. this results in a jerky motion
//    
//    SKAction *stopMoving = [SKAction customActionWithDuration:self.decelTimeSeconds actionBlock:^(SKNode *node, CGFloat elapsedTime){
//        float t = elapsedTime / self.decelTimeSeconds;
//        t = sinf(t * M_PI_2);
//        _characterSpeedMultiplier = 1 - t;
//    }];
//    [self runAction:stopMoving completion:^{self.isMoving = NO;}];
//
//
//}
//
//
//#pragma mark (Private) Sprite Movement
//
//- (void)rotateByAngle:(CGFloat)degrees {
//    SKSpriteNode *sprite = self;
//    
//    // apply the rotation to the sprite
//    CGFloat angle = sprite.zRotation + DegreesToRadians(degrees);
//    
//    // wrap angles larger than +/- 360 degrees
//    if (angle >= ( 2 * M_PI )) {
//        angle -= (2 * M_PI);
//    } else if (angle < -(2 * M_PI)) {
//        angle += (2 * M_PI);
//    }
//    
//    NSLog(@"angle=%f",RadiansToDegrees(angle));
//
//    SKAction *rotateSprite = [SKAction rotateToAngle:angle duration:self.pivotSpeed];
//    [sprite runAction:rotateSprite completion:^(void) {
//        // update the direction of the sprite
//        self.direction = CGPointForAngle(sprite.zRotation);
//        
//    }];
//
//    
//    //Fixes the directions so that you dont end up with a situation where you have -0.00000.  I dont even know how that could happen.  BUT IT DOES
//    if (self.direction.x <= 0.0001 && self.direction.x >= -0.0001) {//slightly more than 0 and slightly less than 0
//        self.direction = CGPointMake(0, self.direction.y);
//    }
//    if (self.direction.y <= 0.0001 && self.direction.y >= -0.0001) {//slightly more than 0 and slightly less than 0
//        self.direction = CGPointMake(self.direction.y, 0);
//    }
//    
//    NSLog(@"vector=%1.0f,%1.0f|z rotation=%1.5f",self.direction.x, self.direction.y,sprite.zRotation);
//}
//
//- (void)moveBy:(CGVector)targetOffset {
//    NSLog(@"<moveBy>");
//    if ([self actionForKey:@"moveBy"]) { return; }
//    
//    SKAction *changeLanes = [SKAction moveBy:targetOffset duration:0.2];
//    changeLanes.timingMode = SKActionTimingEaseInEaseOut;
//    [self runAction:changeLanes withKey:@"moveBy"];
//    
//}
//
//
//- (void)moveSprite:(SKSpriteNode *)sprite directionNormalized:(CGPoint)direction {
//
//    CGPoint velocity = CGPointMultiplyScalar(direction, self.speedPointsPerSec);
//    CGPoint amountToMove = CGPointMultiplyScalar(velocity, self.sceneDelta);
//    
//    // we're not currently using the speed multiplier, but it may come in handy so I'll leave it in
//    CGPoint amountToMoveSpeedMult = CGPointMultiplyScalar(amountToMove, _characterSpeedMultiplier);
//    sprite.position = CGPointAdd(sprite.position, amountToMoveSpeedMult);
//
//    
//}

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


-(BOOL)loadPatient:(AMBPatient *)patient {
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
