//
//  AMBHospital.m
//  CharacterTests
//
//  Created by Alex Taylor on 2014-09-16.
//  Copyright (c) 2014 Alex Taylor. All rights reserved.
//

#import "AMBHospital.h"

@implementation AMBHospital

- (instancetype) init {
    if (self = [super initWithColor:[SKColor whiteColor] size:CGSizeMake(256, 256)]) {
        
        self.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:CGSizeMake(self.size.width, self.size.height)]; // the hospital entity is the invisible area that the patient can be dropped off within. the actual graphic is simply placed on the tilemap.
        self.physicsBody.categoryBitMask = categoryHospital;
        self.physicsBody.collisionBitMask = 0x00000000;
        self.hidden = YES;
    
    }
    
    return self;
}

@end
