//
//  AMBSpawner.h
//  CharacterTests
//
//  Created by Alex Taylor on 2014-09-16.
//  Copyright (c) 2014 Alex Taylor. All rights reserved.
//
/*
 
PatientSpawners will be what gets created from the spawn_patients objects on the map. The idea is that these will be set up to spawn patients of a certain type (or random), at a certain frequency. You could also set up spawners to spawn "specific" patients at a certain time, instead of at a frequency. That would allow level design that explicitly specifies which patients get spawned and where.

    "spawn every five seconds"
        - frequency
    "spawn every five to eight seconds"
    "spawn at 12 seconds"
        - firstSpawnAt (seconds relative to game start)
 
    - firstSpawnAt 0, frequency 10 = immediately begin spawning objects every 10 seconds
    - firstSpawnAt 15, frequency 0 = spawn object at 15 seconds, then never again
    - firstSpawnAt 0, frequency 5-8 = immediately begin spawning objects, repeat between 5 and 8 seconds

 
 */

#import "AMBCharacter.h"

@interface AMBSpawner : AMBCharacter

@property (nonatomic, readonly) NSTimeInterval firstSpawnAt;
@property (nonatomic, readonly) NSTimeInterval frequency;
@property (nonatomic, readonly) NSTimeInterval frequencyUpperRange; // for random frequencies; if 0, only 'frequency' is considered

- (instancetype)initWithFirstSpawnAt:(NSTimeInterval)firstSpawnAt withFrequency:(NSTimeInterval)frequency frequencyUpperRange:(NSTimeInterval)frequencyUpperRange;

- (void)updateWithTimeSinceLastUpdate:(CFTimeInterval)delta;

- (void)fireSpawnEvent;


@end
