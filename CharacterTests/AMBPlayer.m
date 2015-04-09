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
#import "AMBPowerup.h"
#import "AMBScoreKeeper.h"
#import "SKTUtils.h"
#import "AMBFuelGauge.h"

typedef enum {
    Hide,
    PatientDied,
    PatientDelivered
} BubbleHideState;




@interface AMBPlayer ()

//@property NSTimeInterval sceneDelta;


@property SKSpriteNode *sirens;
@property SKSpriteNode *turnSignalLeft;
@property SKSpriteNode *turnSignalRight;

@property AMBScoreKeeper *scoreKeeper;
@property NSTimeInterval fuelTimer; // times when the fuel started being depleted by startMoving

@property SKSpriteNode *patientBubble;
@property SKLabelNode *patientTimer;


@end

@implementation AMBPlayer


- (instancetype) initWithSprite:(AMBVehicleType)vehicleType {
    // choose sprite
    SKTexture *playerTexture;
    
    switch (vehicleType) {
        case AMBVehicleWhite:
            playerTexture = sPlayerSprite;
            break;
            
        case AMBVehicleRed:
            playerTexture = sPlayerSprite;
            break;
            
        case AMBVehicleSpecial1:
            playerTexture = sPlayerSprite;
            break;
            
        case AMBVehicleSpecial2:
            playerTexture = sPlayerSprite;
            break;
    }
    
    self = [super initWithTexture:playerTexture]; // loads from texture atlas
    
    // set constants
    self.nativeSpeed = 600;
    self.speedPointsPerSec = self.nativeSpeed;
    self.pivotSpeed = 0;
    
#warning replace this scale with real graphics
    //[self setScale:1.2];

    self.accelTimeSeconds = 0.75;
    self.decelTimeSeconds = 0.35;
    
    self.name = @"player";
    //self.size = CGSizeMake(self.size.width*0.75,self.size.height*0.75);
    //self.anchorPoint = CGPointMake(0.35, 0.5);
    self.zRotation = DegreesToRadians(90);
    self.zPosition = 100;
    
    // physics (for collisions)
    self.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:CGSizeMake(self.size.width * 0.8, self.size.height * 0.6 )];
    self.physicsBody.categoryBitMask = categoryPlayer;
    self.physicsBody.contactTestBitMask = categoryHospital | categoryPatient | categoryTraffic | categoryPowerup;
    self.physicsBody.collisionBitMask = 0;

    
    self.direction = CGPointMake(0, 1); // default direction, move up
    
    _state = AmbulanceIsEmpty; // set initial ambulance state
    
    // sirens! wee-ooh, wee-oh, wee-ooh...
    // moved into shared asset loading

    _sirens = [SKSpriteNode spriteNodeWithTexture:sSirenDefaultTexture];
    _sirens.hidden = YES;
    _sirens.position = CGPointMake(25, 0);
    _sirens.size = CGSizeMake(self.size.width*0.75,self.size.height*0.75);

    [self addChild:_sirens];
    

    _turnSignalLeft = [SKSpriteNode spriteNodeWithTexture:sTurnSignalLeft];
//    [_turnSignalLeft setScale:2.0];
    _turnSignalLeft.position = CGPointMake(20, 28);
    _turnSignalLeft.zPosition = -1;
    _turnSignalLeft.alpha = 0;
    [self addChild:_turnSignalLeft];
    
    _turnSignalRight = [SKSpriteNode spriteNodeWithTexture:sTurnSignalRight];
