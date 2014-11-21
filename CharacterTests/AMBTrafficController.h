//
//  AMBTrafficController.h
//  CharacterTests
//
//  Created by Alex Taylor on 2014-11-20.
//  Copyright (c) 2014 Alex Taylor. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>
#import <Foundation/Foundation.h>
#import "AMBCharacter.h"

typedef enum {
    Sedan = 1,
    Van,
    Truck,
    RandomType
} VehicleType;


@interface AMBTrafficController : NSObject

- (AMBCharacter *)createVehicle:(VehicleType)type atPoint:(CGPoint)point withRotation:(CGFloat)rotation;

@end
