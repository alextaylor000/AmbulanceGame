//
//  AMBEndlessTimer.m
//  AmbulanceGame
//
//  Created by Alex Taylor on 2015-08-23.
//  Copyright (c) 2015 Alex Taylor. All rights reserved.
//

#import "AMBEndlessTimer.h"

@implementation AMBEndlessTimer

- (id)initWithSecondsRemaining:(NSTimeInterval)seconds {
    self = [super initWithSecondsRemaining:seconds];
    return self;
}

- (void)startTimer {
    [self setTimerState:AMBTimerStateIdle];
}

- (void)pauseTimer {
    [self setTimerState:AMBTimerStateIdle];
}

- (void)resumeTimer {
    [self setTimerState:AMBTimerStateIdle];
}

- (NSString *)labelText {
    return @"∞";
}

@end