//    [_turnSignalRight setScale:2.0];
    _turnSignalRight.position = CGPointMake(20, -28);
    _turnSignalRight.zPosition = -1;
    _turnSignalRight.alpha = 0;
    [self addChild:_turnSignalRight];
    
    _turnSignalState = PlayerTurnSignalStateOff;
    
    _scoreKeeper = [AMBScoreKeeper sharedInstance]; // hook up the shared instance of the score keeper so we can talk to it
    
    _fuel = fuelCapacity; // fuel capacity from FuelGauge
    _fuelTimer = 0;
    
    self.controlState = PlayerIsStopped;
    
    
    // bubble
    _patientBubble = [SKSpriteNode spriteNodeWithTexture:sPatientBubble];
    _patientBubble.position = CGPointMake(70, -50);
    _patientBubble.zPosition = 99;
    _patientBubble.alpha = 0;
    _patientBubble.xScale = 0;

    
    _patientTimer = [SKLabelNode labelNodeWithFontNamed:@"AvenirNextCondensed-Bold"];
    _patientTimer.fontSize = 25;
    _patientTimer.fontColor = [SKColor redColor];
    _patientTimer.zRotation = DegreesToRadians(-115);
    
    _patientTimer.text = @"0:00";
    _patientTimer.position = CGPointMake(0, 3);

    [_patientBubble addChild:_patientTimer];
    [self addChild:_patientBubble];
    
    
    return self;
}

- (void)setTurnSignalState:(PlayerTurnSignalState)turnSignalState {
    switch (turnSignalState) {
        case PlayerTurnSignalStateOff:
            [_turnSignalLeft removeAllActions];
            [_turnSignalRight removeAllActions];
            
            [_turnSignalLeft runAction:sTurnSignalFadeOut];
            [_turnSignalRight runAction:sTurnSignalFadeOut];
            break;
            
        case PlayerTurnSignalStateLeft:
            if (![_turnSignalLeft hasActions]) {
                [_turnSignalRight removeAllActions];
                [_turnSignalRight runAction:sTurnSignalFadeOut];

                [_turnSignalLeft runAction:sTurnSignalOn];
            }
            break;
            
        case PlayerTurnSignalStateRight:
            if (![_turnSignalRight hasActions]) {
                [_turnSignalLeft removeAllActions];
                [_turnSignalLeft runAction:sTurnSignalFadeOut];
            
                [_turnSignalRight runAction:sTurnSignalOn];
            }

    }
}

- (void)updateWithTimeSinceLastUpdate:(CFTimeInterval)delta {
    // the superclass handles moving the sprite
    [super updateWithTimeSinceLastUpdate:delta];


    

    AMBLevelScene *__weak owningScene = [self characterScene]; // declare a reference to the scene as weak, to prevent a reference cycle. Inspired by animationDidComplete in Adventure.
    
    // update the patient timer
    if (self.patient) {
        NSTimeInterval ttl = [self.patient getPatientTTL];
        //owningScene.patientTimeToLive.text = [NSString stringWithFormat:@"PATIENT: %1.1f",ttl];
        _patientTimer.text = [NSString stringWithFormat:@"%@",[self timeFormatted:ttl]];

        if (ttl < 11) {
            [self revealBubble];
        }
        
        if (self.patient.state == PatientIsDead) {
            [self hideBubbleBecause:PatientDied];
            [self unloadPatient];
        }
    
    }
    

    
    
    if (self.isMoving) {
        if (self.controlState == PlayerIsChangingLanes) {
            [self authorizeMoveEvent:_laneChangeDegrees snapToLane:NO];
        }
        
        
        
        // T-intersections
        if (self.currentTileProperties[@"invalid_directions"]) {
            CGPoint currentTilePos = [self.levelScene.mapLayerRoad pointForCoord:  [self.levelScene.mapLayerRoad coordForPoint:self.position]];
            CGPoint playerPosInTile = CGPointSubtract(self.position, currentTilePos);
            CGPoint playerPosNormalized = CGPointMultiply(playerPosInTile, self.direction);
            CGFloat distFromCenter = fabsf(playerPosNormalized.x + playerPosNormalized.y); // should "flatten" the CGPoint since one of these will always be zero
            
            if (distFromCenter < 40) {
                CGRect invalidDirections = CGRectFromString(self.currentTileProperties[@"invalid_directions"]); // CGRect so we can extract the two dimensions
                CGPoint invalidDirection1 = invalidDirections.origin;
                CGPoint invalidDirection2 = CGPointMake(invalidDirections.size.width, invalidDirections.size.height);
                
                
                if (self.controlState == PlayerIsAccelerating ||
                    self.controlState == PlayerIsDecelerating ||
                    self.controlState == PlayerIsDrivingStraight ||
                    self.controlState == PlayerIsChangingLanes) {
                    if (CGPointEqualToPoint(invalidDirection1, self.direction) ||
                        CGPointEqualToPoint(invalidDirection2, self.direction)) {
                        self.controlState = PlayerIsWithinTIntersection; // no valid inputs in this control state (intentional)
                        
                        [self slamBrakes]; // instead of stopMoving
                    }
                }
            }
         
        }

    }
}

