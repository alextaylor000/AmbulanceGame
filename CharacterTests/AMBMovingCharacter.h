//
//  AMBMovingCharacter.h
//  CharacterTests
//
//  Created by Alex Taylor on 2014-11-20.
//  Copyright (c) 2014 Alex Taylor. All rights reserved.
//
//  A high-level superclass that handles moving sprites, like traffic and the player.

#import "AMBCharacter.h"

@interface AMBMovingCharacter : AMBCharacter

@property (nonatomic) BOOL isMoving; // YES if the character is moving at speed; NO if it's not.



@end
