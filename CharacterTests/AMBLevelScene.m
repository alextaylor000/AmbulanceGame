//
//  XXXMyScene.m
//  CharacterTests
//
//  Created by Alex Taylor on 2014-07-06.
//  Copyright (c) 2014 Alex Taylor. All rights reserved.
//
/*
 
 required for multiple levels/modes:
    - init level with map
    - init level with different ambulance sprite
    - init level with timer (set amount, or 0 for endless mode)
    - custom scoring (e.g. patient delivery adds to timer)
    
    - ability to restart level
 
 */

#import "AMBLevelScene.h"
#import "AMBPlayer.h"
#import "AMBPatient.h"
#import "AMBHospital.h"
#import "AMBSpawner.h"
#import "AMBPowerup.h"
#import "AMBTrafficVehicle.h"
#import "JSTilemap.h"   // for supporting TMX maps
#import "SKTUtils.h"
#import "AMBGameOver.h"



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

@property BOOL renderTraffic;
@property SKNode *miniMapContainer; // the node that holds the minimap, so we can rotate it easily

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

@property NSDictionary *initialConditions; // for restarting the game

@property (nonatomic) NSMutableArray *spawners; // store an array of all the spawners in order to update them on every frame

@property SKLabelNode *labelClock;

@property PanGestureState panGestureState;

#if DEBUG_PLAYER_CONTROL
@property SKSpriteNode *panMover;
#endif


//#if DEBUG_PLAYER_CONTROL
//@property SKLabelNode *controlStateLabel; // for the player
//#endif

#if DEBUG_PLAYER_SWIPE
@property SKLabelNode *swipeLabel;
#endif

@property CGFloat minimapScaleFactor; // how much to scale positions by on the minimap; a product of the minimap size relative to the tilemap size

@property AMBTimer *gameClock;


@end

@implementation AMBLevelScene

- (void)didMoveToView:(SKView *)view {
    
    NSLog(@"View is %1.0fx%1.0f",view.bounds.size.width,view.bounds.size.height);
    
    self.panGestureState = GestureIdle;
#if TARGET_OS_IPHONE
    self.gesturePan = [[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(handlePan:)];

    
    self.gestureTap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(handleTap:)];
    [self.gestureTap setNumberOfTapsRequired:2]; // 2 taps to stop/start
    
    self.gestureLongPress = [[UILongPressGestureRecognizer alloc]initWithTarget:self action:@selector(handleLongPress:)]; // long press to slow
    [self.gestureLongPress setMinimumPressDuration:0.15];

    self.gesturePan.delegate = self;
    self.gestureLongPress.delegate = self;
    
    [view addGestureRecognizer:self.gesturePan];
    [view addGestureRecognizer:self.gestureTap];
    [view addGestureRecognizer:self.gestureLongPress];
#endif
    
}


- (void)willMoveFromView:(SKView *)view {
#if TARGET_OS_IPHONE
    [view removeGestureRecognizer:self.gesturePan];
    [view removeGestureRecognizer:self.gestureTap];
    [view removeGestureRecognizer:self.gestureLongPress];
#endif
    
}

- (id)initWithSize:(CGSize)size gameType:(AMBGameType)gameType vehicleType:(AMBVehicleType)vehicleType levelType:(AMBLevelType)levelType tutorial:(BOOL)tut {

    if (self = [super initWithSize:size]) {
        
        /**
        
         Differences in tutorial mode:
            - No traffic at first
            - No timer
            - Patient spawns controlled by tutorial
         
         */
        _initialConditions = @{
                               @"size" : [NSValue valueWithCGSize:size],
                               @"gameType": [NSNumber numberWithInt:gameType],
                               @"vehicleType": [NSNumber numberWithInt:vehicleType],
                               @"levelType": [NSNumber numberWithInt:levelType],
                               @"tutorial": [NSNumber numberWithBool:tut]
                               };
        
        _tutorialMode = tut;
        
        // scoring
        _scoreKeeper = [AMBScoreKeeper sharedInstance]; // create a singleton ScoreKeeper
        _scoreKeeper.scene = self;
        
        
        _renderTraffic = 1;
        self.backgroundColor = [SKColor yellowColor];
        self.physicsWorld.contactDelegate = self;

        // indicator, created before createWorld so it can be referenced in initial spawns
        _indicator = [[AMBIndicator alloc]initForScene:self];

        
        // choose level
        NSString *levelName;
        switch (levelType) {
            case AMBCity1:
                levelName = @"level01_v002.tmx";
                break;
                
            case AMBCity2:
                levelName = @"level01_v002.tmx";
                break;
                
            case AMBCity3:
                levelName = @"level01_v002.tmx";
                break;
        }
        
        [self createWorldWithLevel:levelName];  // set up tilemap
        [self createMinimap];                   // minimap
        [self createSpawners];                  // used to be in createWorld
        [self addPlayerUsingSprite:vehicleType];

        
        _turnRequested = NO;
        
        // camera
        _camera = [[AMBCamera alloc] initWithTargetSprite:_player];
        _camera.zPosition = 999;
        [_tilemap addChild:_camera];
        
        _camera.miniMap = _miniMapContainer; // the camera needs to know about the minimap so it can rotate it at the same time as the real world
        
        SKLabelNode *labelScore = [_scoreKeeper createScoreLabelWithPoints:0 atPos:CGPointMake(self.size.width/2 - 120, self.size.height/2-80)];
        if (!labelScore.parent) {
            [self addChild:labelScore];
        }
        
        
        // notification node
        SKSpriteNode *notifications = [_scoreKeeper createNotificationAtPos:CGPointZero];


        [self addChild:notifications];
        
        // clock
        _gameClock = [[AMBTimer alloc] initWithSecondsRemaining:180]; // create the timer object. doesn't start until startTimer is called.
        
        _labelClock = [SKLabelNode labelNodeWithFontNamed:@"AvenirNextCondensed-Bold"];
        _labelClock.horizontalAlignmentMode = SKLabelHorizontalAlignmentModeRight;
        _labelClock.fontColor = [SKColor yellowColor];
        _labelClock.text = @"00:00";
        _labelClock.fontSize = 30;
        _labelClock.position = CGPointMake(self.size.width/2 - 120, self.size.height/2 -115);
        [self addChild:_labelClock];
        
        
        
        [self createFuelGauge];
        

        
    
        
        // tutorial
        if (_tutorialMode) {
            _tutorialOverlay = [AMBTutorial tutorialOverlay];
            _tutorialOverlay.position = CGPointMake(0, 200);
            [self addChild:_tutorialOverlay];
            [_tutorialOverlay beginTutorialAfterDelayOf:0.75];
            
             _mapLayerTrafficAI.alpha = 0; // hide the traffic
            
        }

        // start clock
        if (!_tutorialMode) {
            [_gameClock startTimer];
        }
        
        
        
    }
    return self;
}

