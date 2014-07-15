//
//  XXXCharacter.h
//  CharacterTests
//
//  Created by Alex Taylor on 2014-07-06.
//  Copyright (c) 2014 Alex Taylor. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

#define kMovementSpeed 0.8

@interface XXXCharacter : SKSpriteNode

@property BOOL isMoving;
@property BOOL moveForward;
@property BOOL moveLeft;
@property BOOL moveRight;
@property BOOL moveBack;
@property CGPoint targetDirection;
@property CGFloat targetRotation;

@property CGFloat movementSpeed;

- (void)updateWithTimeSinceLastUpdate:(CFTimeInterval)delta;

@end
