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

-(void) updateCars {
    double curTime = CACurrentMediaTime();//returns the current absolute time in seconds
    if (curTime > _nextCarSpawn) {
        //NSLog(@"spawning new asteroid");
        float randSecs = [self randomValueBetween:0.20 andValue:1.0];//Creates a randome value to space out when cars appear
        _nextCarSpawn = randSecs + curTime;//time until next car spawns, look at the if statment for why this is relivent
        
        SKSpriteNode *car = [_cars objectAtIndex:_nextCar];//Selects the next car in the list, starts at 0
        _nextCar++;//Incraments up the next car in the list.  So that next time the loop is called this appears.
        
        if (_nextCar >= _cars.count) {//Checks to see that the number of cars has not exceeded the total number of cars in the m-array
            _nextCar = 0;//If it has reset it to 0 and start from the front of the list
        }
        
        [car removeAllActions];//Clears out the old actions so that they dont gum up the works.
        float randDuration = [self randomValueBetween:2.0 andValue:10.0];//Car speed
        CGPoint location;
        
        if ((_player.direction.x == 0.0 && _player.direction.y == 1.0)) {//up
            float randx = [self randomValueBetween:-self.frame.size.width andValue:self.frame.size.width];//Cars appear somewhere on the right side of the screen
            
            car.position = CGPointMake(randx, self.frame.size.height+car.size.height/2);//Place the car on the far right side.  Plus its width(devided in half because it has been scalled in half).  This means it appears offscreen.  Se randY for meaning.
            car.hidden = NO;//Unhide the car
            
            location = CGPointMake(randx, -self.frame.size.height-car.size.height);//sets the desctination for the oposite side of the screen, hence all those negatives.  In addition to this it subtracts the width of the car, so that it doesn't disapear until it compleatly falls off the screen.
        }else if(_player.direction.x == -1.0 && _player.direction.y == 0.0){//left
            float randY = [self randomValueBetween:0.0 andValue:self.frame.size.height];//Cars appear somewhere on the right side of the screen
            
            car.position = CGPointMake(-self.frame.size.width-car.size.width, randY);//Place the car on the far right side.  Plus its width(devided in half because it has been scalled in half).  This means it appears offscreen.  Se randY for meaning.
            car.hidden = NO;//Unhide the car
            
            location = CGPointMake(self.frame.size.width+car.size.width/2 , randY);//sets the desctination for the oposite side of the screen, hence all those negatives.  In addition to this it subtracts the width of the car, so that it doesn't disapear until it compleatly falls off the screen.
        }else if (_player.direction.x == 0.0 && _player.direction.y == -1.0){//down
            float randx = [self randomValueBetween:-self.frame.size.width andValue:self.frame.size.width];//Cars appear somewhere on the right side of the screen
            
            car.position = CGPointMake(randx, -self.frame.size.height-car.size.height);//Place the car on the far right side.  Plus its width(devided in half because it has been scalled in half).  This means it appears offscreen.  Se randY for meaning.
            car.hidden = NO;//Unhide the car
            
            location = CGPointMake(randx, self.frame.size.height+car.size.height/2);//sets the desctination for the oposite side of the screen, hence all those negatives.  In addition to this it subtracts the width of the car, so that it doesn't disapear until it compleatly falls off the screen.ddition to this it subtracts the width of the car, so that it doesn't disapear until it compleatly falls off the screen.
        }else if (_player.direction.x == 1.0 && _player.direction.y == 0.0){//right
            float randY = [self randomValueBetween:0.0 andValue:self.frame.size.height];//Cars appear somewhere on the right side of the screen
            
            car.position = CGPointMake(self.frame.size.width+car.size.width/2, randY);//Place the car on the far right side.  Plus its width(devided in half because it has been scalled in half).  This means it appears offscreen.  Se randY for meaning.
            car.hidden = NO;//Unhide the car
            
            location = CGPointMake(-self.frame.size.width-car.size.width, randY);//sets the desctination for the oposite side of the screen, hence all those negatives.  In addition to this it subtracts the width of the car, so that it doesn't disapear until it compleatly falls off the screen.
        }
        
        
        
        SKAction *moveAction = [SKAction moveTo:location duration:randDuration];//Actually create the action, moving image from A to B.
        SKAction *doneAction = [SKAction runBlock:(dispatch_block_t)^() {//I think this creates a thread to cause the car to hide when it reaches the end of the screen.
            //NSLog(@"Animation Completed");
            car.hidden = YES;
        }];
        
        SKAction *moveCarActionWithDone = [SKAction sequence:@[moveAction, doneAction ]];
        [car runAction:moveCarActionWithDone withKey:@"carMoving"];
    }
    
    
    
}

