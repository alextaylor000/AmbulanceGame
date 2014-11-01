//
//  XXXMyScene.m
//  CharacterTests
//
//  Created by Alex Taylor on 2014-07-06.
//  Copyright (c) 2014 Alex Taylor. All rights reserved.
//

#import "AMBLevelScene.h"
#import "AMBPlayer.h"
#import "AMBPatient.h"
#import "AMBHospital.h"
#import "AMBSpawner.h"
#import "AMBScoreKeeper.h"
#import "AMBCamera.h"
#import "JSTilemap.h"   // for supporting TMX maps
#import "SKTUtils.h"

#define kNumberCars   15

static const float KEY_PRESS_INTERVAL_SECS = 0.25; // ignore key presses more frequent than this interval
static const int TILE_LANE_WIDTH = 32;

@interface AMBLevelScene ()

@property NSTimeInterval lastUpdateTimeInterval;
@property NSTimeInterval lastKeyPress;
@property SKNode *worldNode;
@property JSTileMap *bgLayer;
@property AMBPlayer *player;
@property AMBSpawner *spawnerTest;
@property AMBCamera *camera;

@property TMXLayer *roadLayer;
@property TMXObjectGroup *spawnPoints;
@property CGPoint playerSpawnPoint;
@property NSInteger currentTileGid;

@property BOOL turnRequested;
@property CGFloat turnDegrees;

@property (nonatomic) NSMutableArray *spawners; // store an array of all the spawners in order to update them on every frame


@end

@implementation AMBLevelScene{
    
    NSMutableDictionary *roadTilePaths;
    
    NSMutableArray *_cars;
    AMBScoreKeeper *scoreKeeper;
    int _nextCar;
    double _nextCarSpawn;
    
}

-(id)initWithSize:(CGSize)size {    
    if (self = [super initWithSize:size]) {

        self.physicsWorld.contactDelegate = self;
        
        [self createWorld]; // set up tilemap
        [self addPlayer];

        _turnRequested = NO;
        
        // camera
        _camera = [[AMBCamera alloc] initWithTargetSprite:_player];
        _camera.zPosition = 999;
        [_worldNode addChild:_camera];
        
        // scoring
        scoreKeeper = [AMBScoreKeeper sharedInstance]; // create a singleton ScoreKeeper
        SKLabelNode *labelScore = [scoreKeeper createScoreLabelWithPoints:0 atPos:CGPointMake(self.size.width/2 - 250, self.size.height/2-50)];
        [self addChild:labelScore];
     
#if DEBUG
        NSLog(@"[[   SCORE:  %ld   ]]", scoreKeeper.score);
#endif
        
    }
    return self;
}


- (void) addPatientSeverity:(PatientSeverity)severity atPoint:(CGPoint)point {
    CGPoint patientPosition = point;
    AMBPatient *patient = [[AMBPatient alloc]initWithSeverity:severity position:patientPosition];
    [_tilemap addChild:patient];
}


- (void) addHospitalAtPoint:(CGPoint)point {
    SKSpriteNode *hospital = [SKSpriteNode spriteNodeWithImageNamed:@"hospital"];
    
    hospital.position = point;
    hospital.zPosition = 200;
    hospital.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:CGSizeMake(hospital.size.width * 3, hospital.size.height * 3)]; // for the physics body, expand the hospital's size so that it encompasses all the surrounding road blocks.
    hospital.physicsBody.categoryBitMask = categoryHospital;
    hospital.physicsBody.collisionBitMask = 0x00000000;
    
    [_tilemap addChild:hospital];
}

- (void) initalizeCarVariables{
    
    _nextCarSpawn = 0;
    
    for (SKSpriteNode *car in _cars) {
        car.hidden = YES;
    }
    
}

- (void) addCars{//Adds inital enamies to the screen
    
    _cars = [[NSMutableArray alloc] initWithCapacity:kNumberCars];//Init the mutable array
    for (int i = 0; i < kNumberCars; ++i) {//Fill m-array with X number of car sprites
        SKSpriteNode *car = [SKSpriteNode spriteNodeWithImageNamed:@"car"];//Create car node
        car.zPosition = 200;
        car.hidden = YES;//Hide it so we dont have to bother with it until it is active
        [car setXScale:0.5];//Dont really need
        [car setYScale:0.5];//Dont need
        [_cars addObject:car];//add the car to the m-array
        [self addChild:car];//Add the car to the sceen
    }
    
}

- (void) addPlayer {
    
    _player = [[AMBPlayer alloc] init];
    _player.position = CGPointMake(_playerSpawnPoint.x, _playerSpawnPoint.y); // TODO: don't hardcode this offset!

    [_tilemap addChild:_player];

#if DEBUG
    NSLog(@"adding player at %1.0f,%1.0f",_playerSpawnPoint.x,_playerSpawnPoint.y);
#endif

}


