//
//  AMBTrafficVehicle.m
//  CharacterTests
//
//  Created by Alex Taylor on 2014-11-20.
//  Copyright (c) 2014 Alex Taylor. All rights reserved.
//

#import "AMBTrafficVehicle.h"

static const CGFloat VEHICLE_BASE_SPEED_POINTS_PER_SEC = 150; // this value will be multiplied by the VehicleSpeed (currently 1, 2, or 3)

@implementation AMBTrafficVehicle

- (id)init {
    
    if (self = [super init]) {
        // all new vehicles begin by driving straight
        [self changeState:VehicleIsDrivingStraight];
    }
    return self;
}

- (void)changeState:(VehicleState)newState {
    _state = newState;
    SKAction *moveAction;
    
    switch (_state) {
        case VehicleIsStopped:
            //
            break;
            
        case VehicleIsDrivingStraight:
            //
            break;
            
        case VehicleCanTurn:
            //
            break;
        
        case VehicleIsTailgating:
            // 
            break;
            
    }
}

@end