- (void) addPlayer {
    
    _player = [[AMBPlayer alloc] init];
    _player.position = CGPointMake(_playerSpawnPoint.x - 32, _playerSpawnPoint.y); // TODO: don't hardcode this offset!

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
    
    [_player updateWithTimeSinceLastUpdate:self.sceneDelta];


    [self centerOnNode:_player];
    
    
    _currentTileGid = [_mapLayerRoad tileGidAt:_player.position];

    
    // update the spawners
    // TODO: should this be part of the spawner class?
    [_spawners enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        AMBSpawner *spawnerObj = (AMBSpawner *)obj;
        [spawnerObj updateWithTimeSinceLastUpdate:_sceneDelta];
    }];
    
// commented out during patient testing
//    [self updateCars];

    // update all visible patients
    [_tilemap enumerateChildNodesWithName:@"patient" usingBlock:^(SKNode *node, BOOL *stop) {
        AMBPatient *patientNode = (AMBPatient *)node;
        [patientNode updatePatient];
    }];
    
    
    // test turn
    if (_turnRequested && self.sceneLastUpdate - _lastKeyPress < KEY_PRESS_INTERVAL_SECS ) {
        NSLog(@" Can I turn now?");
        [self authorizeTurnEvent:_turnDegrees];
    }

}