- (void)startMoving {
    AMBLevelScene *__weak owningScene = [self characterScene]; // declare a reference to the scene as weak, to prevent a reference cycle. Inspired by animationDidComplete in Adventure.
    [owningScene.fuelGauge startTimer];
    [super startMoving];
    
}

- (void)stopMovingWithDecelTime:(CGFloat)decel {
    AMBLevelScene *__weak owningScene = [self characterScene]; // declare a reference to the scene as weak, to prevent a reference cycle. Inspired by animationDidComplete in Adventure.
    [owningScene.fuelGauge stopTimer];

    [super stopMovingWithDecelTime:decel];
}


- (void)slamBrakes {
    //if (self.hasActions == NO) { // this was conflicting with the invincibility powerup. did we need it for something specific?
        
        // stopMoving with an end state of PlayerIsStoppedAtTIntersection
        CGFloat decelTime = self.decelTimeSeconds/2;
        SKAction *stopMoving = [SKAction customActionWithDuration:decelTime actionBlock:^(SKNode *node, CGFloat elapsedTime){
            float t = elapsedTime / decelTime;
            t = sinf(t * M_PI_2);
            
            self.characterSpeedMultiplier = 1 - t;
        }];
        [self runAction:stopMoving completion:^{
            self.isMoving = NO;
            self.speedPointsPerSec = 0;
            
            
            self.controlState = PlayerIsStoppedAtTIntersection;
//#if DEBUG_PLAYER_CONTROL
//            NSLog(@"[control] PlayerIsDecelerating -> slamBrakes -> PlayerIsStoppedAtTIntersection");
//#endif
            
            
        }];
    
    //}

    
}

- (void)leaveIntersectionWithInput:(PlayerControls)input {

    self.controlState = PlayerIsWithinTIntersection;

    // rotate, then start moving
    CGFloat degrees = (input == PlayerControlsTurnLeft) ? 90 : -90;
    
    // apply the rotation to the sprite
    CGFloat angle = self.zRotation + DegreesToRadians(degrees);

    // wrap angles larger than +/- 360 degrees
    if (angle >= ( 2 * M_PI )) {
        angle -= (2 * M_PI);
    } else if (angle < -(2 * M_PI)) {
        angle += (2 * M_PI);
    }
    
    self.zRotation = angle;

    // update the direction of the sprite
    self.direction = [self getDirectionFromAngle:self.zRotation];

    
    // rotate the camera
    [self.levelScene.camera rotateByAngle:degrees];
    
    // start moving
    self.isMoving = YES;
    self.speedPointsPerSec = self.nativeSpeed; // reset speedPointsPerSec
    
    SKAction *startMoving = [SKAction customActionWithDuration:self.accelTimeSeconds actionBlock:^(SKNode *node, CGFloat elapsedTime){
        float t = elapsedTime / self.accelTimeSeconds;
        t = sinf(t * M_PI_2);
        self.characterSpeedMultiplier = t;
        
    }];
    [self runAction:startMoving completion:^(void){
        if ([self.name isEqualToString:@"player"]) {
            self.controlState = PlayerIsDrivingStraight;
//#if DEBUG_PLAYER_CONTROL
//            NSLog(@"[control] PlayerIsWithinTIntersection -> leaveIntersection -> PlayerIsDrivingStraight");
//#endif
        }
    }];
    
}

