//
//  AMBCharacter.m
//  CharacterTests
//
//  Created by Alex Taylor on 2014-09-14.
//  Copyright (c) 2014 Alex Taylor. All rights reserved.
//

#import "AMBCharacter.h"

@implementation AMBCharacter

- (id)init {
    if (self = [super init]) {
        // set the spawn time in init because we want to make absolutely sure it runs no matter how the object is created
        self.spawnTime = CACurrentMediaTime();
    }
    return self;
}

- (void)addObjectToNode:(SKNode *)node atPosition:(CGPoint)position {
    self.position = position;
    [node addChild:self];
}

@end