- (float)randomValueBetween:(float)low andValue:(float)high {//Used to return a random value between two points
    return (((float) arc4random() / 0xFFFFFFFFu) * (high - low)) + low;
}

-(void)calcDelta:(CFTimeInterval)currentTime {
    if (self.sceneLastUpdate) {
        self.sceneDelta = currentTime - self.sceneLastUpdate;
    } else {
        self.sceneDelta = 0;
    }
    
    self.sceneLastUpdate = currentTime;
}

-(void)update:(CFTimeInterval)currentTime {
    [self calcDelta:currentTime];
    
    [_player updateWithTimeSinceLastUpdate:_sceneDelta];


    [_camera updateWithTimeSinceLastUpdate:_sceneDelta];
    [self centerOnNode:_camera];
    
    
    _currentTileGid = [_mapLayerRoad tileGidAt:_player.position];

    
    // update the spawners
    // TODO: should this be part of the spawner class?
    [_spawners enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        AMBSpawner *spawnerObj = (AMBSpawner *)obj;
        [spawnerObj updateWithTimeSinceLastUpdate:_sceneDelta];
    }];

    // update all visible patients
    [_tilemap enumerateChildNodesWithName:@"patient" usingBlock:^(SKNode *node, BOOL *stop) {
        AMBPatient *patientNode = (AMBPatient *)node;
        [patientNode updatePatient];
    }];
    
    
    // turn if a turn was requested but hasn't been completed yet
    if (_turnRequested && self.sceneLastUpdate - _lastKeyPress < KEY_PRESS_INTERVAL_SECS ) {
#if DEBUG
        NSLog(@"update loop: turn requested");
#endif
        [self authorizeMoveEvent:_turnDegrees];
    }

}

#pragma mark World Building
- (void)createWorld {
    
    _worldNode = [SKNode node];
    _worldNode.name = @"worldNode";
    [self addChild:_worldNode];
    
    [self levelWithTilemap:@"level01.tmx"];

    if (_tilemap) { [_worldNode addChild:_tilemap]; }
    
    // Set up spawn points
    NSDictionary *playerSpawn = [[_mapGroupSpawnPlayer objects] objectAtIndex:0];
    _playerSpawnPoint = [self centerOfObject:playerSpawn];
    
    NSArray *hospitalSpawns = [_mapGroupSpawnHospitals objects];
    for (NSDictionary *object in hospitalSpawns) {
        AMBHospital *hospital = [[AMBHospital alloc] init];
        [hospital addObjectToNode:_mapLayerRoad atPosition:[self centerOfObject:object]];
    }
    
    [self createSpawners];
}

- (void)createSpawners {
    _spawners = [[NSMutableArray alloc]init];

    // patient spawners
    NSArray *patientSpawns = [_mapGroupSpawnPatients objects];
    for (NSDictionary *object in patientSpawns) {
        CGPoint spawnPoint = [self centerOfObject:object];
        
        // grab properties of the spawner from the TMX object directly
        NSTimeInterval firstSpawnAt = [[object valueForKey:@"firstSpawnAt"] intValue];
        NSTimeInterval frequency = [[object valueForKey:@"frequency"] intValue];
        NSTimeInterval frequencyUpperRange = [[object valueForKey:@"frequencyUpperValue"] intValue]; // defaults to 0

        // build an array of patients based on the severity property (can be comma-separated)
        NSArray *severityArray = [[object valueForKey:@"severity"] componentsSeparatedByString:@","];
        NSMutableArray *patientsForSpawner = [[NSMutableArray alloc]init];
        
        for (NSString *sev in severityArray) {
            int index = [sev intValue];
            [patientsForSpawner addObject:[AMBPatient patientWithSeverity:index]];

        }
        
        AMBSpawner *spawner = [[AMBSpawner alloc] initWithFirstSpawnAt:firstSpawnAt
                                                         withFrequency:frequency
                                                   frequencyUpperRange:frequencyUpperRange
                                                           withObjects:patientsForSpawner];
        
        [spawner addObjectToNode:_mapLayerRoad atPosition:spawnPoint];
        [_spawners addObject:spawner];
    }

}

- (void)levelWithTilemap:(NSString *)tilemapFile {
    _tilemap = [self tileMapFromFile:tilemapFile];
    
    if (_tilemap) {
        // set up the layers/groups
        _mapLayerRoad =     [_tilemap layerNamed:@"road"];
        _mapLayerScenery =  [_tilemap layerNamed:@"scenery"];
        
        _mapGroupSpawnPlayer =      [_tilemap groupNamed:@"spawn_player"];
        _mapGroupSpawnPatients =    [_tilemap groupNamed:@"spawn_patients"];
        _mapGroupSpawnHospitals =   [_tilemap groupNamed:@"spawn_hospitals"];
        _mapGroupSpawnTraffic =     [_tilemap groupNamed:@"spawn_traffic"];
        _mapGroupSpawnPowerups =    [_tilemap groupNamed:@"spawn_powerups"];
        

        [self createTileBoundingPaths];

    }
}