#pragma mark Game Logic
-(void)changeState:(AmbulanceState)newState {
    _state = newState;

    AMBLevelScene *__weak owningScene = [self characterScene]; // declare a reference to the scene as weak, to prevent a reference cycle. Inspired by animationDidComplete in Adventure.
    
    switch (_state) {
        case AmbulanceIsEmpty:
            [_sirens removeActionForKey:@"sirensOn"];
            _sirens.hidden = YES;
            
            
            break;
            
        case AmbulanceIsOccupied:
            //[_sirens runAction:[SKAction repeatActionForever:_sirensOn] withKey:@"sirensOn"];
            [_sirens runAction:sSirensOn withKey:@"sirensOn"];
            _sirens.hidden = NO;
            [owningScene.indicator removeTarget:self.patient];
            break;
    }
}


-(BOOL)loadPatient:(AMBPatient *)patient {
    // loads a given patient into the ambulance. returns true on success, false on failure (if the ambulance was already occupied)
    
    if (_state == AmbulanceIsEmpty) {
        [patient changeState:PatientIsEnRoute];
        _patient = patient; // load the patient into the ambulance
        [self changeState:AmbulanceIsOccupied];
        [self.levelScene.tutorialOverlay playerDidPerformEvent:PlayerEventPickupPatient]; // tutorial event
        
        [self showBubble];
        return YES;
    }
    
    return NO;
}

-(BOOL)unloadPatient {
    // unloads a patient from the ambulance (if there is one)
    
    if (_patient) {
        [self changeState:AmbulanceIsEmpty];
        
        if (_patient.state == PatientIsEnRoute) {
            [self hideBubbleBecause:PatientDelivered];
            [_patient changeState:PatientIsDelivered];
            [self.levelScene.tutorialOverlay playerDidPerformEvent:PlayerEventDeliverPatient]; // tutorial event
            _patient = nil;
            return YES;
        }
    }
    
    return NO;
}

- (void)collidedWith:(SKPhysicsBody *)other victimNodeName:(NSString *)name {
    
    AMBLevelScene *__weak owningScene = [self characterScene]; // declare a reference to the scene as weak, to prevent a reference cycle. Inspired by animationDidComplete in Adventure.
    
    SKAction *action;
#warning preload this action
    SKAction *speedPenalty = [SKAction sequence:@[[SKAction waitForDuration:3.0],[SKAction runBlock:^(void) { [self adjustSpeedToTarget:self.nativeSpeed]; NSLog(@"Speed penalty end"); [self removeActionForKey:@"blink"]; self.alpha = 1.0; // reset alpha
    }]]];
    
    switch (other.categoryBitMask) {
        case categoryPatient:
            [self loadPatient:(AMBPatient *)other.node];
            break;
            
        case categoryTraffic:
            if (![self actionForKey:@"invincibility"]) {
#warning preload this action
                
                [_scoreKeeper handleEventCarHit];
                
                action = [SKAction sequence:@[[SKAction fadeAlphaTo:0.1 duration:0],[SKAction waitForDuration:0.1],[SKAction fadeAlphaTo:1.0 duration:0.1],[SKAction waitForDuration:0.1]]];
                [self runAction:[SKAction repeatActionForever:action] withKey:@"blink"];
                
                // slow down the player temporarily
                [self adjustSpeedToTarget:self.nativeSpeed * 0.70];
                //NSLog(@"Speed penalty begin");
                [self removeActionForKey:@"speedPenalty"]; // remove action if it's running already
                [self runAction: speedPenalty withKey:@"speedPenalty"];
            }
            
            break;
            
        case categoryHospital:
            if (self.patient) {
                [_scoreKeeper handleEventDeliveredPatient:self.patient];
                [self unloadPatient];
            }
            break;
            
        case categoryPowerup:

            if ([other.node.name isEqualToString:@"fuel"]) {

                [owningScene.fuelGauge addFuel:fuelUnitsInPowerup];
                
                [self.levelScene.tutorialOverlay playerDidPerformEvent:PlayerEventPickupFuel]; // tutorial event
                
                AMBCharacter *powerup = (AMBCharacter *)other.node;
                [powerup removeFromParent];
                    
                    

            } else if ([other.node.name isEqualToString:@"invincibility"]) {
#warning preload this action
                action = [SKAction sequence:@[[SKAction colorizeWithColor:[SKColor greenColor] colorBlendFactor:0.6 duration:0.25],[SKAction waitForDuration:PLAYER_INVINCIBLE_TIME],[SKAction colorizeWithColorBlendFactor:0.0 duration:0.25]]];
                [self runAction:action withKey:@"invincibility"]; // as long as this action exists on the player, the player will be immune to traffic
                
                [_scoreKeeper handleEventInvincible];
                [self.levelScene.tutorialOverlay playerDidPerformEvent:PlayerEventPickupInvincibility]; // tutorial event

                AMBCharacter *powerup = (AMBCharacter *)other.node;
                [powerup removeFromParent];
                [powerup.minimapAvatar removeFromParent];
                
            }

            break;
            
    }
}



