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
@property AMBCharacter *spawnedObject; // the spawner keeps track of the object it spawned; if the object no longer has a parent, then this gets set to nil and the spawner is allowed to spawn a new object

@end

@implementation AMBSpawner


-(instancetype)initWithFirstSpawnAt:(NSTimeInterval)firstSpawnAt withFrequency:(NSTimeInterval)frequency frequencyUpperRange:(NSTimeInterval)frequencyUpperRange withObjects:(NSArray *)objects {
    

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
    if (!_spawnedObject.parent) {
        _spawnedObject = nil; // if the spawned object has been picked up, this spawner can create a new one
        
        _lastSpawnTime = CACurrentMediaTime();
        
        NSUInteger i = 0;
        AMBCharacter *objectToSpawn;
        
        
        if (_spawnObjectsCount > 1) {
            i = RandomFloatRange(0, _spawnObjectsCount - 1);
        }
        
        objectToSpawn = (AMBCharacter *)[[_spawnObjects objectAtIndex:i] copy]; // this becomes an immutable copy
        
        AMBLevelScene *__weak owningScene = [self characterScene]; // declare a reference to the scene as weak, to prevent a reference cycle. Inspired by animationDidComplete in Adventure.
        
        objectToSpawn.zRotation = [owningScene.mapLayerInteractives.userData[@"childRotation"] floatValue]; // sync up the rotation of this new sprite with the rest of the existing sprites
        [objectToSpawn addObjectToNode:[owningScene mapLayerInteractives] atPosition:self.position];
        _spawnedObject = objectToSpawn;
        
        // FUEL SPAWN
        if ([objectToSpawn isKindOfClass:[AMBPowerup class]]) {
            SKAction *fuelExpiry = [SKAction sequence:@[[SKAction waitForDuration:FUEL_EXPIRY_DURATION],[SKAction removeFromParent]]];
            [objectToSpawn runAction:fuelExpiry]; // fuel expires! BAM
        }
        
        // PATIENT SPAWN
        if ([objectToSpawn isKindOfClass:[AMBPatient class]]) {
            // add indicator
//            [owningScene.indicator addTarget:objectToSpawn type:IndicatorPatient];
            
            // add to minimap
            SKSpriteNode *miniPatient = [owningScene addObjectToMinimapAtPoint:objectToSpawn.position withColour:[SKColor whiteColor] withSize:1.25];
            SKAction *fadeOut = [SKAction fadeOutWithDuration:0.25];
            [miniPatient runAction:[SKAction repeatActionForever:[SKAction sequence:@[fadeOut, [fadeOut reversedAction]]]]];
            
            AMBPatient *patient = (AMBPatient *)objectToSpawn;
            patient.patientTimer = [[AMBTimer alloc]initWithSecondsRemaining: [patient.userData[@"timeToLive"] doubleValue] ];
            
            CGFloat distanceFromHospital = CGPointLength( CGPointSubtract(self.position, owningScene.hospitalLocation) );
            [patient.userData setObject:[NSNumber numberWithFloat:distanceFromHospital] forKey:@"distanceFromHospital"];
            
            patient.minimapAvatar = miniPatient;
            
            
            [patient changeState:PatientIsWaitingForPickup];
        }
    } // if !_spawnedObject.parent

}

@end
