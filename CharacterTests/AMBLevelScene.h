//
//  XXXMyScene.h
//  CharacterTests
//

//  Copyright (c) 2014 Alex Taylor. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>
#import "JSTileMap.h"
#import "AMBGameScene.h"

@interface AMBLevelScene : AMBGameScene <SKPhysicsContactDelegate>


#pragma Properties - Map
@property (readonly, nonatomic) JSTileMap *tilemap; // the tilemap for this level
@property (readonly, nonatomic) TMXLayer *mapLayerRoad; // road layer and characters
@property (readonly, nonatomic) TMXLayer *mapLayerScenery; // for buildings, grass, etc.

// spawn point(s) will be kept on separate layers so we can choose them at random
// in the spawn methods
@property (readonly, nonatomic) TMXObjectGroup *mapGroupSpawnPlayer;
@property (readonly, nonatomic) TMXObjectGroup *mapGroupSpawnPatients;
@property (readonly, nonatomic) TMXObjectGroup *mapGroupSpawnHospitals;
@property (readonly, nonatomic) TMXObjectGroup *mapGroupSpawnTraffic;
@property (readonly, nonatomic) TMXObjectGroup *mapGroupSpawnPowerups;


#pragma mark Update Loop
@property NSTimeInterval sceneLastUpdate;
@property CGFloat sceneDelta;


#pragma mark Methods
/** Loads a tilemap from disk and sets up all the layers.*/
- (void)levelWithTilemap:(NSString *)tilemapFile;

/** Adds a character sprite to the mapLayerRoad layer at the specified position within the layer's coordinate space. */
- (void)addCharacter:(SKNode *)character atPosition:(CGPoint)pos;






@end