- (void)createTileBoundingPaths {
    // creates CGPaths for each road tile, so that we can check collision
    // this thing helps to rough it in: http://dazchong.com/spritekit/
    
    NSMutableDictionary *tileProperties =[_tilemap tileProperties];
    
    roadTilePaths = [[NSMutableDictionary alloc] init];
    
    for (id key in tileProperties) {
        // get the tile type (e.g. nsw, new, ne, etc)
        NSString *tileType = [tileProperties objectForKey:key][@"road"];

        if (!tileType) { continue; } // ignore tiles that do not have a road attribute (e.g. walls)
        
        CGMutablePathRef path = CGPathCreateMutable(); // create a path to store the bounds for the road surface
        
        NSInteger offsetX = 128; // anchor point of tile (0.5, 0.5)
        NSInteger offsetY = 128;
        
        /*
         REGARDING THE PATHS BELOW:
         
         I've been going back and forth on the width of these paths. If they go "full bleed"
         to the edge of the road, the possibility exists to allow the ambulance to drive
         half on the road, half on the wall. Originally, when I tried moving it in, it made
         it too hard to get the timing just right to make a turn, but I think I've alleviated
         that by continuing to request the turn in the update loop for a short while after keypress.
         
         For reference, the magic numbers for a "full bleed" road path are:
            0
            65
            185
            256
         
         I'm changing it to the numbers below which should prevent the ambulance from getting
         too close to the wall:
            0
            90
            166
            256
         */
        
        if (        [tileType isEqualToString:@"ew"]) {
            
            CGPathMoveToPoint(path, NULL, 0 - offsetX, 90 - offsetY);
            CGPathAddLineToPoint(path, NULL, 256 - offsetX, 90 - offsetY);
            CGPathAddLineToPoint(path, NULL, 256 - offsetX, 166 - offsetY);
            CGPathAddLineToPoint(path, NULL, 0 - offsetX, 166 - offsetY);
            
        } else if ( [tileType isEqualToString:@"nesw"]) {
            
            CGPathMoveToPoint(path, NULL, 90 - offsetX, 0 - offsetY);
            CGPathAddLineToPoint(path, NULL, 166 - offsetX, 0 - offsetY);
            CGPathAddLineToPoint(path, NULL, 166 - offsetX, 90 - offsetY);
            CGPathAddLineToPoint(path, NULL, 256 - offsetX, 90 - offsetY);
            CGPathAddLineToPoint(path, NULL, 256 - offsetX, 166 - offsetY);
            CGPathAddLineToPoint(path, NULL, 166 - offsetX, 166 - offsetY);
            CGPathAddLineToPoint(path, NULL, 166 - offsetX, 256 - offsetY);
            CGPathAddLineToPoint(path, NULL, 90 - offsetX, 256 - offsetY);
            CGPathAddLineToPoint(path, NULL, 90 - offsetX, 166 - offsetY);
            CGPathAddLineToPoint(path, NULL, 0 - offsetX, 166 - offsetY);
            CGPathAddLineToPoint(path, NULL, 0 - offsetX, 90 - offsetY);
            CGPathAddLineToPoint(path, NULL, 90 - offsetX, 90 - offsetY);
            
            
            
        } else if ( [tileType isEqualToString:@"ns"]) {
            
            CGPathMoveToPoint(path, NULL, 90 - offsetX, 0 - offsetY);
            CGPathAddLineToPoint(path, NULL, 166 - offsetX, 0 - offsetY);
            CGPathAddLineToPoint(path, NULL, 166 - offsetX, 256 - offsetY);
            CGPathAddLineToPoint(path, NULL, 90 - offsetX, 256 - offsetY);
            
        } else if ( [tileType isEqualToString:@"ne"]) {
            
            CGPathMoveToPoint(path, NULL, 90 - offsetX, 90 - offsetY);
            CGPathAddLineToPoint(path, NULL, 256 - offsetX, 90 - offsetY);
            CGPathAddLineToPoint(path, NULL, 256 - offsetX, 166 - offsetY);
            CGPathAddLineToPoint(path, NULL, 166 - offsetX, 166 - offsetY);
            CGPathAddLineToPoint(path, NULL, 166 - offsetX, 256 - offsetY);
            CGPathAddLineToPoint(path, NULL, 90 - offsetX, 256 - offsetY);
            
        } else if ( [tileType isEqualToString:@"nw"]) {
            
            CGPathMoveToPoint(path, NULL, 0 - offsetX, 90 - offsetY);
            CGPathAddLineToPoint(path, NULL, 166 - offsetX, 90 - offsetY);
            CGPathAddLineToPoint(path, NULL, 166 - offsetX, 256 - offsetY);
            CGPathAddLineToPoint(path, NULL, 90 - offsetX, 256 - offsetY);
            CGPathAddLineToPoint(path, NULL, 90 - offsetX, 166 - offsetY);
            CGPathAddLineToPoint(path, NULL, 0 - offsetX, 166 - offsetY);
            
        } else if ( [tileType isEqualToString:@"es"]) {
            
            CGPathMoveToPoint(path, NULL, 90 - offsetX, 0 - offsetY);
            CGPathAddLineToPoint(path, NULL, 166 - offsetX, 0 - offsetY);
            CGPathAddLineToPoint(path, NULL, 166 - offsetX, 90 - offsetY);
            CGPathAddLineToPoint(path, NULL, 256 - offsetX, 90 - offsetY);
            CGPathAddLineToPoint(path, NULL, 256 - offsetX, 166 - offsetY);
            CGPathAddLineToPoint(path, NULL, 90 - offsetX, 166 - offsetY);
            
        } else if ( [tileType isEqualToString:@"sw"]) {
            
            CGPathMoveToPoint(path, NULL, 90 - offsetX, 0 - offsetY);
            CGPathAddLineToPoint(path, NULL, 166 - offsetX, 0 - offsetY);
            CGPathAddLineToPoint(path, NULL, 166 - offsetX, 166 - offsetY);
            CGPathAddLineToPoint(path, NULL, 0 - offsetX, 166 - offsetY);
            CGPathAddLineToPoint(path, NULL, 0 - offsetX, 90 - offsetY);
            CGPathAddLineToPoint(path, NULL, 90 - offsetX, 90 - offsetY);
            
        } else if ( [tileType isEqualToString:@"nes"]) {
            
            CGPathMoveToPoint(path, NULL, 90 - offsetX, 0 - offsetY);
            CGPathAddLineToPoint(path, NULL, 166 - offsetX, 0 - offsetY);
            CGPathAddLineToPoint(path, NULL, 166 - offsetX, 90 - offsetY);
            CGPathAddLineToPoint(path, NULL, 256 - offsetX, 90 - offsetY);
            CGPathAddLineToPoint(path, NULL, 256 - offsetX, 166 - offsetY);
            CGPathAddLineToPoint(path, NULL, 166 - offsetX, 166 - offsetY);
            CGPathAddLineToPoint(path, NULL, 166 - offsetX, 256 - offsetY);
            CGPathAddLineToPoint(path, NULL, 90 - offsetX, 256 - offsetY);
            
        } else if ( [tileType isEqualToString:@"new"]) {
            
            CGPathMoveToPoint(path, NULL, 0 - offsetX, 90 - offsetY);
            CGPathAddLineToPoint(path, NULL, 256 - offsetX, 90 - offsetY);
            CGPathAddLineToPoint(path, NULL, 166 - offsetX, 90 - offsetY);
            CGPathAddLineToPoint(path, NULL, 166 - offsetX, 166 - offsetY);
            CGPathAddLineToPoint(path, NULL, 166 - offsetX, 256 - offsetY);
            CGPathAddLineToPoint(path, NULL, 90 - offsetX, 256 - offsetY);
            CGPathAddLineToPoint(path, NULL, 90 - offsetX, 166 - offsetY);
            CGPathAddLineToPoint(path, NULL, 0 - offsetX, 166 - offsetY);
            
        } else if ( [tileType isEqualToString:@"nsw"]) {
            
            CGPathMoveToPoint(path, NULL, 0 - offsetX, 90 - offsetY);
            CGPathAddLineToPoint(path, NULL, 90 - offsetX, 90 - offsetY);
            CGPathAddLineToPoint(path, NULL, 90 - offsetX, 0 - offsetY);
            CGPathAddLineToPoint(path, NULL, 166 - offsetX, 0 - offsetY);
            CGPathAddLineToPoint(path, NULL, 166 - offsetX, 256 - offsetY);
            CGPathAddLineToPoint(path, NULL, 90 - offsetX, 256 - offsetY);
            CGPathAddLineToPoint(path, NULL, 90 - offsetX, 166 - offsetY);
            CGPathAddLineToPoint(path, NULL, 0 - offsetX, 166 - offsetY);
            
        } else if ( [tileType isEqualToString:@"esw"]) {
            
            CGPathMoveToPoint(path, NULL, 0 - offsetX, 90 - offsetY);
            CGPathAddLineToPoint(path, NULL, 90 - offsetX, 90 - offsetY);
            CGPathAddLineToPoint(path, NULL, 90 - offsetX, 0 - offsetY);
            CGPathAddLineToPoint(path, NULL, 166 - offsetX, 0 - offsetY);
            CGPathAddLineToPoint(path, NULL, 166 - offsetX, 90 - offsetY);
            CGPathAddLineToPoint(path, NULL, 256 - offsetX, 90 - offsetY);
            CGPathAddLineToPoint(path, NULL, 256 - offsetX, 166 - offsetY);
            CGPathAddLineToPoint(path, NULL, 0 - offsetX, 166 - offsetY);
            
        } else if ( [tileType isEqualToString:@"b_ns_l"]) {
            CGPathMoveToPoint(path, NULL, 90 - offsetX, 0 - offsetY);
            CGPathAddLineToPoint(path, NULL, 256 - offsetX, 0 - offsetY);
            CGPathAddLineToPoint(path, NULL, 256 - offsetX, 256 - offsetY);
            CGPathAddLineToPoint(path, NULL, 90 - offsetX, 256 - offsetY);
            
        } else if ( [tileType isEqualToString:@"b_ns_r"]) {
            CGPathMoveToPoint(path, NULL, 0 - offsetX, 0 - offsetY);
            CGPathAddLineToPoint(path, NULL, 166 - offsetX, 0 - offsetY);
            CGPathAddLineToPoint(path, NULL, 166 - offsetX, 256 - offsetY);
            CGPathAddLineToPoint(path, NULL, 0 - offsetX, 256 - offsetY);
            
        } else if ( [tileType isEqualToString:@"b_nsw"]) {
            CGPathMoveToPoint(path, NULL, 0 - offsetX, 90 - offsetY);
            CGPathAddLineToPoint(path, NULL, 90 - offsetX, 90 - offsetY);
            CGPathAddLineToPoint(path, NULL, 90 - offsetX, 0 - offsetY);
            CGPathAddLineToPoint(path, NULL, 256 - offsetX, 0 - offsetY);
            CGPathAddLineToPoint(path, NULL, 256 - offsetX, 256 - offsetY);
            CGPathAddLineToPoint(path, NULL, 90 - offsetX, 256 - offsetY);
            CGPathAddLineToPoint(path, NULL, 90 - offsetX, 166 - offsetY);
            CGPathAddLineToPoint(path, NULL, 0 - offsetX, 166 - offsetY);

        } else if ( [tileType isEqualToString:@"b_nes"]) {
            CGPathMoveToPoint(path, NULL, 0 - offsetX, 0 - offsetY);
            CGPathAddLineToPoint(path, NULL, 166 - offsetX, 0 - offsetY);
            CGPathAddLineToPoint(path, NULL, 166 - offsetX, 90 - offsetY);
            CGPathAddLineToPoint(path, NULL, 256 - offsetX, 90 - offsetY);
            CGPathAddLineToPoint(path, NULL, 256 - offsetX, 166 - offsetY);
            CGPathAddLineToPoint(path, NULL, 166 - offsetX, 166 - offsetY);
            CGPathAddLineToPoint(path, NULL, 166 - offsetX, 256 - offsetY);
            CGPathAddLineToPoint(path, NULL, 0 - offsetX, 256 - offsetY);
            
        } else if ( [tileType isEqualToString:@"b_ew_t"]) {
            CGPathMoveToPoint(path, NULL, 0 - offsetX, 0 - offsetY);
            CGPathAddLineToPoint(path, NULL, 256 - offsetX, 0 - offsetY);
            CGPathAddLineToPoint(path, NULL, 256 - offsetX, 166 - offsetY);
            CGPathAddLineToPoint(path, NULL, 0 - offsetX, 166 - offsetY);
            
        } else if ( [tileType isEqualToString:@"b_new"]) {
            CGPathMoveToPoint(path, NULL, 0 - offsetX, 0 - offsetY);
            CGPathAddLineToPoint(path, NULL, 256 - offsetX, 0 - offsetY);
            CGPathAddLineToPoint(path, NULL, 256 - offsetX, 166 - offsetY);
            CGPathAddLineToPoint(path, NULL, 166 - offsetX, 166 - offsetY);
            CGPathAddLineToPoint(path, NULL, 166 - offsetX, 256 - offsetY);
            CGPathAddLineToPoint(path, NULL, 90 - offsetX, 256 - offsetY);
            CGPathAddLineToPoint(path, NULL, 90 - offsetX, 166 - offsetY);
            CGPathAddLineToPoint(path, NULL, 0 - offsetX, 166 - offsetY);
            
        } else if ( [tileType isEqualToString:@"bb_new_l"]) {
            CGPathMoveToPoint(path, NULL, 0 - offsetX, 0 - offsetY);
            CGPathAddLineToPoint(path, NULL, 256 - offsetX, 0 - offsetY);
            CGPathAddLineToPoint(path, NULL, 256 - offsetX, 256 - offsetY);
            CGPathAddLineToPoint(path, NULL, 90 - offsetX, 256 - offsetY);
            CGPathAddLineToPoint(path, NULL, 90 - offsetX, 166 - offsetY);
            CGPathAddLineToPoint(path, NULL, 0 - offsetX, 166 - offsetY);
        } else if ( [tileType isEqualToString:@"bb_new_r"]) {
            CGPathMoveToPoint(path, NULL, 0 - offsetX, 0 - offsetY);
            CGPathAddLineToPoint(path, NULL, 256 - offsetX, 0 - offsetY);
            CGPathAddLineToPoint(path, NULL, 256 - offsetX, 166 - offsetY);
            CGPathAddLineToPoint(path, NULL, 166 - offsetX, 166 - offsetY);
            CGPathAddLineToPoint(path, NULL, 166 - offsetX, 256 - offsetY);
            CGPathAddLineToPoint(path, NULL, 0 - offsetX, 256 - offsetY);
        } else if ( [tileType isEqualToString:@"bb_esw_l"]) {
            CGPathMoveToPoint(path, NULL, 90 - offsetX, 0 - offsetY);
            CGPathAddLineToPoint(path, NULL, 256 - offsetX, 0 - offsetY);
            CGPathAddLineToPoint(path, NULL, 256 - offsetX, 256 - offsetY);
            CGPathAddLineToPoint(path, NULL, 0 - offsetX, 256 - offsetY);
            CGPathAddLineToPoint(path, NULL, 0 - offsetX, 90 - offsetY);
            CGPathAddLineToPoint(path, NULL, 90 - offsetX, 90 - offsetY);
        } else if ( [tileType isEqualToString:@"bb_esw_r"]) {
            CGPathMoveToPoint(path, NULL, 0 - offsetX, 0 - offsetY);
            CGPathAddLineToPoint(path, NULL, 166 - offsetX, 0 - offsetY);
            CGPathAddLineToPoint(path, NULL, 166 - offsetX, 90 - offsetY);
            CGPathAddLineToPoint(path, NULL, 256 - offsetX, 90 - offsetY);
            CGPathAddLineToPoint(path, NULL, 256 - offsetX, 256 - offsetY);
            CGPathAddLineToPoint(path, NULL, 0 - offsetX, 256 - offsetY);
        } else if ( [tileType isEqualToString:@"b_ew_b"]) {
            CGPathMoveToPoint(path, NULL, 0 - offsetX, 90 - offsetY);
            CGPathAddLineToPoint(path, NULL, 256 - offsetX, 90 - offsetY);
            CGPathAddLineToPoint(path, NULL, 256 - offsetX, 256 - offsetY);
            CGPathAddLineToPoint(path, NULL, 0 - offsetX, 256 - offsetY);
        } else if ( [tileType isEqualToString:@"b_esw"]) {
            CGPathMoveToPoint(path, NULL, 0 - offsetX, 90 - offsetY);
            CGPathAddLineToPoint(path, NULL, 90 - offsetX, 90 - offsetY);
            CGPathAddLineToPoint(path, NULL, 90 - offsetX, 0 - offsetY);
            CGPathAddLineToPoint(path, NULL, 166 - offsetX, 0 - offsetY);
            CGPathAddLineToPoint(path, NULL, 166 - offsetX, 90 - offsetY);
            CGPathAddLineToPoint(path, NULL, 256 - offsetX, 90 - offsetY);
            CGPathAddLineToPoint(path, NULL, 256 - offsetX, 256 - offsetY);
            CGPathAddLineToPoint(path, NULL, 0 - offsetX, 256 - offsetY);
        } else {
            // if the tile is not one of these types, return
            return;
        }
        
        
        CGPathCloseSubpath(path); // close the path
        
        [roadTilePaths setObject:(__bridge id)path forKey:tileType]; // TODO: memory leak because of bridging?
        
    } // end for
}