#pragma mark World Building
- (void)createWorld {
    
    _worldNode = [SKNode node];
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
        
        if (        [tileType isEqualToString:@"ew"]) {
            
            CGPathMoveToPoint(path, NULL, 0 - offsetX, 65 - offsetY);
            CGPathAddLineToPoint(path, NULL, 256 - offsetX, 65 - offsetY);
            CGPathAddLineToPoint(path, NULL, 256 - offsetX, 185 - offsetY);
            CGPathAddLineToPoint(path, NULL, 0 - offsetX, 185 - offsetY);
            
        } else if ( [tileType isEqualToString:@"nesw"]) {
            
            CGPathMoveToPoint(path, NULL, 65 - offsetX, 0 - offsetY);
            CGPathAddLineToPoint(path, NULL, 185 - offsetX, 0 - offsetY);
            CGPathAddLineToPoint(path, NULL, 185 - offsetX, 65 - offsetY);
            CGPathAddLineToPoint(path, NULL, 256 - offsetX, 65 - offsetY);
            CGPathAddLineToPoint(path, NULL, 256 - offsetX, 185 - offsetY);
            CGPathAddLineToPoint(path, NULL, 185 - offsetX, 185 - offsetY);
            CGPathAddLineToPoint(path, NULL, 185 - offsetX, 256 - offsetY);
            CGPathAddLineToPoint(path, NULL, 65 - offsetX, 256 - offsetY);
            CGPathAddLineToPoint(path, NULL, 65 - offsetX, 185 - offsetY);
            CGPathAddLineToPoint(path, NULL, 0 - offsetX, 185 - offsetY);
            CGPathAddLineToPoint(path, NULL, 0 - offsetX, 65 - offsetY);
            CGPathAddLineToPoint(path, NULL, 65 - offsetX, 65 - offsetY);
            
            
            
        } else if ( [tileType isEqualToString:@"ns"]) {
            
            CGPathMoveToPoint(path, NULL, 65 - offsetX, 0 - offsetY);
            CGPathAddLineToPoint(path, NULL, 185 - offsetX, 0 - offsetY);
            CGPathAddLineToPoint(path, NULL, 185 - offsetX, 256 - offsetY);
            CGPathAddLineToPoint(path, NULL, 65 - offsetX, 256 - offsetY);
            
        } else if ( [tileType isEqualToString:@"ne"]) {
            
            CGPathMoveToPoint(path, NULL, 65 - offsetX, 65 - offsetY);
            CGPathAddLineToPoint(path, NULL, 256 - offsetX, 65 - offsetY);
            CGPathAddLineToPoint(path, NULL, 256 - offsetX, 185 - offsetY);
            CGPathAddLineToPoint(path, NULL, 185 - offsetX, 185 - offsetY);
            CGPathAddLineToPoint(path, NULL, 185 - offsetX, 256 - offsetY);
            CGPathAddLineToPoint(path, NULL, 65 - offsetX, 256 - offsetY);
            
        } else if ( [tileType isEqualToString:@"nw"]) {
            
            CGPathMoveToPoint(path, NULL, 0 - offsetX, 65 - offsetY);
            CGPathAddLineToPoint(path, NULL, 185 - offsetX, 65 - offsetY);
            CGPathAddLineToPoint(path, NULL, 185 - offsetX, 256 - offsetY);
            CGPathAddLineToPoint(path, NULL, 65 - offsetX, 256 - offsetY);
            CGPathAddLineToPoint(path, NULL, 65 - offsetX, 185 - offsetY);
            CGPathAddLineToPoint(path, NULL, 0 - offsetX, 185 - offsetY);
            
        } else if ( [tileType isEqualToString:@"es"]) {
            
            CGPathMoveToPoint(path, NULL, 65 - offsetX, 0 - offsetY);
            CGPathAddLineToPoint(path, NULL, 185 - offsetX, 0 - offsetY);
            CGPathAddLineToPoint(path, NULL, 185 - offsetX, 65 - offsetY);
            CGPathAddLineToPoint(path, NULL, 256 - offsetX, 65 - offsetY);
            CGPathAddLineToPoint(path, NULL, 256 - offsetX, 185 - offsetY);
            CGPathAddLineToPoint(path, NULL, 65 - offsetX, 185 - offsetY);
            
        } else if ( [tileType isEqualToString:@"sw"]) {
            
            CGPathMoveToPoint(path, NULL, 65 - offsetX, 0 - offsetY);
            CGPathAddLineToPoint(path, NULL, 185 - offsetX, 0 - offsetY);
            CGPathAddLineToPoint(path, NULL, 185 - offsetX, 185 - offsetY);
            CGPathAddLineToPoint(path, NULL, 0 - offsetX, 185 - offsetY);
            CGPathAddLineToPoint(path, NULL, 0 - offsetX, 65 - offsetY);
            CGPathAddLineToPoint(path, NULL, 65 - offsetX, 65 - offsetY);
            
        } else if ( [tileType isEqualToString:@"nes"]) {
            
            CGPathMoveToPoint(path, NULL, 65 - offsetX, 0 - offsetY);
            CGPathAddLineToPoint(path, NULL, 185 - offsetX, 0 - offsetY);
            CGPathAddLineToPoint(path, NULL, 185 - offsetX, 65 - offsetY);
            CGPathAddLineToPoint(path, NULL, 256 - offsetX, 65 - offsetY);
            CGPathAddLineToPoint(path, NULL, 256 - offsetX, 185 - offsetY);
            CGPathAddLineToPoint(path, NULL, 185 - offsetX, 185 - offsetY);
            CGPathAddLineToPoint(path, NULL, 185 - offsetX, 256 - offsetY);
            CGPathAddLineToPoint(path, NULL, 65 - offsetX, 256 - offsetY);
            
        } else if ( [tileType isEqualToString:@"new"]) {
            
            CGPathMoveToPoint(path, NULL, 0 - offsetX, 65 - offsetY);
            CGPathAddLineToPoint(path, NULL, 256 - offsetX, 65 - offsetY);
            CGPathAddLineToPoint(path, NULL, 185 - offsetX, 65 - offsetY);
            CGPathAddLineToPoint(path, NULL, 185 - offsetX, 185 - offsetY);
            CGPathAddLineToPoint(path, NULL, 185 - offsetX, 256 - offsetY);
            CGPathAddLineToPoint(path, NULL, 65 - offsetX, 256 - offsetY);
            CGPathAddLineToPoint(path, NULL, 65 - offsetX, 185 - offsetY);
            CGPathAddLineToPoint(path, NULL, 0 - offsetX, 185 - offsetY);
            
        } else if ( [tileType isEqualToString:@"nsw"]) {
            
            CGPathMoveToPoint(path, NULL, 0 - offsetX, 65 - offsetY);
            CGPathAddLineToPoint(path, NULL, 65 - offsetX, 65 - offsetY);
            CGPathAddLineToPoint(path, NULL, 65 - offsetX, 0 - offsetY);
            CGPathAddLineToPoint(path, NULL, 185 - offsetX, 0 - offsetY);
            CGPathAddLineToPoint(path, NULL, 185 - offsetX, 256 - offsetY);
            CGPathAddLineToPoint(path, NULL, 65 - offsetX, 256 - offsetY);
            CGPathAddLineToPoint(path, NULL, 65 - offsetX, 185 - offsetY);
            CGPathAddLineToPoint(path, NULL, 0 - offsetX, 185 - offsetY);
            
        } else if ( [tileType isEqualToString:@"esw"]) {
            
            CGPathMoveToPoint(path, NULL, 0 - offsetX, 65 - offsetY);
            CGPathAddLineToPoint(path, NULL, 65 - offsetX, 65 - offsetY);
            CGPathAddLineToPoint(path, NULL, 65 - offsetX, 0 - offsetY);
            CGPathAddLineToPoint(path, NULL, 185 - offsetX, 0 - offsetY);
            CGPathAddLineToPoint(path, NULL, 185 - offsetX, 65 - offsetY);
            CGPathAddLineToPoint(path, NULL, 256 - offsetX, 65 - offsetY);
            CGPathAddLineToPoint(path, NULL, 256 - offsetX, 185 - offsetY);
            CGPathAddLineToPoint(path, NULL, 0 - offsetX, 185 - offsetY);
            
        } else if ( [tileType isEqualToString:@"b_ns_l"]) {
            CGPathMoveToPoint(path, NULL, 65 - offsetX, 0 - offsetY);
            CGPathAddLineToPoint(path, NULL, 256 - offsetX, 0 - offsetY);
            CGPathAddLineToPoint(path, NULL, 256 - offsetX, 256 - offsetY);
            CGPathAddLineToPoint(path, NULL, 65 - offsetX, 256 - offsetY);
            
        } else if ( [tileType isEqualToString:@"b_ns_r"]) {
            CGPathMoveToPoint(path, NULL, 0 - offsetX, 0 - offsetY);
            CGPathAddLineToPoint(path, NULL, 185 - offsetX, 0 - offsetY);
            CGPathAddLineToPoint(path, NULL, 185 - offsetX, 256 - offsetY);
            CGPathAddLineToPoint(path, NULL, 0 - offsetX, 256 - offsetY);
            
        } else if ( [tileType isEqualToString:@"b_nsw"]) {
            CGPathMoveToPoint(path, NULL, 0 - offsetX, 65 - offsetY);
            CGPathAddLineToPoint(path, NULL, 65 - offsetX, 65 - offsetY);
            CGPathAddLineToPoint(path, NULL, 65 - offsetX, 0 - offsetY);
            CGPathAddLineToPoint(path, NULL, 256 - offsetX, 0 - offsetY);
            CGPathAddLineToPoint(path, NULL, 256 - offsetX, 256 - offsetY);
            CGPathAddLineToPoint(path, NULL, 65 - offsetX, 256 - offsetY);
            CGPathAddLineToPoint(path, NULL, 65 - offsetX, 185 - offsetY);
            CGPathAddLineToPoint(path, NULL, 0 - offsetX, 185 - offsetY);

        } else if ( [tileType isEqualToString:@"b_nes"]) {
            CGPathMoveToPoint(path, NULL, 0 - offsetX, 0 - offsetY);
            CGPathAddLineToPoint(path, NULL, 185 - offsetX, 0 - offsetY);
            CGPathAddLineToPoint(path, NULL, 185 - offsetX, 65 - offsetY);
            CGPathAddLineToPoint(path, NULL, 256 - offsetX, 65 - offsetY);
            CGPathAddLineToPoint(path, NULL, 256 - offsetX, 185 - offsetY);
            CGPathAddLineToPoint(path, NULL, 185 - offsetX, 185 - offsetY);
            CGPathAddLineToPoint(path, NULL, 185 - offsetX, 256 - offsetY);
            CGPathAddLineToPoint(path, NULL, 0 - offsetX, 256 - offsetY);
            
        } else if ( [tileType isEqualToString:@"b_ew_t"]) {
            CGPathMoveToPoint(path, NULL, 0 - offsetX, 0 - offsetY);
            CGPathAddLineToPoint(path, NULL, 256 - offsetX, 0 - offsetY);
            CGPathAddLineToPoint(path, NULL, 256 - offsetX, 185 - offsetY);
            CGPathAddLineToPoint(path, NULL, 0 - offsetX, 185 - offsetY);
            
        } else if ( [tileType isEqualToString:@"b_new"]) {
            CGPathMoveToPoint(path, NULL, 0 - offsetX, 0 - offsetY);
            CGPathAddLineToPoint(path, NULL, 256 - offsetX, 0 - offsetY);
            CGPathAddLineToPoint(path, NULL, 256 - offsetX, 185 - offsetY);
            CGPathAddLineToPoint(path, NULL, 185 - offsetX, 185 - offsetY);
            CGPathAddLineToPoint(path, NULL, 185 - offsetX, 256 - offsetY);
            CGPathAddLineToPoint(path, NULL, 65 - offsetX, 256 - offsetY);
            CGPathAddLineToPoint(path, NULL, 65 - offsetX, 185 - offsetY);
            CGPathAddLineToPoint(path, NULL, 0 - offsetX, 185 - offsetY);
            
        } else if ( [tileType isEqualToString:@"bb_new_l"]) {
            CGPathMoveToPoint(path, NULL, 0 - offsetX, 0 - offsetY);
            CGPathAddLineToPoint(path, NULL, 256 - offsetX, 0 - offsetY);
            CGPathAddLineToPoint(path, NULL, 256 - offsetX, 256 - offsetY);
            CGPathAddLineToPoint(path, NULL, 65 - offsetX, 256 - offsetY);
            CGPathAddLineToPoint(path, NULL, 65 - offsetX, 185 - offsetY);
            CGPathAddLineToPoint(path, NULL, 0 - offsetX, 185 - offsetY);
        } else if ( [tileType isEqualToString:@"bb_new_r"]) {
            CGPathMoveToPoint(path, NULL, 0 - offsetX, 0 - offsetY);
            CGPathAddLineToPoint(path, NULL, 256 - offsetX, 0 - offsetY);
            CGPathAddLineToPoint(path, NULL, 256 - offsetX, 185 - offsetY);
            CGPathAddLineToPoint(path, NULL, 185 - offsetX, 185 - offsetY);
            CGPathAddLineToPoint(path, NULL, 185 - offsetX, 256 - offsetY);
            CGPathAddLineToPoint(path, NULL, 0 - offsetX, 256 - offsetY);
        } else if ( [tileType isEqualToString:@"bb_esw_l"]) {
            CGPathMoveToPoint(path, NULL, 65 - offsetX, 0 - offsetY);
            CGPathAddLineToPoint(path, NULL, 256 - offsetX, 0 - offsetY);
            CGPathAddLineToPoint(path, NULL, 256 - offsetX, 256 - offsetY);
            CGPathAddLineToPoint(path, NULL, 0 - offsetX, 256 - offsetY);
            CGPathAddLineToPoint(path, NULL, 0 - offsetX, 65 - offsetY);
            CGPathAddLineToPoint(path, NULL, 65 - offsetX, 65 - offsetY);
        } else if ( [tileType isEqualToString:@"bb_esw_r"]) {
            CGPathMoveToPoint(path, NULL, 0 - offsetX, 0 - offsetY);
            CGPathAddLineToPoint(path, NULL, 185 - offsetX, 0 - offsetY);
            CGPathAddLineToPoint(path, NULL, 185 - offsetX, 65 - offsetY);
            CGPathAddLineToPoint(path, NULL, 256 - offsetX, 65 - offsetY);
            CGPathAddLineToPoint(path, NULL, 256 - offsetX, 256 - offsetY);
            CGPathAddLineToPoint(path, NULL, 0 - offsetX, 256 - offsetY);
        } else if ( [tileType isEqualToString:@"b_ew_b"]) {
            CGPathMoveToPoint(path, NULL, 0 - offsetX, 65 - offsetY);
            CGPathAddLineToPoint(path, NULL, 256 - offsetX, 65 - offsetY);
            CGPathAddLineToPoint(path, NULL, 256 - offsetX, 256 - offsetY);
            CGPathAddLineToPoint(path, NULL, 0 - offsetX, 256 - offsetY);
        } else if ( [tileType isEqualToString:@"b_esw"]) {
            CGPathMoveToPoint(path, NULL, 0 - offsetX, 65 - offsetY);
            CGPathAddLineToPoint(path, NULL, 65 - offsetX, 65 - offsetY);
            CGPathAddLineToPoint(path, NULL, 65 - offsetX, 0 - offsetY);
            CGPathAddLineToPoint(path, NULL, 185 - offsetX, 0 - offsetY);
            CGPathAddLineToPoint(path, NULL, 185 - offsetX, 65 - offsetY);
            CGPathAddLineToPoint(path, NULL, 256 - offsetX, 65 - offsetY);
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
        NSLog(@"at hospital");
#endif
    }
    
    
}


