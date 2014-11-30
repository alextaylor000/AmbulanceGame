//
//  AMBTrafficVehicleState.m
//  CharacterTests
//
//  Created by Alex Taylor on 2014-11-29.
//  Copyright (c) 2014 Alex Taylor. All rights reserved.
//

#import "AMBTrafficVehicleState.h"

@implementation AMBTrafficVehicleState

- (void)stateTest:(id)vehicle {
    // overridden by subclasses.
}

@end


#pragma mark States


@implementation AMBTrafficVehicleIsDrivingStraight

- (void)stateTest:(id)vehicle {
    AMBTrafficVehicle *trafficVehicle = (AMBTrafficVehicle *)vehicle;
    NSLog(@"State: VehicleIsDrivingStraight: %@", trafficVehicle.name);
}

@end