- (void)pauseScene {
    [_gameClock pauseTimer];
    if (_player.patient) {
        [_player.patient.patientTimer pauseTimer];
    }
    
    self.view.paused = YES;

    
}

- (void)resumeScene {

    [_gameClock resumeTimer];
    if (_player.patient) {
        [_player.patient.patientTimer resumeTimer];
    }

    
    self.view.paused = NO;

}

- (void)allPatientsDelivered {
    [self gameOverBecause:GameOverReasonSavedEveryone];
}

- (void)restart {
    // re-init the scene. use _tutorialMode because it will get set to "NO" if the user has completed it before restarting.
    
    [self.scene removeAllChildren];    // remove all objects from scene first
    [self.scoreKeeper init]; // re-init scorekeeper

    
    AMBLevelScene *newScene = [[AMBLevelScene alloc]initWithSize:self.size gameType:[_initialConditions[@"gameType"] intValue] vehicleType:[_initialConditions[@"vehicleType"] intValue] levelType:[_initialConditions[@"levelType"]intValue] tutorial:_tutorialMode];
    
    SKTransition *fadeTransition = [SKTransition fadeWithColor:[SKColor colorWithRed:254 green:204 blue:44 alpha:1] duration:0.75];

    self.view.paused = NO;
    [self.view presentScene:newScene transition:fadeTransition];

    
}

- (void)didCompleteTutorial {
    _tutorialMode = NO;
    
    // do things like turn traffic on, start timer, etc.
    [_gameClock startTimer];
    
    SKAction *fadeIn = [SKAction fadeInWithDuration:2.0];
    [_mapLayerTrafficAI runAction:fadeIn];
    
    
}

- (void)createFuelGauge {
    _fuelGauge = [AMBFuelGauge fuelGaugeWithAmount:0];
    _fuelGauge.position = CGPointMake(self.size.width/2 - _fuelGauge.size.width/2, self.size.height/2 - _fuelGauge.size.height/2 - 25); // 25 for padding
    
    [self addChild: _fuelGauge];
    [_fuelGauge addFuel:124];
}

- (void)createMinimap {
    
    
    _miniMap = [SKSpriteNode spriteNodeWithImageNamed:@"level01_firstdraft_MINI-256.png"];
    _miniMap.anchorPoint = CGPointMake(0, 0);
    _miniMap.zPosition = 1000;

    _minimapScaleFactor = _miniMap.size.width / (_tilemap.mapSize.width * _tilemap.tileSize.width); // makes objects 1 tile big

    _miniMapContainer = [SKNode node];
    [_miniMapContainer addChild:_miniMap];
    
//    SKSpriteNode *maskNode = [SKSpriteNode spriteNodeWithColor:[SKColor greenColor] size:CGSizeMake(150,150)]; // TODO: change this colour as appropriate
    SKSpriteNode *maskNode = [SKSpriteNode spriteNodeWithImageNamed:@"minimap_mask"];
    SKSpriteNode *frameNode = [SKSpriteNode spriteNodeWithImageNamed:@"minimap_frame"];
    
    SKCropNode *miniMapFrame = [[SKCropNode alloc]init];
    miniMapFrame.maskNode = maskNode;

    [miniMapFrame addChild:maskNode];
    [miniMapFrame addChild:_miniMapContainer];
    [miniMapFrame addChild:frameNode];

    miniMapFrame.position = CGPointMake(-self.size.width/2 + 100, self.size.height/2-100);
    [self addChild:miniMapFrame];
    
    
}

