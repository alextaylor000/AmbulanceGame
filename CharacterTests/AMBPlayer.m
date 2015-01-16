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

static CGFloat FUEL_TIMER_INCREMENT = 10; // every x seconds, the fuel gets decremented




@interface AMBPlayer ()

//@property NSTimeInterval sceneDelta;


@property SKSpriteNode *sirens;
@property SKAction *sirensOn;
@property AMBScoreKeeper *scoreKeeper;
@property NSTimeInterval fuelTimer; // times when the fuel started being depleted by startMoving


@end

@implementation AMBPlayer


- (instancetype) init {
    self = [super initWithImageNamed:@"asset_ambulance_20140609"];
    
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
    SKTextureAtlas *sirenAtlas = [SKTextureAtlas atlasNamed:@"sirens"];
    SKTexture *sirenLeft = [sirenAtlas textureNamed:@"amulance_sirens_left.png"];
    SKTexture *sirenRight = [sirenAtlas textureNamed:@"amulance_sirens_right.png"];
    _sirensOn = [SKAction animateWithTextures:@[sirenLeft, sirenRight] timePerFrame:0.8];

    _sirens = [SKSpriteNode spriteNodeWithTexture:sirenLeft];
    _sirens.hidden = YES;
    _sirens.position = CGPointMake(25, 0);
    _sirens.size = CGSizeMake(self.size.width*0.75,self.size.height*0.75);

    [self addChild:_sirens];
    
    _scoreKeeper = [AMBScoreKeeper sharedInstance]; // hook up the shared instance of the score keeper so we can talk to it
    
    _fuel = 3;
    _fuelTimer = 0;
    
    self.controlState = PlayerIsStopped;
    
    
    
    return self;
}

- (void)updateWithTimeSinceLastUpdate:(CFTimeInterval)delta {
    // the superclass handles moving the sprite
    [super updateWithTimeSinceLastUpdate:delta];


    if (self.controlState == PlayerIsChangingLanes) {
        [self authorizeMoveEvent:_laneChangeDegrees snapToLane:NO];
    }

    AMBLevelScene *__weak owningScene = [self characterScene]; // declare a reference to the scene as weak, to prevent a reference cycle. Inspired by animationDidComplete in Adventure.
    
    // update the patient timer
    if (self.patient) {
        NSTimeInterval ttl = [self.patient getPatientTTL];
        owningScene.patientTimeToLive.text = [NSString stringWithFormat:@"PATIENT: %1.1f",ttl];
    }
    

    
    
    if (self.isMoving) {
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
            
            if (_fuel < 1) {
                [self stopMovingWithDecelTime:self.decelTimeSeconds];
                [_scoreKeeper eventLabelWithText:@"OUT OF FUEL! GAME OVER"];
        

            }
            
        }
        
        // T-intersections
        if (self.currentTileProperties[@"invalid_directions"]) {
            CGRect invalidDirections = CGRectFromString(self.currentTileProperties[@"invalid_directions"]);
            CGPoint invalidDirection1 = invalidDirections.origin;
            CGPoint invalidDirection2 = CGPointMake(invalidDirections.size.width, invalidDirections.size.height);


#if DEBUG_PLAYER_CONTROL
 //           NSLog(@"** invalid: %1.0f,%1.0f,  direction: %1.0f,%1.0f",invalidDirection.x,invalidDirection.y,self.direction.x,self.direction.y);
#endif
            
            if (self.controlState != PlayerIsChangingLanes && self.controlState != PlayerIsTurning) {
                if (CGPointEqualToPoint(invalidDirection1, self.direction) ||
                    CGPointEqualToPoint(invalidDirection2, self.direction)) {
                    [self slamBrakes]; // instead of stopMoving; ends with PlayerIsStoppedAtTIntersection
                }
            }
         
        }

    }
}


- (void)slamBrakes {
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
#if DEBUG_PLAYER_CONTROL
        NSLog(@"[control] PlayerIsDecelerating -> stopMoving -> PlayerIsStopped");
#endif

        
    }];
    
}

- (void)leaveIntersectionWithInput:(PlayerControls)input {

    self.controlState = PlayerIsLeavingTIntersection;

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
#if DEBUG_PLAYER_CONTROL
            NSLog(@"[control] PlayerIsLeavingTIntersection -> leaveIntersection -> PlayerIsDrivingStraight");
#endif
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
            [_sirens runAction:[SKAction repeatActionForever:_sirensOn] withKey:@"sirensOn"];
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

- (void)collidedWith:(SKPhysicsBody *)other victimNodeName:(NSString *)name {
    
    AMBLevelScene *__weak owningScene = [self characterScene]; // declare a reference to the scene as weak, to prevent a reference cycle. Inspired by animationDidComplete in Adventure.
    
    SKAction *action;
    
    switch (other.categoryBitMask) {
        case categoryPatient:
            [self loadPatient:(AMBPatient *)other.node];
            break;
            
        case categoryTraffic:
            action = [SKAction sequence:@[[SKAction fadeAlphaTo:0.1 duration:0],[SKAction waitForDuration:0.1],[SKAction fadeAlphaTo:1.0 duration:0.1],[SKAction waitForDuration:0.1]]];
            [self runAction:[SKAction repeatAction:action count:5]];
            break;
            
        case categoryHospital:
            if (self.patient) {
                [_scoreKeeper scoreEventDeliveredPatient:self.patient];
                [self unloadPatient];
            }
            break;
            
        case categoryPowerup:
            // fuel! add 1
            if (_fuel < 3) {
                _fuel++;
                owningScene.fuelStatus.text = [NSString stringWithFormat:@"FUEL: %1.0f/3",_fuel];
                [_scoreKeeper eventLabelWithText:@"+1 FUEL!"];
                [other.node removeFromParent];
                
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
            
        case PlayerIsLeavingTIntersection:
            
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
                [self printMessage:message];
                
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
                    message = @"[control] PlayerIsChangingLanes -> handleInput:keyDOWN/turnLeft";
                    [self printMessage:message];
                    
                } else if   (input == PlayerControlsTurnRight) {
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
    #if DEBUG_PLAYER_CONTROL
        NSLog(@"%@", message);
    #endif
    
}

@end