/** Calculates the center point of a TMXObjectGroup object based on its x/y offset and size. */
- (CGPoint)centerOfObject:(NSDictionary *)object {
    return CGPointMake([[object objectForKey:@"x"] intValue] + [[object objectForKey:@"width"] intValue]/2,
                       [[object objectForKey:@"y"] intValue] + [[object objectForKey:@"height"] intValue]/2);
}


#pragma mark Camera

- (void) centerOnNode: (SKNode *) node
{
    CGPoint cameraPositionInScene = [node.scene convertPoint:node.position fromNode:node.parent];
    node.parent.position = CGPointMake(node.parent.position.x - cameraPositionInScene.x,
                                       node.parent.position.y - cameraPositionInScene.y);
    
    
}



#pragma mark Game logic
- (void)didBeginContact:(SKPhysicsContact *)contact {
    /* This method is basically handling all the game logic right now */

    SKPhysicsBody *other =
    (contact.bodyA.categoryBitMask == categoryPlayer ?
     contact.bodyB : contact.bodyA);
    
    
    if (other.categoryBitMask == categoryPatient) {
        AMBPatient *patientNode = (AMBPatient *)other.node;
        [_player loadPatient:patientNode];


    } else if (other.categoryBitMask == categoryHospital) {
        if (_player.patient) {
            [scoreKeeper scoreEventDeliveredPatient:_player.patient];
            [_player unloadPatient];
        }
        
#if DEBUG
//        NSLog(@"at hospital");
#endif
    }
    
    
}


