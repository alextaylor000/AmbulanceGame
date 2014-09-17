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


-(instancetype)initWithFirstSpawnAt:(NSTimeInterval)firstSpawnAt withFrequency:(NSTimeInterval)frequency frequencyUpperRange:(NSTimeInterval)frequencyUpperRange {
    
    // TODO: add checks to ensure that frequencyUpperRange is actually > frequency

    if (self = [super init]) {
        _spawningIsActive = NO;
        
        _lastSpawnTime = self.spawnTime;
        _firstSpawnAt = firstSpawnAt;
        _frequency = frequency;
        _frequencyUpperRange = frequencyUpperRange;
        
        [self setNextSpawn];
    }
    
    return self;
}

- (void)updateWithTimeSinceLastUpdate:(CFTimeInterval)delta {
    CFTimeInterval currentTime = CACurrentMediaTime();
    NSTimeInterval spawnDelta = currentTime - _lastSpawnTime;
    
    if (!_spawningIsActive) {
        if (spawnDelta >= _firstSpawnAt) {
            _spawningIsActive = YES;
            [self fireSpawnEvent];
        }
        
        return;
    }
    
    if (spawnDelta >= _nextSpawnAt) {
        [self setNextSpawn];
        [self fireSpawnEvent];
    }
    
    
}

- (void)setNextSpawn {

    if (_frequencyUpperRange == 0) {
        _nextSpawnAt = _frequency;
    } else {
        _nextSpawnAt = RandomFloatRange(_frequency, _frequencyUpperRange);
    }
}

- (void)fireSpawnEvent {
    _lastSpawnTime = CACurrentMediaTime();
    
    // special behaviour implemented by subclasses.
#if DEBUG
    NSLog(@"<<<< firing spawn event >>>>");
#endif
}

@end
