//
//  AMBTimer.m
//  AmbulanceGame
//
//  Created by Alex Taylor on 2015-02-28.
//  Copyright (c) 2015 Alex Taylor. All rights reserved.
//

#import "AMBTimer.h"


@implementation AMBTimer {
    NSTimeInterval _startTime;
    NSTimeInterval _lastUpdate;
}

- (id)initWithSecondsRemaining:(NSTimeInterval)seconds {
    if (self = [super init]) {
        [self setTimerTo:seconds];
    }
    
    return self;
}

- (void)startTimer {
    _startTime = CACurrentMediaTime();
    _timerState = AMBTimerStateActive;
    
}

- (void)pauseTimer {
    _timerState = AMBTimerStatePaused;
}

- (void)resumeTimer {
    if (_timerState == AMBTimerStatePaused) {
        _timerState = AMBTimerStateActive;
        _lastUpdate = CACurrentMediaTime();
    }
}

- (void)setTimerTo:(NSTimeInterval)seconds {
    _secondsRemaining = seconds;
}

- (NSTimeInterval)timeRemaining {
    return _secondsRemaining;
}

- (void)addTime:(NSTimeInterval)seconds {
    _secondsRemaining += seconds;
}

- (void)subtractTime:(NSTimeInterval)seconds {
    _secondsRemaining -= seconds;
    
    if (_secondsRemaining < 0) {
        _secondsRemaining = 0;
    }
}

- (void)update:(NSTimeInterval)currentTime {

    if (_timerState == AMBTimerStateActive) {
        if (!_lastUpdate) {
            _lastUpdate = currentTime;
        }
        
        NSTimeInterval diff = currentTime - _lastUpdate;
        [self subtractTime: diff];
        
        if (_secondsRemaining == 0) {
            [self timerDidEnd];
        }
        
        _lastUpdate = currentTime;
        
    }

}

- (void)timerDidEnd {
    _timerState = AMBTimerStateEmpty;
}

- (NSString *)labelText {
    return [self timeFormatted:self.secondsRemaining];
}

- (NSString *)timeFormatted:(int)totalSeconds // from http://stackoverflow.com/a/1739411
{
    
    int seconds = totalSeconds % 60;
    int minutes = (totalSeconds / 60) % 60;
    //    int hours = totalSeconds / 3600;
    
    return [NSString stringWithFormat:@"%02d:%02d",minutes, seconds];
}


@end
