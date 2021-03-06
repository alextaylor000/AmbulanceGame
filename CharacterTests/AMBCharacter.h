//
//  AMBCharacter.h
//  CharacterTests
//
//  Created by Alex Taylor on 2014-09-14.
//  Copyright (c) 2014 Alex Taylor. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>
#import "AMBLevelScene.h"

// Collision Bitmasks
static const uint32_t categoryPlayer =                  0x1 << 0;
static const uint32_t categoryPatient =                 0x1 << 1;
static const uint32_t categoryHospital =                0x1 << 2;
static const uint32_t categoryTraffic =                 0x1 << 3; // the real body of the traffic vehicle
static const uint32_t categoryTrafficCollisionZone =    0x1 << 4; // the tailgate zone which the AI uses to determine if it should slow down
static const uint32_t categoryTrafficStoppingZone =     0x1 << 5; // the stopping zone which the AI uses to determine if it should stop
static const uint32_t categoryPowerup =                 0x1 << 6; // powerups (fuel etc)

@interface AMBCharacter : SKSpriteNode

@property NSTimeInterval spawnTime;
@property AMBLevelScene *levelScene;
@property SKSpriteNode *minimapAvatar; // minimap version of sprite

/** Adds the character object to the scene, or other specified node. */
- (void)addObjectToNode:(SKNode *)node atPosition:(CGPoint)position;
+ (void)loadSharedAssets;

/** Returns the scene that the character is a part of. */
- (AMBLevelScene *)characterScene;

- (void)collidedWith:(SKPhysicsBody *)other victimNodeName:(NSString *)name;
- (void)endedContactWith:(SKPhysicsBody *)other victimNodeName:(NSString *)name;



@end
