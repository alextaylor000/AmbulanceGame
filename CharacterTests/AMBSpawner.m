//
//  AMBSpawner.m
//  CharacterTests
//
//  Created by Alex Taylor on 2014-09-16.
//  Copyright (c) 2014 Alex Taylor. All rights reserved.
//

#import "SKTUtils.h"
#import "AMBSpawner.h"

@interface AMBSpawner ()

@property (nonatomic) BOOL spawningIsActive;
@property (nonatomic) NSTimeInterval lastSpawnTime;
@property (nonatomic) NSTimeInterval nextSpawnAt;

@end

@implementation AMBSpawner

- (instancetype) init {
    if (self = [super init]) {
        _spawningIsActive = NO;
        _frequencyUpperRange = 0; // set this to zero by default

        [self setNextSpawn];
    }
    
    return self;
}

- (void)updateWithTimeSinceLastUpdate:(CFTimeInterval)delta {
    CFTimeInterval currentTime = CACurrentMediaTime();
    NSTimeInterval spawnDelta = currentTime - self.spawnTime;
    
    if (!_spawningIsActive) {
        // start the spawning process
        if (spawnDelta >= _firstSpawnAt) { [self fireSpawnEvent]; }
        
        _spawningIsActive = YES;
        return;
    }
    
    if (spawnDelta >= _nextSpawnAt) {
        [self setNextSpawn];
        [self fireSpawnEvent];
    }
    
    
}

- (void)setNextSpawn {

    if (_frequencyUpperRange == 0) {
        _nextSpawnAt = RandomFloatRange(_frequency, _frequencyUpperRange);
    } else {
        _nextSpawnAt = _frequency;
    }
}

- (void)fireSpawnEvent {
    // overridden by subclasses.
#if DEBUG
    NSLog(@"<<<< firing spawn event >>>>");
#endif
}

@end
