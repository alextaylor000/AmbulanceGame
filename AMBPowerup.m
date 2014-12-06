//
//  AMBPowerup.m
//  CharacterTests
//
//  Created by Alex Taylor on 2014-12-04.
//  Copyright (c) 2014 Alex Taylor. All rights reserved.
//

#import "AMBPowerup.h"

@implementation AMBPowerup

- (instancetype)init {
    SKTexture *fuelTexture = [SKTexture textureWithImageNamed:@"fuel"];
    
    if (self = [super initWithTexture:fuelTexture]) {
        self.size = CGSizeMake(75, 75);
        self.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:self.size];
        self.physicsBody.categoryBitMask = categoryPowerup;
        self.physicsBody.collisionBitMask = 0x00000000;
        
        
    }
    
    return self;
}

@end
