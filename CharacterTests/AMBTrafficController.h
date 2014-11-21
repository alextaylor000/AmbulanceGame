//
//  AMBTrafficController.h
//  CharacterTests
//
//  Created by Alex Taylor on 2014-11-20.
//  Copyright (c) 2014 Alex Taylor. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>
#import <Foundation/Foundation.h>
#import "AMBTrafficVehicle.h"

typedef enum {
    VehicleTypeSedan = 1,
    VehicleTypeVan,
    VehicleTypeTruck,
    VehicleTypeRandom
} VehicleType;

typedef enum {
    VehicleSpeedSlow = 1,
    VehicleSpeedMedium,
    VehicleSpeedFast
} VehicleSpeed;


@interface AMBTrafficController : NSObject

- (AMBTrafficVehicle *)createVehicle:(VehicleType)type withSpeed:(VehicleSpeed)speed atPoint:(CGPoint)point withRotation:(CGFloat)rotation;

@end