- (void)authorizeMoveEvent: (CGFloat)degrees {
    /* Called by user input. Initiates a turn or a lane change if the move is legal.
    
     The layout of this function is as follows:
     
     Is the tile an intersection?
            Define the target point (slightly different for single lane vs. multi lane)
     
            Does the target point land on a road?
                *TURN!*
                return;
     
     Define the target point for a lane change
            Does the target point land on a road?
                *CHANGE LANES!*
     
     */
    
    SKSpriteNode *currentTile = [_mapLayerRoad tileAt:_player.position];
    NSDictionary *currentTileProperties = [_tilemap propertiesForGid:[_mapLayerRoad tileGidAt:_player.position]];
    CGPoint playerPosInTile = [currentTile convertPoint:_player.position fromNode:_tilemap];
    
    BOOL isWithinBounds;
    BOOL currentTileIsMultiLane;
    if([[currentTileProperties[@"road"] substringToIndex:1] isEqualToString:@"b"]) { currentTileIsMultiLane = YES; } else { currentTileIsMultiLane = NO; }
    
    CGPoint targetPoint; // the result of this tile calculation below
    CGVector targetOffset; // how much we need to move over to get into the next lane

    if (currentTileProperties[@"intersection"]) {
        CGPoint directionNormalized = CGPointNormalize(_player.direction);
        CGPoint rotatedPointNormalized = CGPointRotate(directionNormalized, degrees);
        CGPoint rotatedPoint;
        
        // is it single-lane?
        if (currentTileIsMultiLane) {
            rotatedPoint = CGPointMultiplyScalar(rotatedPointNormalized, _tilemap.tileSize.width*2); // target tile is 2 over
        } else {
            rotatedPoint = CGPointMultiplyScalar(rotatedPointNormalized, _tilemap.tileSize.width); // target tile is 1 over
        }
 
        targetPoint = CGPointAdd(rotatedPoint, _player.position);
        isWithinBounds = [self isTargetPointValid:targetPoint];
        
        if (isWithinBounds) {
            [_player rotateByAngle:degrees];
            _turnRequested = NO;
            return;
        }

    } // if currentTileProperties = intersection

    // fall through to a lane change if the whole turning thing didn't work out

    CGPoint laneChangeVector = CGPointRotate(_player.direction, degrees);
    CGFloat angle = RadiansToDegrees(CGPointToAngle(laneChangeVector)); // result: 90, 0, etc
    
    NSInteger remainder;
    CGFloat pos;  // the player's position in the tile, either the x or the y value
    CGFloat posNormalized ; // the player's position, normalized to the lane width
    NSInteger targetLaneNormalized;
    NSInteger direction; // the lane change vector, should either be 1 or -1

    // the lane change calculation is easiest in one dimension, so we want to extract the relevant details and forget about points until the end
    if (fabsf(laneChangeVector.x) > fabsf(laneChangeVector.y)) {
        pos     = playerPosInTile.x + (_tilemap.tileSize.width/2); // add half the width of the tile to make the coords corner-anchored.
    } else {
        pos     = playerPosInTile.y + (_tilemap.tileSize.width/2);
    }
    

    // TODO: accept a range around the lane (e.g. if the lane is at 96, 94-98 should be considered the range)
    
    if (angle > -1 ) { // positive change
        posNormalized = floorl( round(pos)/TILE_LANE_WIDTH);
        direction = 1;
    } else { // negative change
        posNormalized = ceilf( round(pos)/TILE_LANE_WIDTH);
        direction = -1;
    }
    
    if ( (int)posNormalized % 2 == 0) { // the player is right on a lane
        targetLaneNormalized = posNormalized + direction;
        
    } else { // the player is somewhere between lanes
        remainder = (int)posNormalized % 2;
        targetLaneNormalized = posNormalized + direction + (remainder * direction);
    }
    
    // convert the result back into a point
    if (fabsf(laneChangeVector.x) > fabsf(laneChangeVector.y)) {
        targetOffset = CGVectorMake((targetLaneNormalized * TILE_LANE_WIDTH) - pos , 0);
        
    } else {
        targetOffset = CGVectorMake(0, (targetLaneNormalized * TILE_LANE_WIDTH) - pos);        }
    
    targetPoint = CGPointAdd(playerPosInTile, CGPointMake(targetOffset.dx, targetOffset.dy));
#if DEBUG
    NSLog(@"LANE CHANGE: (%1.8f,%1.8f)[%ld] -> (%1.8f,%1.8f)[%ld]",playerPosInTile.x, playerPosInTile.y, (long)posNormalized, targetPoint.x, targetPoint.y, (long)targetLaneNormalized); // current position (lane) -> new position (lane)
#endif
    
    targetPoint = [_tilemap convertPoint:targetPoint fromNode:currentTile]; // convert target point back to real world coords

    isWithinBounds = [self isTargetPointValid:targetPoint];
    
    if (isWithinBounds) {
        SKAction *changeLanes = [SKAction moveBy:targetOffset duration:0.2];
        changeLanes.timingMode = SKActionTimingEaseInEaseOut;
        [_player runAction:changeLanes];
        _turnRequested = NO;
        return;
    }
    
    // as a final fall-through, stash the turn request if it wasn't able to be completed.
    // the update loop will keep requesting the turn for a while after the keypress, in order
    // to reduce the precise timing required to turn on to other roads.
    _turnRequested = YES;
    _turnDegrees = degrees;
    
}


