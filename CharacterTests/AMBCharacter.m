//
//  AMBCharacter.m
//  CharacterTests
//
//  Created by Alex Taylor on 2014-09-14.
//  Copyright (c) 2014 Alex Taylor. All rights reserved.
//

#import "AMBCharacter.h"

@implementation AMBCharacter


- (instancetype)initWithTexture:(SKTexture *)texture {
    if (self = [super initWithTexture:texture]) {
        self.spawnTime = CACurrentMediaTime();
    }
    
    return  self;
}

- (void)addObjectToNode:(SKNode *)node atPosition:(CGPoint)position {
    self.position = position;
    [node addChild:self];
}

@end
