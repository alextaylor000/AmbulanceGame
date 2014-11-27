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
static const CGFloat resumeMovementDelayLower = 0.5; // if the vehicle is stopped, a random delay between when the blocking vehicle starts moving and when this vehicle starts moving.
static const CGFloat resumeMovementDelayUpper = 1.25;


@interface AMBTrafficVehicle ()

@property CGFloat targetSpeed;
@property SKSpriteNode *collisionZoneTailgating; // if a vehicle enters this zone in front of this vehicle, this vehicle's speed will be adjusted.
@property SKSpriteNode *collisionZoneStopping; // if a vehicle enters this zone in front of this vehicle, this vehicle will stop quickly.
@property AMBMovingCharacter *blockingVehicle; // the vehicle in front of this vechicle which is preventing it from moving. if this vehicle is stopped, blockingVehicle will be checked to determine when it's OK to begin moving again.


@end

@implementation AMBTrafficVehicle

- (instancetype)init {
    
    if (self = [super initWithColor:[SKColor whiteColor] size:CGSizeMake(80, 40)]) {
        // set constants
        self.speedPointsPerSec = 600;
        self.pivotSpeed = 0;
        
        self.accelTimeSeconds = 0.75;
        self.decelTimeSeconds = 0.35;
        
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
    
    return vehicle;
}



#pragma mark Other
- (void)changeState:(VehicleState)newState {
    _state = newState;
    
    switch (_state) {
        case VehicleIsStopped:
            [self stopMoving];
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
//            [self runAction:
//             [SKAction customActionWithDuration:self.decelTimeSeconds*8 actionBlock:
//                ^(SKNode *node, CGFloat t){
//                    [self adjustSpeedToTarget:_targetSpeed * 0.75];
//                    }] completion:
//             
//                ^(void){
//                     [self runAction:[SKAction customActionWithDuration:self.decelTimeSeconds*4 actionBlock:
//                        ^(SKNode *node, CGFloat t){
//                            [self adjustSpeedToTarget:_targetSpeed];
//                        }]];
//                    }
//             ];
            break;
            
    }
}


- (void)collidedWith:(SKPhysicsBody *)other victimNodeName:(NSString *)name {
    
    AMBMovingCharacter *node = (AMBMovingCharacter *)other.node;
    
    if ([name isEqualToString:@"trafficVehicleCollisionZone"]) {
        NSLog(@"%@ collisionZone", NSStringFromSelector(_cmd));
        if (node.isMoving) {
            if ([node isKindOfClass:[AMBTrafficVehicle class]]) {
                _targetSpeed = node.speedPointsPerSec * 0.75;
                [self changeState:VehicleIsAdjustingSpeed];
            }
            
        } else {
            [self changeState:VehicleIsStopped];
            _blockingVehicle = node;
        }
        
    } else if ([name isEqualToString:@"trafficVehicleStoppingZone"]) {
        NSLog(@"%@ stoppingZone, speed %1.5f", NSStringFromSelector(_cmd), self.speedPointsPerSec);
        [self changeState:VehicleIsStopped]; // screech to a halt if anything comes up in this zone
        _blockingVehicle = node;
    }
    
}

- (void)endedContactWith:(SKPhysicsBody *)other victimNodeName:(NSString *)name {

    AMBMovingCharacter *node = (AMBMovingCharacter *)other.node;
    
    if (_state == VehicleIsAdjustingSpeed) {
        if ([name isEqualToString:@"trafficVehicleCollisionZone"]) {
            _targetSpeed = node.speedPointsPerSec;
            [self changeState:VehicleIsAdjustingSpeed];
            [self changeState:VehicleIsDrivingStraight];
        }
    } else if (_state == VehicleIsStopped) {
        if ([name isEqualToString:@"trafficVehicleCollisionZone"]) {
            if ([node isKindOfClass:[AMBTrafficVehicle class]]) {
                self.speedPointsPerSec = node.speedPointsPerSec;
            }
            
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
        
    if (self.requestedMoveEvent) {
        [self authorizeMoveEvent:self.requestedMoveEventDegrees];
    }
    
//    if (_blockingVehicle.isMoving) {
//        
//        [self runAction:[SKAction waitForDuration:RandomFloatRange(resumeMovementDelayLower, resumeMovementDelayUpper)]
//             completion:^(void){
//                 [self changeState:VehicleIsDrivingStraight];
//             }];
//        
//    }
    
}

@end