- (void)handleInput:(PlayerControls)input keyDown:(BOOL)keyDown {

    NSString *message; // for debug only
    
    switch (self.controlState) {
        case PlayerIsStopped:
            
            // valid inputs: <UP>
            if (input == PlayerControlsStartMoving) {
                self.controlState = PlayerIsAccelerating;
                message = @"[control] PlayerIsStopped -> handleInput:startMoving -> PlayerIsAccelerating";
                [self printMessage:message];
                [self startMoving];
                [self.characterScene.tutorialOverlay playerDidPerformEvent:PlayerEventStartMoving]; // tutorial event
                
            }
            
            break;
    
        case PlayerIsStoppedAtTIntersection:
            
            // valid inputs: <LEFT>,<RIGHT>
            // this is the only state where the player can change directions from stopped
            if (input == PlayerControlsTurnLeft) {
                [self leaveIntersectionWithInput:input];
                message = @"[control] PlayerIsStoppedAtTIntersection -> handleInput:turnLeft -> PlayerIsAccelerating";
                [self printMessage:message];
                
                
            } else if (input == PlayerControlsTurnRight) {
                [self leaveIntersectionWithInput:input];
                message = @"[control] PlayerIsStoppedAtTIntersection -> handleInput:turnRight -> PlayerIsAccelerating";
                [self printMessage:message];
                
            }
            
            break;
            
        case PlayerIsWithinTIntersection:
            
            // valid inputs: NONE
            break;
            
        case PlayerIsAccelerating:
            
            // valid inputs: <DOWN>,<LEFT>,<RIGHT>
            if (input == PlayerControlsStopMoving) {
                self.controlState = PlayerIsDecelerating;
                message = @"[control] PlayerIsAccelerating -> handleInput:stopMoving -> PlayerIsDecelerating";
                [self printMessage:message];
                [self stopMovingWithDecelTime:self.decelTimeSeconds];
                
            } else if   (input == PlayerControlsTurnLeft) {
                self.laneChangeDegrees = 90;
                self.controlState = PlayerIsChangingLanes;
                message = @"[control] PlayerIsAccelerating -> handleInput:turnLeft";
                [self printMessage:message];
                
            } else if   (input == PlayerControlsTurnRight) {
                self.laneChangeDegrees = -90;
                self.controlState = PlayerIsChangingLanes;
                message = @"[control] PlayerIsAccelerating -> handleInput:turnRight";
                [self printMessage:message];
            }
            
            break;
            
        case PlayerIsDecelerating:
            
            // valid inputs: <UP>,<LEFT>,<RIGHT>
            if (input == PlayerControlsStartMoving) {
                self.controlState = PlayerIsAccelerating;
                message = @"[control] PlayerIsDecelerating -> handleInput:startMoving -> PlayerIsAccelerating";
                [self printMessage:message];
                [self startMoving];
                
            } else if   (input == PlayerControlsTurnLeft) {
                self.laneChangeDegrees = 90;
                self.controlState = PlayerIsChangingLanes;
                message = @"[control] PlayerIsDecelerating -> handleInput:turnLeft";
                [self printMessage:message]; // can we cancel all actions here to return to normal speed?
                
            } else if   (input == PlayerControlsTurnRight) {
                self.laneChangeDegrees = -90;
                self.controlState = PlayerIsChangingLanes;
                message = @"[control] PlayerIsDecelerating -> handleInput:turnRight";
                [self printMessage:message];
            }

            break;
            
        case PlayerIsDrivingStraight:
            
            if (!keyDown) {
                return;
            }
            
            // valid inputs: <DOWN>,<LEFT>,<RIGHT>
            if (input == PlayerControlsStopMoving) {
                self.controlState = PlayerIsDecelerating;
                message = @"[control] PlayerIsDrivingStraight -> handleInput:stopMoving -> PlayerIsDecelerating";
                [self printMessage:message];
                [self stopMovingWithDecelTime:self.decelTimeSeconds];
                [self.characterScene.tutorialOverlay playerDidPerformEvent:PlayerEventStopMoving];
                
            } else if   (input == PlayerControlsTurnLeft) {
                self.laneChangeDegrees = 90;
                self.controlState = PlayerIsChangingLanes;
                message = @"[control] PlayerIsDrivingStraight -> handleInput:turnLeft";
                [self printMessage:message];
                
            } else if   (input == PlayerControlsTurnRight) {
                self.laneChangeDegrees = -90;
                self.controlState = PlayerIsChangingLanes;
                message = @"[control] PlayerIsDrivingStraight -> handleInput:turnRight";
                [self printMessage:message];
            }
            
            break;

        case PlayerIsTurning:
            
            // valid inputs: none
            // authorizeMoveEvent will be overridden in the Player class to change its state when complete
            message = @"[control] PlayerIsTurning -> nil";
            [self printMessage:message];
            break;

        case PlayerIsChangingLanes:
            
            // valid inputs: <DOWN>,<LEFT>,<RIGHT>
            if (input == PlayerControlsStopMoving) {
                self.controlState = PlayerIsDecelerating;
                message = @"[control] PlayerIsChangingLanes -> handleInput:stopMoving -> PlayerIsDecelerating";
                [self printMessage:message];
                [self stopMovingWithDecelTime:self.decelTimeSeconds];
            }
            
            if (keyDown) {
                // TODO: these are actually redundant at the moment, since once this state is enabled it can only be disabled by a keyUp event.
                if   (input == PlayerControlsTurnLeft) {
                    self.laneChangeDegrees = 90; // fixes issue #36
                    message = @"[control] PlayerIsChangingLanes -> handleInput:keyDOWN/turnLeft";
                    [self printMessage:message];
                    
                } else if   (input == PlayerControlsTurnRight) {
                    self.laneChangeDegrees = -90; // fixes issue #36
                    message = @"[control] PlayerIsChangingLanes -> handleInput:keyDOWN/turnRight";
                    [self printMessage:message];
                }
                
                
            } else if (!keyDown) {
                if   (input == PlayerControlsTurnLeft) {
                    // TODO: consider changing this to ONLY change lanes on keyUp, not introduce the possibility of turning.
                    [self authorizeMoveEvent:90 snapToLane:YES];
                    self.controlState = PlayerIsDrivingStraight;
                    message = @"[control] PlayerIsChangingLanes -> handleInput:keyUP/turnLeft -> PlayerIsDrivingStraight";
                    [self printMessage:message];
                    
                } else if   (input == PlayerControlsTurnRight) {
                    [self authorizeMoveEvent:-90 snapToLane:YES];
                    self.controlState = PlayerIsDrivingStraight;
                    message = @"[control] PlayerIsChangingLanes -> handleInput:keyUP/turnRight -> PlayerIsDrivingStraight";
                    [self printMessage:message];
                }
                
            }
            
            
            break;
            
    }
   
    
}

