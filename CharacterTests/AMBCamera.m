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
        
        // set properties
        _boundingBox = CGSizeMake(300, 300);
        _cameraIsActive = NO;
        _reorientsToTargetSpriteDirection = YES;
        _idleOffset = CGPointMake(0, 0);
        _activeOffset = CGPointMake(0, 200);
        
        // set initial position to center on the target sprite
        self.position = _targetSprite.position;
        
#if DEBUG
        SKSpriteNode *boundingBox = [SKSpriteNode spriteNodeWithColor:[SKColor whiteColor] size:_boundingBox];
        boundingBox.alpha = 0.15;
        [self addChild:boundingBox];
#endif
    }
    
    return self;
}


- (void)updateWithTimeSinceLastUpdate:(CFTimeInterval)delta {
    self.position = _targetSprite.position;

}


@end
