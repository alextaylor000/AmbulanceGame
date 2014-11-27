//
//  FiniteStateMachine.m
//  CharacterTests
//
//  Created by Alex Taylor on 2014-11-26.
//  Copyright (c) 2014 Alex Taylor. All rights reserved.
//

#import "FiniteStateMachine.h"

@implementation FiniteStateMachine

- (void)setState:(SEL)state {
    _activeState = state;
}

- (void)update {
    if (_activeState != nil) {
        [_controller performSelector:_activeState];
    }
}

- (void)testFunc {
    NSLog(@"Hey");
}

@end
