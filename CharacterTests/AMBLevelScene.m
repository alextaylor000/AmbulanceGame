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
#import "AMBPowerup.h"
#import "AMBTrafficVehicle.h"
#import "JSTilemap.h"   // for supporting TMX maps
#import "SKTUtils.h"

#define kNumberCars   15

static const float KEY_PRESS_INTERVAL_SECS = 0.2; // ignore key presses more frequent than this interval
//static NSString * const LEVEL_NAME = @"level01_firstdraft.tmx";
static NSString * const LEVEL_NAME = @"level01_firstdraft.tmx";
static const BOOL renderTraffic = 1;

typedef enum {
    GestureIdle,
    GestureBegan,

    GestureLeftDown,
    GestureLeftUp,

    GestureRightDown,
    GestureRightUp
} PanGestureState;

@interface AMBLevelScene ()

@property NSTimeInterval lastUpdateTimeInterval;

@property SKNode *worldNode;
@property JSTileMap *bgLayer;
@property AMBPlayer *player;
@property AMBSpawner *spawnerTest;


@property SKSpriteNode *miniMapContainer; // the sprite node that holds the minimap, so we can rotate it easily
@property SKSpriteNode *miniPlayer; // for the minimap
@property SKSpriteNode *miniHospital;


@property NSMutableArray *trafficVehicles; // for enumerating the traffic objects during update loop


#if TARGET_OS_IPHONE
@property SKSpriteNode *controlsLeft;
@property SKSpriteNode *controlsCenter;
@property SKSpriteNode *controlsRight;
#endif


@property TMXLayer *roadLayer;
@property TMXObjectGroup *spawnPoints;
@property CGPoint playerSpawnPoint;
@property NSInteger currentTileGid;

@property BOOL turnRequested;
@property CGFloat turnDegrees;

@property (nonatomic) NSMutableArray *spawners; // store an array of all the spawners in order to update them on every frame

@property SKLabelNode *labelClock;

@property PanGestureState panGestureState;

#if DEBUG_PLAYER_CONTROL
@property SKLabelNode *controlStateLabel; // for the player
#endif

#if DEBUG_PLAYER_SWIPE
@property SKLabelNode *swipeLabel;
#endif


@end

@implementation AMBLevelScene

