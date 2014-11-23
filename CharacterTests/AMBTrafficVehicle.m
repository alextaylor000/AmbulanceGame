//
//  AMBTrafficVehicle.m
//  CharacterTests
//
//  Created by Alex Taylor on 2014-11-20.
//  Copyright (c) 2014 Alex Taylor. All rights reserved.
//

#import "AMBTrafficVehicle.h"
#import "SKTUtils.h"

static const CGFloat speedMultiplier = 150; // the vehicle speed (1, 2, 3) gets multiplied by this
static const int tailgateZoneMultiplier = 2; // the zone in which tailgating is enabled is the vehicle's height multiplied by this value.


@interface AMBTrafficVehicle ()

@property CGFloat targetSpeed;
@property SKSpriteNode *collisionZoneTailgating;

@end

@implementation AMBTrafficVehicle

- (instancetype)init {
    
    if (self = [super initWithColor:[SKColor whiteColor] size:CGSizeMake(80, 40)]) {
        // set constants
        self.speedPointsPerSec = 600;
        self.pivotSpeed = 0;
        
        self.accelTimeSeconds = 0.75;
        self.decelTimeSeconds = 0.35;
        
        
        // all new vehicles begin by driving straight
        [self changeState:VehicleIsDrivingStraight];
    }
    return self;
}

+ (AMBTrafficVehicle *)createVehicle:(VehicleType)type withSpeed:(VehicleSpeed)speed atPoint:(CGPoint)point withRotation:(CGFloat)rotation {
    
    AMBTrafficVehicle *vehicle = [[AMBTrafficVehicle alloc]init];
    
    vehicle.speedPointsPerSec = speed * speedMultiplier;
    vehicle.position = point;
    vehicle.zRotation = rotation;
    vehicle.direction = CGPointForAngle(rotation);
    vehicle.name = @"traffic"; // for grouped enumeration
    
    // physics
    vehicle.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:vehicle.size];
    vehicle.physicsBody.categoryBitMask = categoryTraffic;
    vehicle.physicsBody.collisionBitMask = 0;
    vehicle.physicsBody.contactTestBitMask = 0;
    
    vehicle.collisionZoneTailgating = [SKSpriteNode spriteNodeWithColor:[SKColor yellowColor] size:CGSizeMake(vehicle.size.width * tailgateZoneMultiplier, vehicle.size.height)]; // the coordinates are based on the node being oriented to the right
    vehicle.collisionZoneTailgating.name = @"trafficVehicleCollisionZone";
    vehicle.collisionZoneTailgating.zPosition = -1;
    vehicle.collisionZoneTailgating.position = CGPointMake(vehicle.size.width/2 + vehicle.collisionZoneTailgating.size.width/2 + 2, 0); // put the collision zone out in front; add two pixels to prevent the collision from registering
    vehicle.collisionZoneTailgating.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:vehicle.collisionZoneTailgating.size];
    vehicle.collisionZoneTailgating.physicsBody.categoryBitMask = categoryTrafficCollisionZone;
    vehicle.collisionZoneTailgating.physicsBody.collisionBitMask = 0;
    vehicle.collisionZoneTailgating.physicsBody.contactTestBitMask = categoryPlayer | categoryTraffic;
    [vehicle addChild:vehicle.collisionZoneTailgating];
    
    return vehicle;
}


- (void)changeState:(VehicleState)newState {
    _state = newState;
    SKAction *moveAction;
    
    switch (_state) {
        case VehicleIsStopped:
            //
            break;
            
        case VehicleIsDrivingStraight:
            if (!self.isMoving) {
                [self startMoving];
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


- (void)changeSpeedTo:(CGFloat)newSpeed {
    _targetSpeed = newSpeed;
//    [self changeState:VehicleIsAdjustingSpeed];
    [self adjustSpeedToTarget:_targetSpeed];
    NSLog(@"changeSpeedTo:");
}

- (void)collidedWith:(SKPhysicsBody *)other {
    _collisionZoneTailgating.color = [SKColor redColor];
}

- (void)updateWithTimeSinceLastUpdate:(CFTimeInterval)delta {
    // the superclass handles moving the sprite
    [super updateWithTimeSinceLastUpdate:delta];
}

@end
