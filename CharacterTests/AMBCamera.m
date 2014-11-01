//
//  AMBCamera.m
//  CharacterTests
//
//  Created by Alex Taylor on 2014-10-31.
//  Copyright (c) 2014 Alex Taylor. All rights reserved.
//

#import "AMBCamera.h"

@implementation AMBCamera

- (instancetype)initWithTargetSprite:(SKSpriteNode *)targetSprite {
    
    if (self = [super init]) {
        _targetSprite = targetSprite;
    }
    
    return self;
}


@end