- (BOOL)isTargetPointValid: (CGPoint)targetPoint {
    BOOL pointIsValid = NO;
    
    // with the target point, get the target tile and determine a) if it's a road tile, and b) if the point within the road tile is a road surface (and not the border)
    SKSpriteNode *targetTile = [_mapLayerRoad tileAt:targetPoint]; // gets the the tile object being considered for the turn
    
    NSString *targetTileRoadType = [_tilemap propertiesForGid:  [_mapLayerRoad tileGidAt:targetPoint]  ][@"road"];
    CGPoint positionInTargetTile = [targetTile convertPoint:targetPoint fromNode:_tilemap]; // the position of the target within the target tile
    
#if DEBUG
    SKSpriteNode *targetPointSprite = [SKSpriteNode spriteNodeWithColor:[SKColor yellowColor] size:CGSizeMake(10, 10)];
    targetPointSprite.name = @"DEBUG_targetPointSprite";
    targetPointSprite.position = positionInTargetTile;
    targetPointSprite.zPosition = targetTile.zPosition + 1;
    [targetTile addChild:targetPointSprite];
    [targetPointSprite runAction:[SKAction sequence:@[[SKAction waitForDuration:3],[SKAction removeFromParent]]]];
#endif
    
    if (targetTileRoadType) {
        // check the coordinates to make sure it's on ROAD SURFACE within the tile
        
        CGPathRef path = (__bridge CGPathRef)([roadTilePaths objectForKey:targetTileRoadType]); // TODO: memory leak because of bridging?
        
        pointIsValid = CGPathContainsPoint(path, NULL, positionInTargetTile, FALSE);
        
#if DEBUG
        if (pointIsValid) {
            targetPointSprite.color = [SKColor greenColor];
        }
        
        SKShapeNode *bounds = [SKShapeNode node];
        bounds.path = path;
        bounds.fillColor = [SKColor whiteColor];
        bounds.alpha = 0.5;
        bounds.zPosition = targetPointSprite.zPosition - 1;
        
        [targetTile addChild:bounds];
        [bounds runAction:[SKAction sequence:@[[SKAction waitForDuration:1],[SKAction removeFromParent]]]];
#endif
        
        
        return CGPathContainsPoint(path, NULL, positionInTargetTile, FALSE);
    }
    
    return pointIsValid;
}