- (SKSpriteNode *)addObjectToMinimapAtPoint:(CGPoint)position withColour:(SKColor *)colour withSize:(CGFloat)size {

    CGFloat mult = _minimapScaleFactor * size; // in case we want something bigger than 1 tile...
    SKSpriteNode *object = [SKSpriteNode spriteNodeWithColor:colour size:CGSizeMake(_tilemap.tileSize.width*mult, _tilemap.tileSize.width*mult)];

    CGPoint posScaled = CGPointMultiplyScalar(position, _minimapScaleFactor);
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



- (void)addMovingCharacter:(AMBMovingCharacter *)character toLayer:(SKNode *)layer {
    // encapsulated like this because we need to make sure levelScene is set on all the player/traffic nodes
    [layer addChild:character];
    character.levelScene = self;
}

- (void) addPlayerUsingSprite:(AMBVehicleType)vehicleType {
    NSDictionary *playerSpawn = [[_mapGroupSpawnPlayer objects] objectAtIndex:0];
    _playerSpawnPoint = [self centerOfObject:playerSpawn];
    
    
    _player = [[AMBPlayer alloc] initWithSprite:vehicleType];
    _player.position = CGPointMake(_playerSpawnPoint.x, _playerSpawnPoint.y);

    [self addMovingCharacter:_player toLayer:_mapLayerRoad];
#if DEBUG
    NSLog(@"adding player at %1.0f,%1.0f",_playerSpawnPoint.x,_playerSpawnPoint.y);
#endif
    
    
    _miniPlayer = [self addObjectToMinimapAtPoint:_player.position withColour:[SKColor greenColor] withSize:1];
    _miniMap.position = CGPointMake(-_miniPlayer.position.x, -_miniPlayer.position.y);
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
        _sceneDelta = fminf(0.02, currentTime - self.sceneLastUpdate); // run at 1/60 or never less than 1/50
    } else {
        _sceneDelta = 0;
    }
    
    _sceneLastUpdate = currentTime;
}

//-(void)update:(CFTimeInterval)currentTime {
- (void)update:(NSTimeInterval)currentTime {
    if (!self.paused) {
        

    [self calcDelta:currentTime];
    
    // update the clock
    [_gameClock update:currentTime];
    _labelClock.text = [self timeFormatted:[_gameClock secondsRemaining]];

    // update the score
    [_scoreKeeper update];
        
    if (_gameClock.timerState == AMBTimerStateEmpty) {
        [self gameOverBecause:GameOverReasonOutOfTime];
    }
    
    [_player updateWithTimeSinceLastUpdate:_sceneDelta];
    [_camera updateWithTimeSinceLastUpdate:_sceneDelta];
    [_fuelGauge updateWithTimeSinceLastUpdate:_sceneDelta];
    
    [self centerOnNode:_camera];
    
    _currentTileGid = [_mapLayerRoad tileGidAt:_player.position];

    
    // update the spawners
    // TODO: should this be part of the spawner class?
    [_spawners enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        AMBSpawner *spawnerObj = (AMBSpawner *)obj;
        [spawnerObj updateWithTimeSinceLastUpdate:_sceneDelta];
    }];

    // update all visible patients
#warning enumerateChildNodes is an expensive process
    [_mapLayerInteractives enumerateChildNodesWithName:@"patient" usingBlock:^(SKNode *node, BOOL *stop) {
        AMBPatient *patientNode = (AMBPatient *)node;
        [patientNode updatePatient];
    }];
    
    // update the indicators
    [_indicator update];
    
    // update traffic
    if (_renderTraffic) {
        for (AMBTrafficVehicle *vehicle in _trafficVehicles) {
            CGFloat distanceFromPlayer = CGPointDistance(self.player.position, vehicle.position);


            if (vehicle.hidden) {
                if (distanceFromPlayer < TRAFFIC_MAX_DISTANCE_FROM_PLAYER) {
                    // vehicle has entered the player's space; begin animating.

                    // randomize the wait time to give the illusion of ... randomness!
                    [vehicle runAction:[SKAction waitForDuration:0 withRange:8] completion:^(void){
                        vehicle.hidden = NO;
                    }];

                }
                
            } else {
                if (distanceFromPlayer < TRAFFIC_MAX_DISTANCE_FROM_PLAYER) {
                    // vehicle is within the player's space; continue animating.
                    [vehicle updateWithTimeSinceLastUpdate:_sceneDelta];
                } else {
                    // vehicle has left the player's space; stop animation and reset to original position.
                    vehicle.hidden = YES;
                    vehicle.position = vehicle.originalPosition;
                    vehicle.zRotation = vehicle.originalRotation;
                    vehicle.direction = vehicle.originalDirection;
                    
                    [vehicle swapTexture];
                    
                }
            }

        }
        
    }
    
    // update minimap
    _miniPlayer.position = CGPointMultiplyScalar(_player.position, _minimapScaleFactor);
    _miniMap.position = CGPointMake(-_miniPlayer.position.x, -_miniPlayer.position.y);

    } // self.paused
}