- (void)printMessage:(NSString *)message {
//    #if DEBUG_PLAYER_CONTROL
//        NSLog(@"%@", message);
//    #endif
    
}

- (void)showBubble {
    SKAction *bubbleScale =  [SKAction sequence:@[[SKAction scaleTo:1.25 duration:0.15], [SKAction scaleTo:1.0 duration:0.075]]];
    bubbleScale.timingMode = SKActionTimingEaseInEaseOut;

    SKAction *bubbleFade = [SKAction fadeInWithDuration:0.25];

    SKAction *fade = [SKAction sequence:@[[SKAction waitForDuration:5],[SKAction fadeAlphaTo:0.5 duration:0.5]]];
    
    SKAction *group = [SKAction group:@[bubbleScale, bubbleFade, fade]];
    

    [_patientBubble runAction:group];
    
}

- (void)revealBubble {
    if ([_patientBubble hasActions] == NO) {
        SKAction *fadeUp = [SKAction fadeAlphaTo:1.0 duration:0.25];
        [_patientBubble runAction:fadeUp];
        
    }
}

- (void)hideBubbleBecause:(BubbleHideState)reason {
    SKAction *hide;
    
    switch (reason) {
        case Hide:
            hide = [SKAction fadeOutWithDuration:0.25];
            break;
            
        case PatientDelivered:
            hide = [SKAction fadeOutWithDuration:0.25];
            break;
            
        case PatientDied:
            hide = [SKAction fadeOutWithDuration:0.5];
            break;
            
    }
    
    [_patientBubble runAction:hide];
    
}



