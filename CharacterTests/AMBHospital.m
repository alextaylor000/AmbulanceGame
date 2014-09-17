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
    SKTexture *hospitalTexture = [SKTexture textureWithImageNamed:@"hospital"]; // TODO: shared asset loading
    
    if (self = [super initWithTexture:hospitalTexture]) {
        
        self.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:CGSizeMake(self.size.width * 3, self.size.height * 3)]; // for the physics body, expand the hospital's size so that it encompasses all the surrounding road blocks. this obviously assumes that the hospital occupies one entire tile!
        self.physicsBody.categoryBitMask = categoryHospital;
        self.physicsBody.collisionBitMask = 0x00000000;
        
        //self.zPosition = 200; // TODO: do we need to manage z positions?
    
    }
    
    return self;
}

@end
