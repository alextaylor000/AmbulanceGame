//
//  AMBPowerup.m
//  CharacterTests
//
//  Created by Alex Taylor on 2014-12-04.
//  Copyright (c) 2014 Alex Taylor. All rights reserved.
//

#import "AMBPowerup.h"

@implementation AMBPowerup


- (instancetype)initAsType:(AMBPowerupType)type {
    
    SKTexture *texture;
    
    if (type == AMBPowerupFuel) {
        texture = [SKTexture textureWithImageNamed:@"fuel"];
        self.name = @"fuel";
    } else if (type == AMBPowerupInvincibility) {
        texture = [SKTexture textureWithImageNamed:@"invincibility"];
        self.name = @"invincibility";
    }
    
    if (self = [super initWithTexture:texture]) {
        self.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:self.size];
        self.physicsBody.categoryBitMask = categoryPowerup;
        self.physicsBody.collisionBitMask = 0x00000000;
        
    }
    
    return self;
}

@end
