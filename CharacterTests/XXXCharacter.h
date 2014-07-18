//
//  XXXCharacter.h
//  CharacterTests
//
//  Created by Alex Taylor on 2014-07-06.
//  Copyright (c) 2014 Alex Taylor. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>


@interface XXXCharacter : SKSpriteNode


- (void)updateWithTimeSinceLastUpdate:(CFTimeInterval)delta;
- (void)startMoving;
- (void)stopMoving;
- (void)turnByAngle:(CGFloat)degrees;

@end
