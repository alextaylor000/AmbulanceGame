//
//  AMBTrafficVehicle.m
//  CharacterTests
//
//  Created by Alex Taylor on 2014-11-20.
//  Copyright (c) 2014 Alex Taylor. All rights reserved.
//

#import "AMBTrafficVehicle.h"
#import "AMBTrafficVehicleState.h"
#import "SKTUtils.h"





@interface AMBTrafficVehicle ()

@property CGFloat targetSpeed;
@property AMBMovingCharacter *blockingVehicle; // the vehicle in front of this vechicle which is preventing it from moving. if this vehicle is stopped, blockingVehicle will be checked to determine when it's OK to begin moving again.
@property BOOL isAtIntersection; // YES if this vehicle just entered an intersection


@property AMBTrafficVehicleState *currentState;



@end

@implementation AMBTrafficVehicle


- (instancetype)initWithTexture:(SKTexture *)texture {
    
    if (self = [super initWithTexture:texture]) {
        // set constants
        self.pivotSpeed = 0;
        
        self.accelTimeSeconds = 0.75;
        self.decelTimeSeconds = 0.35;
        
        
    }
    return self;
}


+ (AMBTrafficVehicle *)createVehicle:(VehicleType)type withSpeed:(VehicleSpeed)speed atPoint:(CGPoint)point withRotation:(CGFloat)rotation shouldTurnAtIntersections:(BOOL)shouldTurn {
    
    AMBTrafficVehicle *vehicle = [[AMBTrafficVehicle alloc]initWithTexture:sVehicleType1Texture];
    
    if (type == VehicleTypeRandom) {
        [vehicle swapTexture];
    }
    
    vehicle.shouldTurnAtIntersections = shouldTurn;
    vehicle.speedPointsPerSec = speed * speedMultiplier;
    vehicle.nativeSpeed = vehicle.speedPointsPerSec; // store the native speed so we can refer to it later
    vehicle.position = point;
    vehicle.originalPosition = point; // store the original position so we can reset it based on distance from player
    vehicle.zRotation = rotation;
    vehicle.originalRotation = rotation; // store the original rotation so we can reset it based on distance from player
    vehicle.direction = CGPointForAngle(rotation);
    vehicle.originalDirection = vehicle.direction;
    vehicle.name = @"traffic"; // for grouped enumeration
    
    // physics
    vehicle.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:CGSizeMake(vehicle.size.width * 0.75, vehicle.size.height * 0.75)];
    vehicle.physicsBody.categoryBitMask = categoryTraffic;
    vehicle.physicsBody.collisionBitMask = 0;

    
    vehicle.collisionZoneTailgating = [SKSpriteNode spriteNodeWithColor:[SKColor yellowColor] size:CGSizeMake(vehicle.size.width * tailgateZoneMultiplier, vehicle.size.height)]; // the coordinates are based on the node being oriented to the right
    vehicle.collisionZoneTailgating.name = @"trafficVehicleCollisionZone";
    vehicle.collisionZoneTailgating.zPosition = -2;
    vehicle.collisionZoneTailgating.position = CGPointMake(vehicle.size.width/2 + vehicle.collisionZoneTailgating.size.width/2 + 2, 0); // put the collision zone out in front; add two pixels to prevent the collision from registering
    vehicle.collisionZoneTailgating.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:vehicle.collisionZoneTailgating.size];
    vehicle.collisionZoneTailgating.physicsBody.categoryBitMask = categoryTrafficCollisionZone;
    vehicle.collisionZoneTailgating.physicsBody.collisionBitMask = 0;
    vehicle.collisionZoneTailgating.physicsBody.contactTestBitMask = categoryPlayer | categoryTraffic;
    
    vehicle.collisionZoneStopping = [SKSpriteNode spriteNodeWithColor:[SKColor redColor] size:CGSizeMake(vehicle.size.width * tailgateZoneMultiplier*0.4, vehicle.size.height)];
    vehicle.collisionZoneStopping.name = @"trafficVehicleStoppingZone";
    vehicle.collisionZoneStopping.zPosition = -1;
    vehicle.collisionZoneStopping.position = CGPointMake(vehicle.size.width/2 + vehicle.collisionZoneStopping.size.width/2 + 2, 0);
    vehicle.collisionZoneStopping.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:vehicle.collisionZoneStopping.size];
    vehicle.collisionZoneStopping.physicsBody.categoryBitMask = categoryTrafficStoppingZone;
    vehicle.collisionZoneStopping.physicsBody.collisionBitMask = 0;
    vehicle.collisionZoneStopping.physicsBody.contactTestBitMask = categoryPlayer | categoryTraffic;
    
    
    [vehicle addChild:vehicle.collisionZoneTailgating];
    [vehicle addChild:vehicle.collisionZoneStopping];
    
    vehicle.collisionZoneStopping.hidden = YES;
    vehicle.collisionZoneTailgating.hidden = YES;

    // enter the initial state
    vehicle.currentState = [AMBTrafficVehicleIsDrivingStraight sharedInstance];
    [vehicle.currentState enterState:vehicle];
    
    return vehicle;
}