#pragma mark Assets
+ (void)loadSharedAssets {
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        SKTextureAtlas *gameObjectSprites = [SKTextureAtlas atlasNamed:@"GameObjectSprites"];
        sPlayerSprite = [gameObjectSprites textureNamed:@"ambulance"];
        sTurnSignalLeft = [gameObjectSprites textureNamed:@"hud_swipe_turn-left_v001"];
        sTurnSignalRight = [gameObjectSprites textureNamed:@"hud_swipe_turn-right_v001"];;
        
        sPatientBubble = [gameObjectSprites textureNamed:@"patient_bubble"];

        
        
        SKTextureAtlas *sirenAtlas = [SKTextureAtlas atlasNamed:@"sirens"];
        SKTexture *sirenLeft = [sirenAtlas textureNamed:@"amulance_sirens_left"];
        SKTexture *sirenRight = [sirenAtlas textureNamed:@"amulance_sirens_right"];        
        
        sSirensOn = [SKAction repeatActionForever:[SKAction animateWithTextures:@[sirenLeft, sirenRight] timePerFrame:0.8]];
        
        sTurnSignalOn = [SKAction repeatActionForever:[SKAction sequence:@[[SKAction fadeInWithDuration:0.15],[SKAction fadeOutWithDuration:0.15]]]];
        sTurnSignalFadeOut = [SKAction fadeOutWithDuration:0.15];
        
        
        
    });
    
}

- (NSString *)timeFormatted:(int)totalSeconds // from http://stackoverflow.com/a/1739411
{
    
    int seconds = totalSeconds % 60;
    int minutes = (totalSeconds / 60) % 60;
    //    int hours = totalSeconds / 3600;
    
    return [NSString stringWithFormat:@"%02d:%02d",minutes, seconds];
}


static SKTexture *sPlayerSprite = nil;
static SKTexture *sSirenDefaultTexture = nil;
static SKTexture *sTurnSignalLeft = nil;
static SKTexture *sTurnSignalRight = nil;
static SKTexture *sPatientBubble = nil;


static SKAction *sSirensOn = nil;
static SKAction *sTurnSignalOn = nil;
static SKAction *sTurnSignalFadeOut = nil;




@end
