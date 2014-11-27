//
//  FiniteStateMachine.h
//  CharacterTests
//
//  Created by Alex Taylor on 2014-11-26.
//  Copyright (c) 2014 Alex Taylor. All rights reserved.
//  A function-based finite state machine

#import <Foundation/Foundation.h>

@interface FiniteStateMachine : NSObject

@property SEL activeState; // the currently active state
@property id controller;


/** Sets the current state of the entity. */
- (void)setState:(SEL)state;

/** Executes an update loop based on the active state. */
- (void)update;

@end