#pragma mark Other
- (void)changeState:(VehicleState)newState {
    _state = newState;
    
    switch (_state) {
        case VehicleIsStopped:
            [self stopMovingWithDecelTime:self.decelTimeSeconds];
            break;
            
            
        case VehicleIsDrivingStraight:
            if (!self.isMoving) {
                [self startMoving];
                _blockingVehicle = nil; // clear the blocking vehicle
            }
            break;
            
            
        case VehicleCanTurn:
            //
            break;
        
            
        case VehicleIsTailgating:
            // 
            break;
            
            
        case VehicleIsAdjustingSpeed:
            [self adjustSpeedToTarget:_targetSpeed];
            break;
            
    }
}

- (void)beganCollision:(SKPhysicsContact *)contact {
    AMBTrafficVehicleState *newState = [_currentState beganCollision:contact  context:self];
    
    if (newState) {
        _currentState = newState;
        [_currentState enterState:self];
    }
}

- (void)endedCollision:(SKPhysicsContact *)contact {
    AMBTrafficVehicleState *newState = [_currentState endedCollision:contact  context:self];
    
    if (newState) {
        _currentState = newState;
        [_currentState enterState:self];
        
    }

}

- (void)collidedWith:(SKPhysicsBody *)other victimNodeName:(NSString *)name {
    
    AMBMovingCharacter *node = (AMBMovingCharacter *)other.node;
    
    if ([name isEqualToString:@"trafficVehicleCollisionZone"]) {
        //NSLog(@"[%@] %@ collisionZone", self.name, NSStringFromSelector(_cmd));
        if (node.isMoving) {
            if ([node isKindOfClass:[AMBTrafficVehicle class]]) {
                //NSLog(@"[%@] %@ collisionZone | encountered traffic vehicle; state -> VehicleIsAdjustingSpeed", self.name, NSStringFromSelector(_cmd));
                _targetSpeed = node.speedPointsPerSec * 0.75;
                [self changeState:VehicleIsAdjustingSpeed];
            } else {
                //NSLog(@"[%@] %@ collisionZone | encountered non-traffic entity; speed -> 80%% native", self.name, NSStringFromSelector(_cmd));
                _targetSpeed = self.speedPointsPerSec * 0.8;
                [self changeState:VehicleIsAdjustingSpeed];
            }
            
        } else {
            //NSLog(@"[%@] %@ collisionZone | encountered stopped node; state -> VehicleIsStopped", self.name, NSStringFromSelector(_cmd));
            [self changeState:VehicleIsStopped];
            _blockingVehicle = node;
        }
        
    } else if ([name isEqualToString:@"trafficVehicleStoppingZone"]) {
        //NSLog(@"[%@] %@ stoppingZone | state -> VehicleIsStopped; previous speed: %1.5f", self.name, NSStringFromSelector(_cmd), self.speedPointsPerSec);
        [self changeState:VehicleIsStopped]; // screech to a halt if anything comes up in this zone
        _blockingVehicle = node;
    }
    
}