#pragma mark World Building
- (void)createWorldWithLevel:(NSString *)level_name {
    CGFloat sceneHeight = self.size.height/2 * -0.6;
    
    _worldNode = [SKNode node];
    _worldNode.name = @"worldNode";
    _worldNode.position = CGPointMake(0, sceneHeight); // camera offset
    [self addChild:_worldNode];
    
    [self levelWithTilemap:level_name];

    if (_tilemap) {
        [_worldNode addChild:_tilemap];
        
    }
    
    
    
}


- (void)createSpawners {
    // Set up spawn points
    
    NSArray *hospitalSpawns = [_mapGroupSpawnHospitals objects];
    for (NSDictionary *object in hospitalSpawns) {
        AMBHospital *hospital = [[AMBHospital alloc] init];
        hospital.blendMode = SKBlendModeReplace;
        
        _hospitalLocation = [self centerOfObject:object];
        [hospital addObjectToNode:_mapLayerRoad atPosition:_hospitalLocation];
        
        // add hospital indicator target
        [_indicator addTarget:hospital type:IndicatorHospital];
        _miniHospital = [self addObjectToMinimapAtPoint:_hospitalLocation withColour:[SKColor whiteColor] withSize:1.5]; // TODO: this assumes just one hospital. does it matter?
    }

    
    _spawners = [[NSMutableArray alloc]init];

    // patient spawners
    NSArray *patientSpawns = [_mapGroupSpawnPatients objects];
    
    [_scoreKeeper setPatientsTotal:[patientSpawns count]];
    
    for (NSDictionary *object in patientSpawns) {
        CGPoint spawnPoint = [self centerOfObject:object];
        
        
        // grab properties of the spawner from the TMX object directly
        NSTimeInterval firstSpawnAt = [[object valueForKey:@"firstSpawnAt"] intValue];
        NSTimeInterval frequency = [[object valueForKey:@"frequency"] intValue];
        NSTimeInterval frequencyUpperRange = [[object valueForKey:@"frequencyUpperRange"] intValue]; // defaults to 0

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
    if (_renderTraffic) {
        _trafficVehicles = [[NSMutableArray alloc]init];
        
        CGSize gridSize = _mapLayerTraffic.layerInfo.layerGridSize;
        for (int w = 0 ; w < gridSize.width; ++w) {
            for(int h = 0; h < gridSize.height; ++h) {
                
                CGPoint coord = CGPointMake(w, h);

                int tileGid =
                [_mapLayerTraffic.layerInfo tileGidAtCoord:coord];

                if(!tileGid)
                    continue;

                NSDictionary *tileProperties = [_tilemap propertiesForGid:tileGid];            // properties will be name (traffic), center_x, center_y, orientation, shouldTurnAtIntersections
                if ([tileProperties[@"name"] isEqualToString:@"traffic"]) {
                    // spawn the thing!
                    CGPoint center = CGPointMake([tileProperties[@"center_x"] floatValue], [tileProperties[@"center_y"] floatValue]);
                    CGPoint point = [_mapLayerTraffic pointForCoord:coord];
                    center = CGPointAdd(center, point);
                    
                    BOOL intersections = [tileProperties[@"shouldTurnAtIntersections"] boolValue];

                    [self spawnTrafficObjectAt:center vehicleType:VehicleTypeRandom rotation:tileProperties[@"orientation"] shouldTurnAtIntersections:intersections];
                }

            }
        }
    }
    

    // powerup spawners
    NSArray *powerupSpawns = [_mapGroupSpawnPowerups objects];
    for (NSDictionary *object in powerupSpawns) {
        CGPoint spawnPoint = [self centerOfObject:object];
        
        
        
        // grab properties of the spawner from the TMX object directly
        NSTimeInterval firstSpawnAt = [[object valueForKey:@"firstSpawnAt"] intValue];
        NSTimeInterval frequency = [[object valueForKey:@"frequency"] intValue];
        NSTimeInterval frequencyUpperRange = [[object valueForKey:@"frequencyUpperRange"] intValue]; // defaults to 0
        
        // get powerup type
        NSString *objectName = object[@"name"];
        
        if ([object[@"type"] isEqualToString:@"DEBUG"]) {
            NSLog(@"debug");
        }
        
        AMBPowerupType powerupType;
        
        if ([objectName isEqualToString:@"fuel.spawn"]) {
            powerupType = AMBPowerupFuel;
        } else if ([objectName isEqualToString:@"invincibility.spawn"]) {
            powerupType = AMBPowerupInvincibility;
        } else {
            // skip; it's invalid
            NSLog(@"Skipping invalid spawn object in powerups");
            continue;
        }
        
        
        NSArray *powerupArray = [NSArray arrayWithObject:[[AMBPowerup alloc]initAsType:powerupType]];
        
        
        AMBSpawner *spawner = [[AMBSpawner alloc] initWithFirstSpawnAt:firstSpawnAt
                                                         withFrequency:frequency
                                                   frequencyUpperRange:frequencyUpperRange
                                                           withObjects:powerupArray];
        
        
        [spawner addObjectToNode:_mapLayerRoad atPosition:spawnPoint];
        [_spawners addObject:spawner];
    }
    
    
    
}


#pragma mark Assets
+ (void)loadSceneAssets {
    SKTextureAtlas *atlas = [SKTextureAtlas atlasNamed:@"GameObjectSprites"];
    
    [AMBTutorial loadSharedAssets];
    [AMBScoreKeeper loadSharedAssets];
    [AMBPlayer loadSharedAssets];
    [AMBPowerup loadSharedAssets];
    [AMBTrafficVehicle loadSharedAssets];
    [AMBFuelGauge loadSharedAssets];
    
    
}







- (void)spawnTrafficObjectAt:(CGPoint)pos vehicleType:(VehicleType)vt rotation:(NSString *)rot shouldTurnAtIntersections:(BOOL)intersections {

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

    AMBTrafficVehicle *traffic = [AMBTrafficVehicle createVehicle:vt withSpeed:VehicleSpeedSlow atPoint:pos withRotation:rotation shouldTurnAtIntersections:intersections];

    traffic.name = @"real_traffic";
    traffic.hidden = YES; // traffic starts hidden until player approaches
    [self addMovingCharacter:traffic toLayer:_mapLayerTrafficAI];
    [_trafficVehicles addObject:traffic];
    

}

- (void)levelWithTilemap:(NSString *)tilemapFile {
    _tilemap = [self tileMapFromFile:tilemapFile];
    
    // traffic layer
    _mapLayerTrafficAI = [SKNode node];
    [_tilemap addChild:_mapLayerTrafficAI];
    
    
    // "interactives" layer. fuel, invincibility, and patients - anything that needs to rotate against the camera's rotation
    _mapLayerInteractives = [SKNode node];
    _mapLayerInteractives.userData = [NSMutableDictionary dictionaryWithObject:@0 forKey:@"childRotation"];
    
    [_tilemap addChild:_mapLayerInteractives];
    
    
    if (_tilemap) {
        // set up the layers/groups
        _mapLayerRoad =     [_tilemap layerNamed:@"road"];
        _mapLayerTraffic =  [_tilemap layerNamed:@"spawn_traffic"];

        
        _mapGroupSpawnPlayer =      [_tilemap groupNamed:@"spawn_player"];
        _mapGroupSpawnPatients =    [_tilemap groupNamed:@"spawn_patients"];
        _mapGroupSpawnHospitals =   [_tilemap groupNamed:@"spawn_hospitals"];
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
            
            CGPathMoveToPoint(path, NULL, 0 - offsetX, 90 - offsetY);
            CGPathAddLineToPoint(path, NULL, 256 - offsetX, 90 - offsetY);
            CGPathAddLineToPoint(path, NULL, 166 - offsetX, 90 - offsetY);
            CGPathAddLineToPoint(path, NULL, 166 - offsetX, 166 - offsetY);
            CGPathAddLineToPoint(path, NULL, 166 - offsetX, 256 - offsetY);
            CGPathAddLineToPoint(path, NULL, 90 - offsetX, 256 - offsetY);
            CGPathAddLineToPoint(path, NULL, 90 - offsetX, 166 - offsetY);
            CGPathAddLineToPoint(path, NULL, 0 - offsetX, 166 - offsetY);
            
        } else if ( [tileType isEqualToString:@"nw"]) {
            
            CGPathMoveToPoint(path, NULL, 0 - offsetX, 90 - offsetY);
            CGPathAddLineToPoint(path, NULL, 256 - offsetX, 90 - offsetY);
            CGPathAddLineToPoint(path, NULL, 166 - offsetX, 90 - offsetY);
            CGPathAddLineToPoint(path, NULL, 166 - offsetX, 166 - offsetY);
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
            CGPathAddLineToPoint(path, NULL, 166 - offsetX, 166 - offsetY);
            CGPathAddLineToPoint(path, NULL, 166 - offsetX, 256 - offsetY);
            CGPathAddLineToPoint(path, NULL, 90 - offsetX, 256 - offsetY);
            
        } else if ( [tileType isEqualToString:@"sw"]) {
            
            CGPathMoveToPoint(path, NULL, 0 - offsetX, 90 - offsetY);
            CGPathAddLineToPoint(path, NULL, 90 - offsetX, 90 - offsetY);
            CGPathAddLineToPoint(path, NULL, 90 - offsetX, 0 - offsetY);
            CGPathAddLineToPoint(path, NULL, 166 - offsetX, 0 - offsetY);
            CGPathAddLineToPoint(path, NULL, 166 - offsetX, 256 - offsetY);
            CGPathAddLineToPoint(path, NULL, 90 - offsetX, 256 - offsetY);
            CGPathAddLineToPoint(path, NULL, 90 - offsetX, 166 - offsetY);
            CGPathAddLineToPoint(path, NULL, 0 - offsetX, 166 - offsetY);
            
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

/* new multi-lane t-intersections feb 2015 */
        } else if ( [tileType isEqualToString:@"bbb_nes_b"]) {
            
            CGPathMoveToPoint(path, NULL, 90 - offsetX, 0 - offsetY);
            CGPathAddLineToPoint(path, NULL, 166 - offsetX, 0 - offsetY);
            CGPathAddLineToPoint(path, NULL, 166 - offsetX, 90 - offsetY);
            CGPathAddLineToPoint(path, NULL, 256 - offsetX, 90 - offsetY);
            CGPathAddLineToPoint(path, NULL, 256 - offsetX, 166 - offsetY);
            CGPathAddLineToPoint(path, NULL, 166 - offsetX, 166 - offsetY);
            CGPathAddLineToPoint(path, NULL, 166 - offsetX, 256 - offsetY);
            CGPathAddLineToPoint(path, NULL, 90 - offsetX, 256 - offsetY);

        } else if ( [tileType isEqualToString:@"bbb_nes_t"]) {
            
            CGPathMoveToPoint(path, NULL, 90 - offsetX, 0 - offsetY);
            CGPathAddLineToPoint(path, NULL, 166 - offsetX, 0 - offsetY);
            CGPathAddLineToPoint(path, NULL, 166 - offsetX, 90 - offsetY);
            CGPathAddLineToPoint(path, NULL, 256 - offsetX, 90 - offsetY);
            CGPathAddLineToPoint(path, NULL, 256 - offsetX, 166 - offsetY);
            CGPathAddLineToPoint(path, NULL, 166 - offsetX, 166 - offsetY);
            CGPathAddLineToPoint(path, NULL, 166 - offsetX, 256 - offsetY);
            CGPathAddLineToPoint(path, NULL, 90 - offsetX, 256 - offsetY);

        } else if ( [tileType isEqualToString:@"bbb_nsw_b"]) {
            
            CGPathMoveToPoint(path, NULL, 0 - offsetX, 90 - offsetY);
            CGPathAddLineToPoint(path, NULL, 90 - offsetX, 90 - offsetY);
            CGPathAddLineToPoint(path, NULL, 90 - offsetX, 0 - offsetY);
            CGPathAddLineToPoint(path, NULL, 166 - offsetX, 0 - offsetY);
            CGPathAddLineToPoint(path, NULL, 166 - offsetX, 256 - offsetY);
            CGPathAddLineToPoint(path, NULL, 90 - offsetX, 256 - offsetY);
            CGPathAddLineToPoint(path, NULL, 90 - offsetX, 166 - offsetY);
            CGPathAddLineToPoint(path, NULL, 0 - offsetX, 166 - offsetY);

        } else if ( [tileType isEqualToString:@"bbb_nsw_t"]) {
            
            CGPathMoveToPoint(path, NULL, 0 - offsetX, 90 - offsetY);
            CGPathAddLineToPoint(path, NULL, 90 - offsetX, 90 - offsetY);
            CGPathAddLineToPoint(path, NULL, 90 - offsetX, 0 - offsetY);
            CGPathAddLineToPoint(path, NULL, 166 - offsetX, 0 - offsetY);
            CGPathAddLineToPoint(path, NULL, 166 - offsetX, 256 - offsetY);
            CGPathAddLineToPoint(path, NULL, 90 - offsetX, 256 - offsetY);
            CGPathAddLineToPoint(path, NULL, 90 - offsetX, 166 - offsetY);
            CGPathAddLineToPoint(path, NULL, 0 - offsetX, 166 - offsetY);
            
        } else if ( [tileType isEqualToString:@"bbb_esw_l"]) {
            
            CGPathMoveToPoint(path, NULL, 0 - offsetX, 90 - offsetY);
            CGPathAddLineToPoint(path, NULL, 90 - offsetX, 90 - offsetY);
            CGPathAddLineToPoint(path, NULL, 90 - offsetX, 0 - offsetY);
            CGPathAddLineToPoint(path, NULL, 166 - offsetX, 0 - offsetY);
            CGPathAddLineToPoint(path, NULL, 166 - offsetX, 90 - offsetY);
            CGPathAddLineToPoint(path, NULL, 256 - offsetX, 90 - offsetY);
            CGPathAddLineToPoint(path, NULL, 256 - offsetX, 166 - offsetY);
            CGPathAddLineToPoint(path, NULL, 0 - offsetX, 166 - offsetY);

        } else if ( [tileType isEqualToString:@"bbb_esw_r"]) {
            
            CGPathMoveToPoint(path, NULL, 0 - offsetX, 90 - offsetY);
            CGPathAddLineToPoint(path, NULL, 90 - offsetX, 90 - offsetY);
            CGPathAddLineToPoint(path, NULL, 90 - offsetX, 0 - offsetY);
            CGPathAddLineToPoint(path, NULL, 166 - offsetX, 0 - offsetY);
            CGPathAddLineToPoint(path, NULL, 166 - offsetX, 90 - offsetY);
            CGPathAddLineToPoint(path, NULL, 256 - offsetX, 90 - offsetY);
            CGPathAddLineToPoint(path, NULL, 256 - offsetX, 166 - offsetY);
            CGPathAddLineToPoint(path, NULL, 0 - offsetX, 166 - offsetY);

        } else if ( [tileType isEqualToString:@"bbb_new_l"]) {
            
            CGPathMoveToPoint(path, NULL, 0 - offsetX, 90 - offsetY);
            CGPathAddLineToPoint(path, NULL, 256 - offsetX, 90 - offsetY);
            CGPathAddLineToPoint(path, NULL, 166 - offsetX, 90 - offsetY);
            CGPathAddLineToPoint(path, NULL, 166 - offsetX, 166 - offsetY);
            CGPathAddLineToPoint(path, NULL, 166 - offsetX, 256 - offsetY);
            CGPathAddLineToPoint(path, NULL, 90 - offsetX, 256 - offsetY);
            CGPathAddLineToPoint(path, NULL, 90 - offsetX, 166 - offsetY);
            CGPathAddLineToPoint(path, NULL, 0 - offsetX, 166 - offsetY);

        } else if ( [tileType isEqualToString:@"bbb_new_r"]) {
            
            CGPathMoveToPoint(path, NULL, 0 - offsetX, 90 - offsetY);
            CGPathAddLineToPoint(path, NULL, 256 - offsetX, 90 - offsetY);
            CGPathAddLineToPoint(path, NULL, 166 - offsetX, 90 - offsetY);
            CGPathAddLineToPoint(path, NULL, 166 - offsetX, 166 - offsetY);
            CGPathAddLineToPoint(path, NULL, 166 - offsetX, 256 - offsetY);
            CGPathAddLineToPoint(path, NULL, 90 - offsetX, 256 - offsetY);
            CGPathAddLineToPoint(path, NULL, 90 - offsetX, 166 - offsetY);
            CGPathAddLineToPoint(path, NULL, 0 - offsetX, 166 - offsetY);
            

            
            
            
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

- (void)rotateInteractives:(CGFloat)degrees {
    // apply the rotation to the sprite
    CGFloat curRotation = [_mapLayerInteractives.userData[@"childRotation"] floatValue];
    
    CGFloat angle = curRotation + DegreesToRadians(degrees);
    
    // wrap angles larger than +/- 360 degrees
    if (angle >= ( 2 * M_PI )) {
        angle -= (2 * M_PI);
    } else if (angle < -(2 * M_PI)) {
        angle += (2 * M_PI);
    }
    
    _mapLayerInteractives.userData[@"childRotation"] = [NSNumber numberWithFloat:angle];

    for (SKNode *child in [_mapLayerInteractives children]) {
        child.zRotation = angle;
    }
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

// Gesture Controls

- (void)handlePan:(UIGestureRecognizer *)recognizer {
    if ([_fuelGauge isOutOfFuel]) { return; }
    
    CGPoint vel = [(UIPanGestureRecognizer *)recognizer velocityInView:self.view]; // negative x if moving to the left; we can ignore the y
    CGPoint trans = [(UIPanGestureRecognizer *)recognizer translationInView:self.view ];
    
#if DEBUG_PLAYER_CONTROL
    _panMover.position = trans;
    _panMover.color = [SKColor whiteColor];
#endif
    
    
    static CGFloat PAN_IDLE_TRANS = 10; // issue #42, handle idle state during pan
    
#if DEBUG_PLAYER_CONTROL
    NSLog(@"handlePan state=%li, velocity=%1.0f,%1.0f, trans=%1.0f,%1.0f",recognizer.state,vel.x,vel.y,trans.x,trans.y);
#endif
    
    // if a Pan gesture has begun, fire up OUR state machine; otherwise pass the current state through
    self.panGestureState = recognizer.state == UIGestureRecognizerStateBegan ? GestureBegan : self.panGestureState;
    
    
    switch (self.panGestureState) {
        case GestureIdle:
            if (fabsf(trans.x) > PAN_IDLE_TRANS) {
                self.panGestureState = GestureBegan;
#if DEBUG_PLAYER_CONTROL
                _panMover.hidden = NO;
                NSLog(@"[GestureIdle] -> [GestureBegan]");
#endif
                
            }
            break;
        
        case GestureBegan:
            if (vel.x < 0) { // LEFT
                self.panGestureState = GestureLeftDown;
                //[_player handleInput:PlayerControlsTurnLeft keyDown:YES];
                [_player setTurnSignalState:PlayerTurnSignalStateLeft];
#if DEBUG_PLAYER_CONTROL
                _panMover.hidden = NO;
                NSLog(@"[GestureBegan] -> [GestureLeftDown]");
#endif
                
                
            } else { // RIGHT
                self.panGestureState = GestureRightDown;
                //[_player handleInput:PlayerControlsTurnRight keyDown:YES];
                [_player setTurnSignalState:PlayerTurnSignalStateRight];
#if DEBUG_PLAYER_CONTROL
                NSLog(@"[GestureBegan] -> [GestureRightDown]");
#endif
                
                
            }
            break;
            
            
        case GestureLeftDown:
            if (recognizer.state == UIGestureRecognizerStateEnded) {
                [_player handleInput:PlayerControlsTurnLeft keyDown:NO]; // fingers up!
                [_player setTurnSignalState:PlayerTurnSignalStateOff];
                break;
            }
            
            if (trans.x <= -PAN_IDLE_TRANS) { // LEFT, with margin of error
                [_player handleInput:PlayerControlsTurnLeft keyDown:YES];
                [_player setTurnSignalState:PlayerTurnSignalStateLeft];
#if DEBUG_PLAYER_CONTROL
                NSLog(@"[GestureLeftDown] LEFT");
#endif
                
                
            } else if (trans.x >= PAN_IDLE_TRANS)  { // RIGHT
                self.panGestureState = GestureRightDown;
                [_player handleInput:PlayerControlsTurnRight keyDown:YES];
                [_player setTurnSignalState:PlayerTurnSignalStateRight];
#if DEBUG_PLAYER_CONTROL
                NSLog(@"[GestureLeftDown] RIGHT");
#endif
                
        
            } else { // IDLE
                self.panGestureState = GestureIdle;
                [_player handleInput:PlayerControlsTurnLeft keyDown:NO]; // fingers up!
                [_player setTurnSignalState:PlayerTurnSignalStateOff];
#if DEBUG_PLAYER_CONTROL
                NSLog(@"[GestureLeftDown] IDLE");
                _panMover.color = [SKColor greenColor];
#endif
                
                
            }
            break;
            
        case GestureLeftUp:
            // should never be called; transition will be handled by LeftDown
            break;
            
        case GestureRightDown:
            if (recognizer.state == UIGestureRecognizerStateEnded) {
                [_player handleInput:PlayerControlsTurnRight keyDown:NO]; // fingers up!
                [_player setTurnSignalState:PlayerTurnSignalStateOff];
                break;
            }
            
            if (trans.x >= PAN_IDLE_TRANS) { // RIGHT, with margin of error
                [_player handleInput:PlayerControlsTurnRight keyDown:YES];
                [_player setTurnSignalState:PlayerTurnSignalStateRight];
#if DEBUG_PLAYER_CONTROL
                NSLog(@"[GestureLeftDown] RIGHT");
#endif
                
                
            } else if (trans.x <= -PAN_IDLE_TRANS)  { // LEFT
                self.panGestureState = GestureLeftDown;
                [_player handleInput:PlayerControlsTurnLeft keyDown:YES];
                [_player setTurnSignalState:PlayerTurnSignalStateLeft];
#if DEBUG_PLAYER_CONTROL
                NSLog(@"[GestureLeftDown] LEFT");
#endif
                
                
            } else { // IDLE
                self.panGestureState = GestureIdle;
                [_player handleInput:PlayerControlsTurnRight keyDown:NO]; // fingers up!
                [_player setTurnSignalState:PlayerTurnSignalStateOff];
#if DEBUG_PLAYER_CONTROL
                NSLog(@"[GestureLeftDown] IDLE");
                _panMover.color = [SKColor greenColor];
#endif
                
                
            }


            break;
            
        case GestureRightUp:
            // should never be called; transition will be handled by RightDown
            break;
        
    }
    
}

- (void)gameOverBecause:(GameOverReason)reason {
    
    switch (reason) {
        case GameOverReasonOutOfFuel:
            [_scoreKeeper handleEventOutOfFuel];
            break;
            
        case GameOverReasonOutOfTime:
            [_scoreKeeper handleEventOutOfTime];
            break;
            
        case GameOverReasonSavedEveryone:
            [_scoreKeeper handleEventSavedEveryone];
            break;
            
    }

    [_player stopMovingWithDecelTime:1.0];
    [_gameClock pauseTimer];
    
    SKAction *runGameOver =
    [SKAction sequence:@[
        [SKAction waitForDuration:3.0],
        [SKAction runBlock:^(void)
         {
             SKScene *gameOverScene = [[AMBGameOver alloc]initWithSize:self.size scoreKeeper:_scoreKeeper];
             gameOverScene.scaleMode = SKSceneScaleModeAspectFit;
             [self.view presentScene:gameOverScene transition:[SKTransition fadeWithColor:[SKColor whiteColor] duration:0.25]];
          }]]];
    [self runAction:runGameOver];
    
}

- (void)handleTap:(UIGestureRecognizer *)recognizer {
    if ([_fuelGauge isOutOfFuel]) { return; }
    // two taps, start/stop moving
//#if DEBUG_PLAYER_CONTROL
//    NSLog(@"handleTap");
//#endif
    
    if (_player.isMoving) {
        [_player handleInput:PlayerControlsStopMoving keyDown:YES];
    } else {
        [_player handleInput:PlayerControlsStartMoving keyDown:YES];
    }


}

- (void)handleLongPress:(UIGestureRecognizer *)recognizer {
    if ([_fuelGauge isOutOfFuel]) { return; }    
    // will be called multiple times after the gesture is recognized.
    // you can query the recognizer's state to respond to specific events.

    // state 1=began    state 3=ended
    //NSLog(@"handleLongPress state=%li",recognizer.state );
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        [_player adjustSpeedToTarget: 150];
        [self.tutorialOverlay playerDidPerformEvent:PlayerEventSlowDown]; // tutorial event
        
    } else if (recognizer.state == UIGestureRecognizerStateEnded) {
        [_player adjustSpeedToTarget:_player.nativeSpeed];
    }
    

 
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