- (void)authorizeTurnEvent: (CGFloat)degrees {
    /* Called directly by user input. Evaluates the player's current position, and executes a turn only if it ends on a road tile. */
    
    SKSpriteNode *currentTile = [_mapLayerRoad tileAt:_player.position];
    NSDictionary *currentTileProperties = [_tilemap propertiesForGid:[_mapLayerRoad tileGidAt:_player.position]];
    NSString *currentTileType = currentTileProperties[@"road"];
    CGPoint playerPosInTile = [currentTile convertPoint:_player.position fromNode:_tilemap];

    CGPoint targetPoint; // the result of this tile calculation below
    CGVector targetOffset; // how much we need to move over to get into the next lane
    
    if (currentTileProperties[@"intersection"]) {
        // begin by modeling the requested turn from the player's current position; return a target point
        CGFloat rads = DegreesToRadians(degrees);
        CGFloat newAngle = _player.zRotation + rads; // the angle the player will face after the turn
        
        CGFloat playerWidth = [self calculatePlayerWidth];
        
        CGPoint directionNormalized = CGPointNormalize(_player.direction);
        CGPoint rotatedPointNormalized = CGPointRotate(directionNormalized, degrees);
        CGPoint rotatedPoint = CGPointMultiplyScalar(rotatedPointNormalized, playerWidth);
        
        targetPoint = CGPointAdd(rotatedPoint, _player.position);
        
        
    } else { // lane changes
        CGPoint laneChangeVector = CGPointMultiplyScalar(  CGPointRotate(_player.direction, degrees) , TILE_LANE_WIDTH*2); // lane width * 2 because we're in the center of a lane and need to get across to the next one

        CGFloat angle = RadiansToDegrees(CGPointToAngle(laneChangeVector));
        NSInteger remainder;
        
        /*
         remainder (
         remainder = playerPosInTile + laneChange % TILE_LANE_WIDTH
         */

        NSInteger pos;  // the player's position in the tile, either the x or the y value
        NSInteger lane; // the lane change vector, either the x or the y value
        NSInteger coordPoint; // the resulting point for targetPoint; calculated differently depending on whether we're moving left/up or right/down
        
        
        if (fabsf(laneChangeVector.x) > fabsf(laneChangeVector.y)) {
            pos     = (int)playerPosInTile.x;
            lane    = (int)laneChangeVector.x;
            
        } else {
            pos     = (int)playerPosInTile.y;
            lane    = (int)laneChangeVector.y;
        }

        // calculate remainder; how far are we going to overshoot the next lane?
        remainder = (pos + lane) % TILE_LANE_WIDTH;
        
        if (angle > -1 ) {
            // positive
            coordPoint = pos + TILE_LANE_WIDTH*2 - remainder;
            
        } else {
            // negative
            coordPoint = pos - remainder;
            
        }
        
        targetPoint = CGPointMultiply(CGPointMake(coordPoint, coordPoint), CGPointRotate(_player.direction, degrees)); // multiplying the coordPoint against the direction should produce a vector in the correct direction
        
        
        targetOffset = CGVectorMake(targetPoint.x - playerPosInTile.x, 0);
        
        
        targetPoint = [_tilemap convertPoint:targetPoint fromNode:currentTile]; // convert target point back to real world coords
        
        

        
    }

    
    // with the target point, get the target tile and determine a) if it's a road tile, and b) if the point within the road tile is a road surface (and not the border)
    SKSpriteNode *targetTile = [_mapLayerRoad tileAt:targetPoint]; // gets the the tile object being considered for the turn
    NSString *targetTileRoadType = [_tilemap propertiesForGid:  [_mapLayerRoad tileGidAt:targetPoint]  ][@"road"];
    
    CGPoint positionInTargetTile = [targetTile convertPoint:targetPoint fromNode:_tilemap]; // the position of the target within the target tile
    
    CGPoint playerInTile = [currentTile convertPoint:_player.position fromNode:_tilemap];
    currentTile.color = [SKColor yellowColor];
    //NSLog(@"playerInTile = %1.0f,%1.0f",playerInTile.x,playerInTile.y);
    
#if DEBUG
    SKSpriteNode *targetPointSprite = [SKSpriteNode spriteNodeWithColor:[SKColor redColor] size:CGSizeMake(10, 10)];
    targetPointSprite.name = @"DEBUG_targetPointSprite";
    targetPointSprite.position = positionInTargetTile;
    targetPointSprite.zPosition = targetTile.zPosition + 1;
    [targetTile addChild:targetPointSprite];
    [targetPointSprite runAction:[SKAction sequence:@[[SKAction waitForDuration:3],[SKAction removeFromParent]]]];
    
    NSLog(@"targetTileRoadType = %@", targetTileRoadType);
#endif
    
    
    if (targetTileRoadType) {
        // check the coordinates to make sure it's on ROAD SURFACE within the tile
        
        CGPathRef path = (__bridge CGPathRef)([roadTilePaths objectForKey:targetTileRoadType]); // TODO: memory leak because of bridging?
        
        BOOL isWithinBounds = CGPathContainsPoint(path, NULL, positionInTargetTile, FALSE);
        
        if (isWithinBounds) { // if the point is within the bounding path..
            if (currentTileProperties[@"intersection"]) {
                [_player rotateByAngle:degrees];
            } else {
#if DEBUG
                NSLog(@"changing lanes by %1.0f,%1.0f",targetOffset.dx,targetOffset.dy);
#endif
                [_player runAction:[SKAction moveBy:targetOffset duration:0.25]];
            }
            _turnRequested = NO;
            
            
#if DEBUG
            NSLog(@"turn initiated while on tile %@",currentTileType);
#endif
        } else {
            // stash the turn request
            _turnRequested = YES;
            _turnDegrees = degrees;
        }
        
#if DEBUG
        if (isWithinBounds) {
            targetPointSprite.color = [SKColor blueColor];
        }
        
        SKShapeNode *bounds = [SKShapeNode node];
        bounds.path = path;
        bounds.fillColor = [SKColor whiteColor];
        bounds.alpha = 0.5;
        bounds.zPosition = targetPointSprite.zPosition - 1;
        
        [targetTile addChild:bounds];
        [bounds runAction:[SKAction sequence:@[[SKAction waitForDuration:1],[SKAction removeFromParent]]]];
#endif
        
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
                    [self authorizeTurnEvent:90];
                    
                    break;
                    
                case NSRightArrowFunctionKey:
                    [self authorizeTurnEvent:-90];
                    
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