- (void)didMoveToView:(SKView *)view {
    
    self.panGestureState = GestureIdle;
#if TARGET_OS_IPHONE
    self.gesturePan = [[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(handlePan:)];
    
    self.gestureSwipeUp = [[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(handleSwipeUp:)];
    [self.gestureSwipeUp setDirection:UISwipeGestureRecognizerDirectionUp];
    [self.gestureSwipeUp requireGestureRecognizerToFail:self.gesturePan];

    self.gestureSwipeDown = [[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(handleSwipeDown:)];
    [self.gestureSwipeDown setDirection:UISwipeGestureRecognizerDirectionDown];
    [self.gestureSwipeDown requireGestureRecognizerToFail:self.gesturePan];

    self.gestureTap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(handleTap:)];
    [self.gestureTap setNumberOfTapsRequired:2]; // 2 taps to stop/start
    
    self.gestureLongPress = [[UILongPressGestureRecognizer alloc]initWithTarget:self action:@selector(handleLongPress:)]; // long press to slow

    [view addGestureRecognizer:self.gesturePan];
    [view addGestureRecognizer:self.gestureSwipeUp];
    [view addGestureRecognizer:self.gestureSwipeDown];
    [view addGestureRecognizer:self.gestureTap];
    [view addGestureRecognizer:self.gestureLongPress];
#endif
    
}

- (void)willMoveFromView:(SKView *)view {
#if TARGET_OS_IPHONE
    [view removeGestureRecognizer:self.gesturePan];
    [view removeGestureRecognizer:self.gestureSwipeUp];
    [view removeGestureRecognizer:self.gestureSwipeDown];
    [view removeGestureRecognizer:self.gestureTap];
    [view removeGestureRecognizer:self.gestureLongPress];
#endif
    
}


-(id)initWithSize:(CGSize)size {    
    if (self = [super initWithSize:size]) {

        self.physicsWorld.contactDelegate = self;

        // indicator, created before createWorld so it can be referenced in initial spawns
        _indicator = [[AMBIndicator alloc]initForScene:self];

        
        // add controls
        #if TARGET_OS_IPHONE
//        [self createControls];
        #endif
        
#if DEBUG_PLAYER_SWIPE
        _swipeLabel = [SKLabelNode labelNodeWithFontNamed:@"Arial"];
        _swipeLabel.fontColor = [SKColor whiteColor];
        _swipeLabel.fontSize = 50;
        _swipeLabel.text = @"|";
        _swipeLabel.position = CGPointMake(0, -self.size.height/2 + 60);
        [self addChild:_swipeLabel];
#endif

        // minimap
        [self createMinimap];

        
        [self createWorld]; // set up tilemap
        [self addPlayer];

#if DEBUG_PLAYER_CONTROL
        _controlStateLabel = [SKLabelNode labelNodeWithFontNamed:@"Arial"];
        _controlStateLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentModeLeft;
        _controlStateLabel.fontColor = [SKColor yellowColor];
        _controlStateLabel.position = CGPointMake(-400,0);
        _controlStateLabel.text = @"PlayerIsStopped";
        [self addChild:_controlStateLabel];
#endif
    
        
        
        _turnRequested = NO;
        
        // camera
        _camera = [[AMBCamera alloc] initWithTargetSprite:_player];
        _camera.zPosition = 999;
        [_tilemap addChild:_camera];
        
        _camera.miniMap = _miniMapContainer; // the camera needs to know about the minimap container so it can rotate it at the same time as the real world
        
        // scoring
        _scoreKeeper = [AMBScoreKeeper sharedInstance]; // create a singleton ScoreKeeper
        _scoreKeeper.scene = self;
        
        SKLabelNode *labelScore = [_scoreKeeper createScoreLabelWithPoints:0 atPos:CGPointMake(self.size.width/2 - 250, self.size.height/2-50)];
        [self addChild:labelScore];
     
        
        // event label
        SKLabelNode *labelEvent = [_scoreKeeper createEventlabelAtPos:CGPointZero];
        [self addChild:labelEvent];
        
        
        // clock... for testing at the moment, but who knows...?
        _labelClock = [SKLabelNode labelNodeWithFontNamed:@"Courier-Bold"];
        _labelClock.horizontalAlignmentMode = SKLabelHorizontalAlignmentModeLeft;
        _labelClock.fontColor = [SKColor yellowColor];
        _labelClock.text = @"00:00";
        _labelClock.position = CGPointMake(self.size.width/2 - 250, self.size.height/2 -150);
        [self addChild:_labelClock];
        
        
        
        // fuel
        _fuelStatus = [SKLabelNode labelNodeWithFontNamed:@"Courier-Bold"];
        _fuelStatus.horizontalAlignmentMode = SKLabelHorizontalAlignmentModeLeft;
        _fuelStatus.text = [NSString stringWithFormat:@"FUEL: 3/3"];
        _fuelStatus.fontColor = [SKColor yellowColor];
        _fuelStatus.position = CGPointMake(self.size.width/2 - 250, self.size.height/2-75);
        _fuelStatus.zPosition = 999;
        [self addChild:_fuelStatus];
        

        
        // patient TTL
        _patientTimeToLive = [SKLabelNode labelNodeWithFontNamed:@"Courier-Bold"];
        _patientTimeToLive.horizontalAlignmentMode = SKLabelHorizontalAlignmentModeLeft;
        _patientTimeToLive.text = [NSString stringWithFormat:@"PATIENT: --"];
        _patientTimeToLive.fontColor = [SKColor yellowColor];
        _patientTimeToLive.position = CGPointMake(self.size.width/2 - 250, self.size.height/2-100);
        _patientTimeToLive.zPosition = 999;
        [self addChild:_patientTimeToLive];

    
        
#if DEBUG
        NSLog(@"[[   SCORE:  %ld   ]]", _scoreKeeper.score);
#endif
        
        // start the clock
        _gameStartTime = CACurrentMediaTime();


        
    }
    return self;
}


- (void)createMinimap {
    

    
    _miniMap = [SKSpriteNode spriteNodeWithImageNamed:@"level01_firstdraft_MINI.png"];
    _miniMap.anchorPoint = CGPointMake(0, 0);
    _miniMap.zPosition = 1000;
    _miniMap.position = CGPointMake(-_miniMap.size.width/2, -_miniMap.size.height/2);

    _miniMapContainer = [SKSpriteNode spriteNodeWithColor:[SKColor blackColor] size:CGSizeMake(150,150)];
    _miniMapContainer.anchorPoint = CGPointMake(0.5, 0.5);

    [_miniMapContainer addChild:_miniMap];
    _miniMapContainer.position = CGPointMake(-self.size.width/2 + 100, self.size.height/2-100);
    [self addChild:_miniMapContainer];
    
    
}

- (SKSpriteNode *)addObjectToMinimapAtPoint:(CGPoint)position withColour:(SKColor *)colour withScale:(CGFloat)scale {
    SKSpriteNode *object = [SKSpriteNode spriteNodeWithColor:colour size:CGSizeMake(256*scale, 256*scale)];
    CGPoint posScaled = CGPointMultiplyScalar(position, 0.0125);
    object.position = posScaled;
    object.zPosition = 100;
    [_miniMap addChild:object];

#if DEBUG_MINIMAP
    NSLog(@"Adding object to minimap at %1.0f,%1.0f", posScaled.x,posScaled.y);
#endif
    
    return object;
}

- (void) addPatientSeverity:(PatientSeverity)severity atPoint:(CGPoint)point {
    CGPoint patientPosition = point;
    AMBPatient *patient = [[AMBPatient alloc]initWithSeverity:severity position:patientPosition];
    [_tilemap addChild:patient];
}


//- (void) addHospitalAtPoint:(CGPoint)point {
//    // TODO: this is deprecated, right? I think this was just for testing.
//    SKSpriteNode *hospital = [SKSpriteNode spriteNodeWithImageNamed:@"hospital"];
//    
//    hospital.position = point;
//    hospital.zPosition = 200;
//    hospital.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:CGSizeMake(hospital.size.width * 3, hospital.size.height * 3)]; // for the physics body, expand the hospital's size so that it encompasses all the surrounding road blocks.
//    hospital.physicsBody.categoryBitMask = categoryHospital;
//    hospital.physicsBody.collisionBitMask = 0x00000000;
//    
//    [_tilemap addChild:hospital];
//    
//    
//    
//    
//}

- (void)addMovingCharacterToTileMap:(AMBMovingCharacter *)character {
    // encapsulated like this because we need to make sure levelScene is set on all the player/traffic nodes
    [_mapLayerRoad addChild:character]; // changed from _tilemap to _mapLayerRoad to keep things consistent between the sprites
    character.levelScene = self;
}

- (void) addPlayer {
    
    _player = [[AMBPlayer alloc] init];
    _player.position = CGPointMake(_playerSpawnPoint.x, _playerSpawnPoint.y); // TODO: don't hardcode this offset!

    [self addMovingCharacterToTileMap:_player];
#if DEBUG
    NSLog(@"adding player at %1.0f,%1.0f",_playerSpawnPoint.x,_playerSpawnPoint.y);
#endif
    
    
    _miniPlayer = [self addObjectToMinimapAtPoint:_player.position withColour:[SKColor greenColor] withScale:0.0125];

}

- (NSString *)timeFormatted:(int)totalSeconds // from http://stackoverflow.com/a/1739411
{
    
    int seconds = totalSeconds % 60;
    int minutes = (totalSeconds / 60) % 60;
//    int hours = totalSeconds / 3600;
    
    return [NSString stringWithFormat:@"%02d:%02d",minutes, seconds];
}

- (float)randomValueBetween:(float)low andValue:(float)high {//Used to return a random value between two points
    return (((float) arc4random() / 0xFFFFFFFFu) * (high - low)) + low;
}

-(void)calcDelta:(CFTimeInterval)currentTime {
    if (self.sceneLastUpdate) {
        _sceneDelta = currentTime - self.sceneLastUpdate;
    } else {
        _sceneDelta = 0;
    }
    
    _sceneLastUpdate = currentTime;
}

-(void)update:(CFTimeInterval)currentTime {
    
    [self calcDelta:currentTime];
    
    // update the clock
    
    CGFloat seconds = 180 - (currentTime - _gameStartTime); // Modulo (%) operator below needs int or long
    
    
    
    _labelClock.text = [self timeFormatted:seconds];

    
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
    [_mapLayerRoad enumerateChildNodesWithName:@"patient" usingBlock:^(SKNode *node, BOOL *stop) {
        AMBPatient *patientNode = (AMBPatient *)node;
        [patientNode updatePatient];
        //NSLog(@"update patient");
    }];
    
    // update the indicators
    [_indicator update];
    
    // update traffic
    if (renderTraffic) {
        for (AMBTrafficVehicle *vehicle in _trafficVehicles) {
            [vehicle updateWithTimeSinceLastUpdate:_sceneDelta];
        }
        
    }
    
    // update minimap
    _miniPlayer.position = CGPointMultiplyScalar(_player.position, 0.0125);
    
    
#if DEBUG_PLAYER_CONTROL
    switch (_player.controlState) {
        case PlayerIsStopped:
            _controlStateLabel.text = @"PlayerIsStopped";
            break;
        case PlayerIsDrivingStraight:
            _controlStateLabel.text = @"PlayerIsDrivingStraight";
            break;
        case PlayerIsAccelerating:
            _controlStateLabel.text = @"PlayerIsAccelerating";
            break;
        case PlayerIsChangingLanes:
            _controlStateLabel.text = @"PlayerIsChangingLanes";
            break;
        case PlayerIsDecelerating:
            _controlStateLabel.text = @"PlayerIsDecelerating";
            break;
        case PlayerIsTurning:
            _controlStateLabel.text = @"PlayerIsTurning";
            break;
    }
#endif
}

#pragma mark World Building
- (void)createWorld {
    
//    _worldNode = [SKSpriteNode spriteNodeWithImageNamed:@"border"];
    _worldNode = [SKNode node];
    _worldNode.name = @"worldNode";
    _worldNode.position = CGPointMake(0, -150);
    [self addChild:_worldNode];
    
    [self levelWithTilemap:LEVEL_NAME];

    if (_tilemap) {
        [_worldNode addChild:_tilemap];
        
    }
    

    
    
    // Set up spawn points
    NSDictionary *playerSpawn = [[_mapGroupSpawnPlayer objects] objectAtIndex:0];
    _playerSpawnPoint = [self centerOfObject:playerSpawn];
    
    NSArray *hospitalSpawns = [_mapGroupSpawnHospitals objects];
    for (NSDictionary *object in hospitalSpawns) {
        AMBHospital *hospital = [[AMBHospital alloc] init];
        hospital.blendMode = SKBlendModeReplace;
        
        CGPoint hospitalPos = [self centerOfObject:object];
        [hospital addObjectToNode:_mapLayerRoad atPosition:hospitalPos];

        // add hospital indicator target
        [_indicator addTarget:hospital type:IndicatorHospital];
        _miniHospital = [self addObjectToMinimapAtPoint:hospitalPos withColour:[SKColor whiteColor] withScale:0.02]; // TODO: this assumes just one hospital. does it matter?
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

    // traffic spawners
    if (renderTraffic) {
        _trafficVehicles = [[NSMutableArray alloc]init];
        
        CGSize gridSize = _mapLayerTraffic.layerInfo.layerGridSize;
        for (int w = 0 ; w < gridSize.width; ++w) {
            for(int h = 0; h < gridSize.height; ++h) {
                
                CGPoint coord = CGPointMake(w, h);

                int tileGid =
                [_mapLayerTraffic.layerInfo tileGidAtCoord:coord];

                if(!tileGid)
                    continue;

                NSDictionary *tileProperties = [_tilemap propertiesForGid:tileGid];            // properties will be name (traffic), center_x, center_y, orientation
                if ([tileProperties[@"name"] isEqualToString:@"traffic"]) {
                    // spawn the thing!
                    CGPoint center = CGPointMake([tileProperties[@"center_x"] floatValue], [tileProperties[@"center_y"] floatValue]);
                    CGPoint point = [_mapLayerTraffic pointForCoord:coord];
                    center = CGPointAdd(center, point);

    //                NSLog(@"Adding traffic object at %1.0f,%1.0f",center.x,center.y);
                    [self spawnTrafficObjectAt:center rotation:tileProperties[@"orientation"] shouldTurnAtIntersections:YES];
                }

            }
        }
    }
    

    // fuel powerup spawners
    NSArray *fuelSpawns = [_mapGroupSpawnPowerups objects];
    for (NSDictionary *object in fuelSpawns) {
        CGPoint spawnPoint = [self centerOfObject:object];
        
        // grab properties of the spawner from the TMX object directly
        NSTimeInterval firstSpawnAt = [[object valueForKey:@"firstSpawnAt"] intValue];
        NSTimeInterval frequency = [[object valueForKey:@"frequency"] intValue];
        NSTimeInterval frequencyUpperRange = [[object valueForKey:@"frequencyUpperValue"] intValue]; // defaults to 0
        
        // build an array of patients based on the severity property (can be comma-separated)
        NSArray *fuelArray = [NSArray arrayWithObject:[[AMBPowerup alloc]init]];
        
        
        AMBSpawner *spawner = [[AMBSpawner alloc] initWithFirstSpawnAt:firstSpawnAt
                                                         withFrequency:frequency
                                                   frequencyUpperRange:frequencyUpperRange
                                                           withObjects:fuelArray];
        
        //SKSpriteNode *fuelSpawn = [self addObjectToMinimapAtPoint:spawnPoint withColour:[SKColor orangeColor] withScale:1.0];
        
        [spawner addObjectToNode:_mapLayerRoad atPosition:spawnPoint];
        [_spawners addObject:spawner];
    }
    
    
    
}

- (void)spawnTrafficObjectAt:(CGPoint)pos rotation:(NSString *)rot shouldTurnAtIntersections:(BOOL)intersections {

    CGFloat rotation;

    if ([rot isEqualToString:@"n"]) {
        rotation = DegreesToRadians(90);
    } else if ([rot isEqualToString:@"e"]) {
        rotation = DegreesToRadians(0);
    } else if ([rot isEqualToString:@"s"]) {
        rotation = DegreesToRadians(-90);
    } else if ([rot isEqualToString:@"w"]) {
        rotation = DegreesToRadians(180);
    }

    AMBTrafficVehicle *traffic = [AMBTrafficVehicle createVehicle:VehicleTypeSedan withSpeed:VehicleSpeedSlow atPoint:pos withRotation:rotation shouldTurnAtIntersections:intersections];

    traffic.name = @"real_traffic";
    [self addMovingCharacterToTileMap:traffic];
    [_trafficVehicles addObject:traffic];
    

}

- (void)levelWithTilemap:(NSString *)tilemapFile {
    _tilemap = [self tileMapFromFile:tilemapFile];
    
    if (_tilemap) {
        // set up the layers/groups
        _mapLayerRoad =     [_tilemap layerNamed:@"road"];
//        _mapLayerScenery =  [_tilemap layerNamed:@"scenery"]; // removed because it's redundant
        _mapLayerTraffic =  [_tilemap layerNamed:@"spawn_traffic"];
        
        _mapGroupSpawnPlayer =      [_tilemap groupNamed:@"spawn_player"];
        _mapGroupSpawnPatients =    [_tilemap groupNamed:@"spawn_patients"];
        _mapGroupSpawnHospitals =   [_tilemap groupNamed:@"spawn_hospitals"];
//        _mapGroupSpawnTraffic =     [_tilemap groupNamed:@"spawn_traffic"];
        _mapGroupSpawnPowerups =    [_tilemap groupNamed:@"spawn_powerups"];
        

        [self createTileBoundingPaths];

    }
}

- (void)createTileBoundingPaths {
    // creates CGPaths for each road tile, so that we can check collision
    // this thing helps to rough it in: http://dazchong.com/spritekit/
    
    NSMutableDictionary *tileProperties =[_tilemap tileProperties];
    
    _roadTilePaths = [[NSMutableDictionary alloc] init];
    
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
        
        [_roadTilePaths setObject:(__bridge id)path forKey:tileType]; // TODO: memory leak because of bridging?
        
    } // end for
}


/** Calculates the center point of a TMXObjectGroup object based on its x/y offset and size. */
- (CGPoint)centerOfObject:(NSDictionary *)object {
    return CGPointMake([[object objectForKey:@"x"] intValue] + [[object objectForKey:@"width"] intValue]/2,
                       [[object objectForKey:@"y"] intValue] + [[object objectForKey:@"height"] intValue]/2);
}


#pragma mark Camera

- (void) centerOnNode: (SKNode *) node {
    // The offset is calculated from the world node now, instead of the scene. When converting the camera position into
    // scene coordinates, the rotation would always cause the view to go completely off the rails around 65 degrees
    CGPoint cameraPositionInWorldNode = [_worldNode convertPoint:node.position fromNode:node.parent];
    node.parent.position = CGPointMake(node.parent.position.x - cameraPositionInWorldNode.x,
                                       node.parent.position.y - cameraPositionInWorldNode.y);
}



#pragma mark Game logic
- (void)didBeginContact:(SKPhysicsContact *)contact {
    
    SKNode *node = contact.bodyA.node;
    if ([node isKindOfClass:[AMBPlayer class]]) {
        [(AMBPlayer *)node collidedWith:contact.bodyB victimNodeName:node.name];
    } else if ([node.parent isKindOfClass:[AMBTrafficVehicle class]]) {
        [(AMBTrafficVehicle *)node.parent beganCollision:contact];
    }
    
    node = contact.bodyB.node;
    if ([node isKindOfClass:[AMBPlayer class]]) {
        [(AMBPlayer *)node collidedWith:contact.bodyA victimNodeName:node.name];
    } else if ([node.parent isKindOfClass:[AMBTrafficVehicle class]]) {
        [(AMBTrafficVehicle *)node.parent beganCollision:contact];
    }

}

- (void)didEndContact:(SKPhysicsContact *)contact {
    
    SKNode *node = contact.bodyA.node;
    if ([node.parent isKindOfClass:[AMBTrafficVehicle class]]) {
        [(AMBTrafficVehicle *)node.parent endedCollision:contact];
    }
    
    node = contact.bodyB.node;
    if ([node.parent isKindOfClass:[AMBTrafficVehicle class]]) {
        [(AMBTrafficVehicle *)node.parent endedCollision:contact];
    }
    
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
#if TARGET_OS_IPHONE
- (void)createControls {
    // left
    _controlsLeft = [SKSpriteNode spriteNodeWithColor:[SKColor yellowColor] size:CGSizeMake(100, 100)];
    _controlsLeft.name = @"controlsLeft";
    _controlsLeft.zPosition = 999;
    _controlsLeft.position = CGPointMake(-self.size.width/2 + 75, -self.size.height/2 + 75);
    _controlsLeft.userData = [NSMutableDictionary dictionaryWithObject:@"NO" forKey:@"pressed"];
    
    [self addChild:_controlsLeft];
    
    // center
    _controlsCenter = [SKSpriteNode spriteNodeWithColor:[SKColor greenColor] size:CGSizeMake(100, 100)];
    _controlsCenter.name = @"controlsCenter_Go";
    _controlsCenter.zPosition = 999;
    _controlsCenter.position = CGPointMake(0, -self.size.height/2 + 75);
    _controlsCenter.userData = [NSMutableDictionary dictionaryWithObject:@"NO" forKey:@"pressed"];
    
    [self addChild:_controlsCenter];

    // right
    _controlsRight = [SKSpriteNode spriteNodeWithColor:[SKColor yellowColor] size:CGSizeMake(100, 100)];
    _controlsRight.name = @"controlsRight";
    _controlsRight.zPosition = 999;
    _controlsRight.position = CGPointMake(self.size.width/2 - 75, -self.size.height/2 + 75);
    _controlsRight.userData = [NSMutableDictionary dictionaryWithObject:@"NO" forKey:@"pressed"];
    
    [self addChild:_controlsRight];
    

}



// removed in favour of gestures
//- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
//    
//    UITouch *touch = [touches anyObject];
//    CGPoint touchLocationInScene = [touch locationInNode:self];
//    SKSpriteNode *touchedNode = (SKSpriteNode *)[self nodeAtPoint:touchLocationInScene];
//#if DEBUG_PLAYER_CONTROL
//    NSLog(@"touchedNode.name=%@",touchedNode.name);
//#endif
//    
//    if ([touchedNode.name isEqualToString:@"controlsCenter_Go"]) {
//        [_player handleInput:PlayerControlsStartMoving keyDown:YES];
//        _controlsCenter.name = @"controlsCenter_Stop";
//        _controlsCenter.color = [SKColor redColor];
//        [_controlsCenter.userData setObject:event forKey:@"event"];
//        
//        
//    } else if ([touchedNode.name isEqualToString:@"controlsCenter_Stop"]) {
//        [_player handleInput:PlayerControlsStopMoving keyDown:YES];
//        _controlsCenter.name = @"controlsCenter_Go";
//        _controlsCenter.color = [SKColor greenColor];
//        [_controlsCenter.userData setObject:event forKey:@"event"];
//        
//    } else if ([touchedNode.name isEqualToString:@"controlsLeft"]) {
//        [_player handleInput:PlayerControlsTurnLeft keyDown:YES];
//        _controlsLeft.color = SKColorWithRGB(120, 120, 0);
//        [_controlsLeft.userData setObject:event forKey:@"event"];
//        
//    } else if ([touchedNode.name isEqualToString:@"controlsRight"]) {
//        [_player handleInput:PlayerControlsTurnRight keyDown:YES];
//        _controlsRight.color = SKColorWithRGB(120, 120, 0);
//        [_controlsRight.userData setObject:event forKey:@"event"];
//    }
//    
//}
//
//- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
//
//#if DEBUG_PLAYER_CONTROL
//    NSLog(@"touchesEnded");
//#endif
//    
//    if ([_controlsCenter.userData[@"event"] isEqual:event]) {
//#if DEBUG_PLAYER_CONTROL
//        NSLog(@"unset controlsCenter event");
//#endif
//        [_controlsCenter.userData removeObjectForKey:@"event"];
//    }
//
//    if ([_controlsLeft.userData[@"event"] isEqual:event]) {
//#if DEBUG_PLAYER_CONTROL
//        NSLog(@"unset controlsLeft event");
//#endif
//        [_controlsLeft.userData removeObjectForKey:@"event"];
//        _controlsLeft.color = [SKColor yellowColor];
//        [_player handleInput:PlayerControlsTurnLeft keyDown:NO];
//    }
//
//    if ([_controlsRight.userData[@"event"] isEqual:event]) {
//#if DEBUG_PLAYER_CONTROL
//        NSLog(@"unset controlsRight event");
//#endif
//        [_controlsRight.userData removeObjectForKey:@"event"];
//        _controlsRight.color = [SKColor yellowColor];
//        [_player handleInput:PlayerControlsTurnRight keyDown:NO];
//    }
//
//    
//
//}


// Gesture Controls


- (void)handleSwipeUp:(UIGestureRecognizer *)recognizer {
    [_player handleInput:PlayerControlsStartMoving keyDown:YES];
}

- (void)handleSwipeDown:(UIGestureRecognizer *)recognizer {
    [_player handleInput:PlayerControlsStopMoving keyDown:YES];
}

- (void)handlePan:(UIGestureRecognizer *)recognizer {
    CGPoint vel = [(UIPanGestureRecognizer *)recognizer velocityInView:self.view]; // negative x if moving to the left; we can ignore the y
    
#if DEBUG_PLAYER_CONTROL
    NSLog(@"handlePanl state=%li, velocity%1.0f,%1.0f",recognizer.state,vel.x,vel.y);
#endif
    
    // if a Pan gesture has begun, fire up OUR state machine; otherwise pass the current state through
    self.panGestureState = recognizer.state == UIGestureRecognizerStateBegan ? GestureBegan : self.panGestureState;
    
    
    switch (self.panGestureState) {
        case GestureIdle:
            // should never happen
            break;
        
        case GestureBegan:
            if (vel.x < 0) { // LEFT
                self.panGestureState = GestureLeftDown;
                [_player handleInput:PlayerControlsTurnLeft keyDown:YES];
#if DEBUG_PLAYER_SWIPE
                _swipeLabel.text = @"<<";
#endif
                
            } else { // RIGHT
                self.panGestureState = GestureRightDown;
                [_player handleInput:PlayerControlsTurnRight keyDown:YES];
#if DEBUG_PLAYER_SWIPE
                _swipeLabel.text = @">>";
#endif
                
            }
            break;
            
            
        case GestureLeftDown:
            if (recognizer.state == UIGestureRecognizerStateEnded) {
                [_player handleInput:PlayerControlsTurnLeft keyDown:NO]; // fingers up!
#if DEBUG_PLAYER_SWIPE
                _swipeLabel.text = @"|";
#endif
                
                break;
            }
            
            if (vel.x <= 2) { // LEFT, with 2 pts margin of error
                [_player handleInput:PlayerControlsTurnLeft keyDown:YES];
#if DEBUG_PLAYER_SWIPE
                _swipeLabel.text = @"<<";
#endif
                
                
            } else { // RIGHT
                self.panGestureState = GestureRightDown;
                [_player handleInput:PlayerControlsTurnRight keyDown:YES];
#if DEBUG_PLAYER_SWIPE
                _swipeLabel.text = @">>";
#endif
                
            }
            break;
            
        case GestureLeftUp:
            // should never be called; transition will be handled by LeftDown
            break;
            
        case GestureRightDown:
            if (recognizer.state == UIGestureRecognizerStateEnded) {
                [_player handleInput:PlayerControlsTurnRight keyDown:NO]; // fingers up!
#if DEBUG_PLAYER_SWIPE
                _swipeLabel.text = @"|";
#endif
                
                break;
            }
            
            if (vel.x >= -2) { // RIGHT, with 2 pts margin of error
                [_player handleInput:PlayerControlsTurnRight keyDown:YES];
#if DEBUG_PLAYER_SWIPE
                _swipeLabel.text = @">>";
#endif
                
                
            } else { // LEFT
                self.panGestureState = GestureLeftDown;
                [_player handleInput:PlayerControlsTurnLeft keyDown:YES];
#if DEBUG_PLAYER_SWIPE
                _swipeLabel.text = @"<<";
#endif
                
            }
            break;

            break;
            
        case GestureRightUp:
            // should never be called; transition will be handled by RightDown
            break;
        
    }
    
}

- (void)handleTap:(UIGestureRecognizer *)recognizer {
    // two taps, start/stop moving
#if DEBUG_PLAYER_CONTROL
    NSLog(@"handleTap");
#endif
    
    if (_player.isMoving) {
        [_player handleInput:PlayerControlsStopMoving keyDown:YES];
    } else {
        [_player handleInput:PlayerControlsStartMoving keyDown:YES];
    }


}

- (void)handleLongPress:(UIGestureRecognizer *)recognizer {
    // will be called multiple times after the gesture is recognized.
    // you can query the recognizer's state to respond to specific events.
#if DEBUG_PLAYER_CONTROL
    NSLog(@"handleLongPress");
#endif
 
}




#else
// OS X controls
- (void)handleKeyboardEvent: (NSEvent *)theEvent keyDown:(BOOL)downOrUp {
    
//    if (self.sceneLastUpdate - _lastKeyPress < KEY_PRESS_INTERVAL_SECS ) return;
    
    
    if ([theEvent modifierFlags] & NSNumericPadKeyMask) { // arrow keys
        _lastKeyPress = self.sceneLastUpdate;
        
        NSString *theArrow = [theEvent charactersIgnoringModifiers];
        unichar keyChar = 0;

        
        if ([theArrow length] == 1) {
            keyChar = [theArrow characterAtIndex:0];

            
            
            switch (keyChar) {
                case NSUpArrowFunctionKey:
//                    [_player startMoving];
                    [_player handleInput:PlayerControlsStartMoving keyDown:downOrUp];
                    break;
                    
                case NSLeftArrowFunctionKey:
//                    [_player authorizeMoveEvent:90];
                    [_player handleInput:PlayerControlsTurnLeft keyDown:downOrUp];
                    break;
                    
                case NSRightArrowFunctionKey:
//                    [_player authorizeMoveEvent:-90];
                    [_player handleInput:PlayerControlsTurnRight keyDown:downOrUp];
                    break;
                    
                case NSDownArrowFunctionKey:
//                    [_player stopMoving];
                    [_player handleInput:PlayerControlsStopMoving keyDown:downOrUp];
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
#endif

@end
