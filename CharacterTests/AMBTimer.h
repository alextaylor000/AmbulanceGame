//
//  AMBTimer.h
//  AmbulanceGame
//
//  Created by Alex Taylor on 2015-02-28.
//  Copyright (c) 2015 Alex Taylor. All rights reserved.
//

#import <Foundation/Foundation.h>

/*
 
 timer class
 - set timer
 - get timer
 - add time
 - subtract time
 - timerDidEnd

 
 */

typedef enum {
    AMBTimerStateActive,
    AMBTimerStatePaused,
    AMBTimerStateEmpty
} AMBTimerState;


@interface AMBTimer : NSObject

@property NSTimeInterval secondsRemaining;
@property AMBTimerState timerState;

- (id)initWithSecondsRemaining:(NSTimeInterval)seconds;
- (void)update:(NSTimeInterval)currentTime;
- (void)setTimerTo:(NSTimeInterval)seconds;
- (void)addTime:(NSTimeInterval)seconds;
- (void)subtractTime:(NSTimeInterval)seconds;
- (NSTimeInterval)timeRemaining;
- (void)startTimer;
- (void)pauseTimer;
- (void)timerDidEnd;


@end
