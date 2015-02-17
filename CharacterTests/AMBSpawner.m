//
//  AMBSpawner.m
//  CharacterTests
//
//  Created by Alex Taylor on 2014-09-16.
//  Copyright (c) 2014 Alex Taylor. All rights reserved.
//

#import "SKTUtils.h"
#import "AMBSpawner.h"
#import "AMBPatient.h"
#import "AMBPowerup.h"
#import "AMBLevelScene.h"

@interface AMBSpawner ()

@property (nonatomic) BOOL spawningIsActive;
@property (nonatomic) NSTimeInterval lastSpawnTime;
@property (nonatomic) NSTimeInterval nextSpawnAt;

@property (nonatomic) NSArray *spawnObjects;
@property (nonatomic) NSInteger spawnObjectsCount;


@end

@implementation AMBSpawner


-(instancetype)initWithFirstSpawnAt:(NSTimeInterval)firstSpawnAt withFrequency:(NSTimeInterval)frequency frequencyUpperRange:(NSTimeInterval)frequencyUpperRange withObjects:(NSArray *)objects {
    
    // TODO: allow frequency to be 0, which means only one object will ever be spawned
    // TODO: add checks to ensure that frequencyUpperRange is actually > frequency

    if (self = [super init]) {
        _spawningIsActive = NO;
        
        _lastSpawnTime = self.spawnTime;
        _firstSpawnAt = firstSpawnAt;
        _frequency = frequency;
        _frequencyUpperRange = frequencyUpperRange;
        
        _spawnObjects = objects;
        _spawnObjectsCount = [_spawnObjects count];
        
        if (_frequency <= 0) {
            _frequency = INFINITY; // protect against missing properties in TMX file; otherwise an object will spawn every frame!
        }
        
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
    
    NSUInteger i = 0;
    AMBCharacter *objectToSpawn;
    
    
    if (_spawnObjectsCount > 1) {
        i = RandomFloatRange(0, _spawnObjectsCount - 1);
    }
    
    objectToSpawn = (AMBCharacter *)[[_spawnObjects objectAtIndex:i] copy]; // this becomes an immutable copy
    
    AMBLevelScene *__weak owningScene = [self characterScene]; // declare a reference to the scene as weak, to prevent a reference cycle. Inspired by animationDidComplete in Adventure.
    
    [objectToSpawn addObjectToNode:[owningScene mapLayerRoad] atPosition:self.position];

    // FUEL SPAWN
    if ([objectToSpawn isKindOfClass:[AMBPowerup class]]) {
        SKSpriteNode *miniFuel = [owningScene addObjectToMinimapAtPoint:objectToSpawn.position withColour:[SKColor yellowColor] withSize:1];
        objectToSpawn.minimapAvatar = miniFuel;
        
        SKAction *fuelExpiry = [SKAction sequence:@[[SKAction waitForDuration:FUEL_EXPIRY_DURATION],[SKAction removeFromParent]]];
        [objectToSpawn runAction:fuelExpiry]; // fuel expires! BAM
        [objectToSpawn.minimapAvatar runAction:fuelExpiry];
    }
    
    // PATIENT SPAWN
    if ([objectToSpawn isKindOfClass:[AMBPatient class]]) {
#if DEBUG_PATIENT
        
        NSLog(@"[patient] Spawning patient '%@'...", objectToSpawn.name);
#endif
        
        [owningScene.indicator addTarget:objectToSpawn type:IndicatorPatient];
            
        // add to minimap
        SKSpriteNode *miniPatient = [owningScene addObjectToMinimapAtPoint:objectToSpawn.position withColour:[SKColor whiteColor] withSize:1.25];
        SKAction *fadeOut = [SKAction fadeOutWithDuration:0.25];
        [miniPatient runAction:[SKAction repeatActionForever:[SKAction sequence:@[fadeOut, [fadeOut reversedAction]]]]];

        AMBPatient *patient = (AMBPatient *)objectToSpawn;
        patient.minimapAvatar = miniPatient;
        
        [patient changeState:PatientIsWaitingForPickup];
#if DEBUG_INDICATOR
        NSLog(@"Adding indicator for target");
#endif
    }
    

}

@end