- (CGFloat)calculatePlayerWidth {
    // calculates the player's width based on the current direction of travel.
    if (_player.direction.x == 1) {
        return _player.size.width;
    } else {
        return _player.size.height;
    }
}

#pragma mark Controls
- (void)handleKeyboardEvent: (NSEvent *)theEvent keyDown:(BOOL)downOrUp {
    
    if (self.sceneLastUpdate - _lastKeyPress < KEY_PRESS_INTERVAL_SECS ) return;
    
    if ([theEvent modifierFlags] & NSNumericPadKeyMask) { // arrow keys
        _lastKeyPress = self.sceneLastUpdate;
        
        NSString *theArrow = [theEvent charactersIgnoringModifiers];
        unichar keyChar = 0;

        
        if ([theArrow length] == 1) {
            keyChar = [theArrow characterAtIndex:0];
            
            switch (keyChar) {
                case NSUpArrowFunctionKey:
                    [_player startMoving];
                    break;
                    
                case NSLeftArrowFunctionKey:
                    [self authorizeMoveEvent:90];
                    
                    break;
                    
                case NSRightArrowFunctionKey:
                    [self authorizeMoveEvent:-90];
                    
                    break;
                    
                case NSDownArrowFunctionKey:
                    [_player stopMoving];
                    break;
                
                    
            }
        }
        
    }
    
    
}

- (void)keyDown:(NSEvent *)theEvent {
    [self handleKeyboardEvent:theEvent keyDown:YES];
}

- (void)keyUp:(NSEvent *)theEvent {
    [self handleKeyboardEvent:theEvent keyDown:NO];
}

@end
