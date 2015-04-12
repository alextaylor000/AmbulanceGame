//
//  AMBCharacter.h
//  CharacterTests
//
//  Created by Alex Taylor on 2014-09-14.
//  Copyright (c) 2014 Alex Taylor. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>
#import "AMBLevelScene.h"
#import "AMBConstants.h"


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
