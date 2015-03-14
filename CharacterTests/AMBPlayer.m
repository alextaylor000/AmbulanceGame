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






@interface AMBPlayer ()

//@property NSTimeInterval sceneDelta;


@property SKSpriteNode *sirens;
@property SKSpriteNode *turnSignalLeft;
@property SKSpriteNode *turnSignalRight;

@property AMBScoreKeeper *scoreKeeper;
@property NSTimeInterval fuelTimer; // times when the fuel started being depleted by startMoving


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
    _turnSignalLeft.position = CGPointMake(20, 28);
    _turnSignalLeft.zPosition = -1;
    _turnSignalLeft.alpha = 0;
    [self addChild:_turnSignalLeft];
    
    _turnSignalRight = [SKSpriteNode spriteNodeWithTexture:sTurnSignalRight];
    _turnSignalRight.position = CGPointMake(20, -28);
    _turnSignalRight.zPosition = -1;
    _turnSignalRight.alpha = 0;
    [self addChild:_turnSignalRight];
    
    _turnSignalState = PlayerTurnSignalStateOff;
    
    _scoreKeeper = [AMBScoreKeeper sharedInstance]; // hook up the shared instance of the score keeper so we can talk to it
    
    _fuel = 3;
    _fuelTimer = 0;
    
    self.controlState = PlayerIsStopped;
    
    
    
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
        owningScene.patientTimeToLive.text = [NSString stringWithFormat:@"PATIENT: %1.1f",ttl];

        if (self.patient.state == PatientIsDead) {
            [self unloadPatient];
        }
    
    }
    

    
    
    if (self.isMoving) {
        if (self.controlState == PlayerIsChangingLanes) {
            [self authorizeMoveEvent:_laneChangeDegrees snapToLane:NO];
        }
        
        
        _fuelTimer += delta;
#if DEBUG_FUEL
        NSLog(@"fueltimer=%1.0f",_fuelTimer);
#endif
        
        
        // update fuel if we're moving
        if (_fuelTimer > FUEL_TIMER_INCREMENT) {
            _fuelTimer = 0;
            _fuel--; // decrement fuel
#if DEBUG_FUEL
            NSLog(@"fuel is now %f",_fuel);
#endif
            
            owningScene.fuelStatus.text = [NSString stringWithFormat:@"FUEL: %1.0f/3",_fuel];
            
            if (_fuel == 0) {
                [self stopMovingWithDecelTime:self.decelTimeSeconds];
                [_scoreKeeper showNotification:ScoreKeeperNotificationFuelEmpty]; // OUT OF FUEL!
                
                
            }
            
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
                    self.controlState == PlayerIsDrivingStraight) {
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
            
            owningScene.patientTimeToLive.text = @"PATIENT: --";
            
            
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
        return YES;
    }
    
    return NO;
}

-(BOOL)unloadPatient {
    // unloads a patient from the ambulance (if there is one)
    if (_patient) {
        [self changeState:AmbulanceIsEmpty];
        
        if (_patient.state == PatientIsEnRoute) {
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
    SKAction *speedPenalty = [SKAction sequence:@[[SKAction waitForDuration:5.0],[SKAction runBlock:^(void) { [self adjustSpeedToTarget:self.nativeSpeed]; NSLog(@"Speed penalty end"); [self removeActionForKey:@"blink"]; self.alpha = 1.0; // reset alpha
    }]]];
    
    switch (other.categoryBitMask) {
        case categoryPatient:
            [self loadPatient:(AMBPatient *)other.node];
            break;
            
        case categoryTraffic:
            if (![self actionForKey:@"invincibility"]) {
#warning preload this action
                
                action = [SKAction sequence:@[[SKAction fadeAlphaTo:0.1 duration:0],[SKAction waitForDuration:0.1],[SKAction fadeAlphaTo:1.0 duration:0.1],[SKAction waitForDuration:0.1]]];
                [self runAction:[SKAction repeatActionForever:action] withKey:@"blink"];
                
                // slow down the player temporarily
                [self adjustSpeedToTarget:self.nativeSpeed * 0.75];
                //NSLog(@"Speed penalty begin");
                [self removeActionForKey:@"speedPenalty"]; // remove action if it's running already
                [self runAction: speedPenalty withKey:@"speedPenalty"];
            }
            
            break;
            
        case categoryHospital:
            if (self.patient) {
                [_scoreKeeper scoreEventDeliveredPatient:self.patient];
                [self unloadPatient];
            }
            break;
            
        case categoryPowerup:

            if ([other.node.name isEqualToString:@"fuel"]) {
                if (_fuel < 3) {
                    _fuel++;
                    owningScene.fuelStatus.text = [NSString stringWithFormat:@"FUEL: %1.0f/3",_fuel];
                    //[_scoreKeeper eventLabelWithText:@"+1 FUEL!"];
                    [_scoreKeeper showNotification:ScoreKeeperNotificationFuelUp];
                    
                    [self.levelScene.tutorialOverlay playerDidPerformEvent:PlayerEventPickupFuel]; // tutorial event
                    
                    AMBCharacter *powerup = (AMBCharacter *)other.node;
                    [powerup removeFromParent];
                    [powerup.minimapAvatar removeFromParent];
                    
                    
                }
            } else if ([other.node.name isEqualToString:@"invincibility"]) {
#warning preload this action
                action = [SKAction sequence:@[[SKAction colorizeWithColor:[SKColor greenColor] colorBlendFactor:0.6 duration:0.25],[SKAction waitForDuration:PLAYER_INVINCIBLE_TIME],[SKAction colorizeWithColorBlendFactor:0.0 duration:0.25]]];
                [self runAction:action withKey:@"invincibility"]; // as long as this action exists on the player, the player will be immune to traffic
                
                [_scoreKeeper showNotification:ScoreKeeperNotificationInvincibility];
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


#pragma mark Assets
+ (void)loadSharedAssets {
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        SKTextureAtlas *gameObjectSprites = [SKTextureAtlas atlasNamed:@"GameObjectSprites"];
        sPlayerSprite = [gameObjectSprites textureNamed:@"ambulance"];
        sTurnSignalLeft = [gameObjectSprites textureNamed:@"hud_swipe_turn-left_v001"];
        sTurnSignalRight = [gameObjectSprites textureNamed:@"hud_swipe_turn-right_v001"];;
        
        SKTextureAtlas *sirenAtlas = [SKTextureAtlas atlasNamed:@"sirens"];
        SKTexture *sirenLeft = [sirenAtlas textureNamed:@"amulance_sirens_left"];
        SKTexture *sirenRight = [sirenAtlas textureNamed:@"amulance_sirens_right"];        
        sSirensOn = [SKAction repeatActionForever:[SKAction animateWithTextures:@[sirenLeft, sirenRight] timePerFrame:0.8]];
        
        sTurnSignalOn = [SKAction repeatActionForever:[SKAction sequence:@[[SKAction fadeInWithDuration:0.15],[SKAction fadeOutWithDuration:0.15]]]];
        sTurnSignalFadeOut = [SKAction fadeOutWithDuration:0.15];
        
        
    });
    
}

static SKTexture *sPlayerSprite = nil;
static SKTexture *sSirenDefaultTexture = nil;
static SKTexture *sTurnSignalLeft = nil;
static SKTexture *sTurnSignalRight = nil;

static SKAction *sSirensOn = nil;
static SKAction *sTurnSignalOn = nil;
static SKAction *sTurnSignalFadeOut = nil;




@end