- (void)endedContactWith:(SKPhysicsBody *)other victimNodeName:(NSString *)name {

    AMBMovingCharacter *node = (AMBMovingCharacter *)other.node;
    
    if (_state == VehicleIsAdjustingSpeed) {
        if ([name isEqualToString:@"trafficVehicleCollisionZone"]) {
            if ([node isKindOfClass:[AMBTrafficVehicle class]]) {
                //NSLog(@"[%@] %@ collisionZone | AdjustSpeed to match; targetSpeed: %1.5f", self.name, NSStringFromSelector(_cmd), node.speedPointsPerSec);
                _targetSpeed = self.nativeSpeed;

            } else {
                //NSLog(@"[%@] %@ collisionZone | AdjustSpeed to native; targetSpeed: %1.5f", self.name, NSStringFromSelector(_cmd), self.nativeSpeed);
                _targetSpeed = self.nativeSpeed; // revert to native speed if we're not matching
            }

            [self removeActionForKey:@"adjustSpeed"];
            [self changeState:VehicleIsAdjustingSpeed];

            //NSLog(@"[%@] %@ collisionZone | state VehicleIsDrivingStraight", self.name, NSStringFromSelector(_cmd));
            [self changeState:VehicleIsDrivingStraight];

        }
    } else if (_state == VehicleIsStopped) {
        if ([name isEqualToString:@"trafficVehicleCollisionZone"]) {

            if ([node isKindOfClass:[AMBTrafficVehicle class]]) {
                //NSLog(@"[%@] %@ collisionZone | setting speed to target node speed: %1.f", self.name, NSStringFromSelector(_cmd), node.speedPointsPerSec);
                self.speedPointsPerSec = self.nativeSpeed;
            } else {
                //NSLog(@"[%@] %@ collisionZone | setting speed to native speed: %1.5f", self.name, NSStringFromSelector(_cmd), self.nativeSpeed);
                self.speedPointsPerSec = self.nativeSpeed;
            }

            //NSLog(@"[%@] %@ collisionZone | state VehicleStopped -> VehicleIsDrivingStraight; speed %1.5f", self.name, NSStringFromSelector(_cmd),self.speedPointsPerSec);
            [self runAction:[SKAction waitForDuration:RandomFloatRange(resumeMovementDelayLower, resumeMovementDelayUpper)]
                 completion:^(void){
                     [self changeState:VehicleIsDrivingStraight];
                 }];
        }
    }
}

- (void)updateWithTimeSinceLastUpdate:(CFTimeInterval)delta {
    // the superclass handles moving the sprite
    [super updateWithTimeSinceLastUpdate:delta];

    // state
    AMBTrafficVehicleState *newState = [_currentState updateWithTimeSinceLastUpdate:delta context:self];
    
    if (newState) {
        _currentState = newState;
        [_currentState enterState:self];
    }
    
    
}

- (void)swapTexture {
    SKTexture *newTexture = [sVehicleTypeArray objectAtIndex:(int)RandomFloatRange(0, 4)];
    [self setTexture:newTexture];
}

#pragma mark Assets
+ (void)loadSharedAssets {
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
    
        // thought I needed to preload this, but it seems to use the same instance as other invocations (e.g. in powerup)
        SKTextureAtlas *gameObjectSprites = [SKTextureAtlas atlasNamed:@"GameObjectSprites"];
        
        sVehicleType1Texture = [gameObjectSprites textureNamed:@"traffic01"];
        sVehicleType2Texture = [gameObjectSprites textureNamed:@"traffic02"];
        sVehicleType3Texture = [gameObjectSprites textureNamed:@"traffic03"];
        sVehicleType4Texture = [gameObjectSprites textureNamed:@"traffic04"];
        sVehicleType5Texture = [gameObjectSprites textureNamed:@"traffic05"];

        sVehicleTypeArray = [NSArray arrayWithObjects:sVehicleType1Texture, sVehicleType2Texture, sVehicleType3Texture, sVehicleType4Texture, sVehicleType5Texture, nil];
    });
    
    
}

static SKTexture *sVehicleType1Texture = nil;
static SKTexture *sVehicleType2Texture = nil;
static SKTexture *sVehicleType3Texture = nil;
static SKTexture *sVehicleType4Texture = nil;
static SKTexture *sVehicleType5Texture = nil;
static NSArray *sVehicleTypeArray = nil;


- (SKTexture *)vehicleType1Texture {
    return sVehicleType1Texture;
}

@end


