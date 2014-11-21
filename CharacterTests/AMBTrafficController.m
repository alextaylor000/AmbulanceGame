//
//  AMBTrafficController.m
//  CharacterTests
//
//  Created by Alex Taylor on 2014-11-20.
//  Copyright (c) 2014 Alex Taylor. All rights reserved.
//

#import "AMBTrafficController.h"

@implementation AMBTrafficController

- (AMBCharacter *)createVehicle:(VehicleType)type atPoint:(CGPoint)point withRotation:(CGFloat)rotation {
    
    AMBCharacter *vehicle = (AMBCharacter *)[SKSpriteNode spriteNodeWithColor:[SKColor whiteColor] size:CGSizeMake(80, 40)]; // placeholder sprite; the real texture and size would be determined by the type of vehicle
    
    vehicle.position = point;
    vehicle.zRotation = rotation;
    vehicle.name = @"traffic"; // for grouped enumeration
    return vehicle;
}

@end
