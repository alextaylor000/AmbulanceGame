//
//  XXXMyScene.m
//  CharacterTests
//
//  Created by Alex Taylor on 2014-07-06.
//  Copyright (c) 2014 Alex Taylor. All rights reserved.
//

#import "XXXMyScene.h"
#import "XXXCharacter.h"
#import "XXXPatient.h"
#import "XXXScoreKeeper.h"
#import "Tilemap.h"     // for supporting ASCII maps
#import "JSTilemap.h"   // for supporting TMX maps
#import "SKTUtils.h"

#define kNumberCars   15

static const float KEY_PRESS_INTERVAL_SECS = 0.25; // ignore key presses more frequent than this interval

@interface XXXMyScene ()

@property NSTimeInterval lastUpdateTimeInterval;
@property NSTimeInterval lastKeyPress;
@property SKNode *worldNode;
@property JSTileMap *bgLayer;
@property XXXCharacter *player;


@property TMXLayer *roadLayer;
@property TMXObjectGroup *spawnPoints;
@property CGPoint playerSpawnPoint;
@property NSInteger currentTileGid;


@end

@implementation XXXMyScene{
    
    NSMutableArray *_cars;
    XXXScoreKeeper *scoreKeeper;
    int _nextCar;
    double _nextCarSpawn;
    
}

-(id)initWithSize:(CGSize)size {    
    if (self = [super initWithSize:size]) {

        /* Setup your scene here */
        
        self.backgroundColor = [SKColor colorWithRed:0.15 green:0.15 blue:0.3 alpha:1.0];
        self.anchorPoint = CGPointMake(0.5, 0.5);
        self.physicsWorld.gravity = CGVectorMake(0, 0);

        self.physicsWorld.contactDelegate = self;
        
        // Add score object
        scoreKeeper = [XXXScoreKeeper sharedInstance];

        
        [self createWorld];
        
        
        [self addPlayer];

// commented out during patient testing
//        [self addCars];//Adds inital enamies to the screen
//        [self initalizeCarVariables];
        
        
        
        
#if DEBUG
        NSLog(@"[[   SCORE:  %ld   ]]", scoreKeeper.score);
#endif
        
        // Add score label
        SKLabelNode *labelScore = [scoreKeeper createScoreLabelWithPoints:0 atPos:CGPointMake(self.size.width/2 - 250, self.size.height/2-50)];
        [self addChild:labelScore];
        
        
    }
    return self;
}


- (void) addPatientSeverity:(PatientSeverity)severity atPoint:(CGPoint)point {
    CGPoint patientPosition = point;
    XXXPatient *patient = [[XXXPatient alloc]initWithSeverity:severity position:patientPosition];
    [_bgLayer addChild:patient];
}


- (void) addHospitalAtPoint:(CGPoint)point {
    // adds a hospital at the tilemap coordinates specified.
    SKSpriteNode *hospital = [SKSpriteNode spriteNodeWithImageNamed:@"hospital"];
    hospital.position = point;
    hospital.zPosition = 200;
    hospital.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:CGSizeMake(hospital.size.width * 3, hospital.size.height * 3)]; // for the physics body, expand the hospital's size so that it encompasses all the surrounding road blocks.
    hospital.physicsBody.categoryBitMask = categoryHospital;
    hospital.physicsBody.collisionBitMask = 0x00000000;
    
    [_bgLayer addChild:hospital];
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
    _player = [[XXXCharacter alloc] init];
    
    CGPoint spawnPoint = [_roadLayer pointForCoord:CGPointMake(35, 12)];
    
    _player.position = _playerSpawnPoint;
    
#if DEBUG
    NSLog(@"adding player at %1.0f,%1.0f",_playerSpawnPoint.x,_playerSpawnPoint.y);
#endif
    
    [_bgLayer addChild:_player];
    
    
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
    
    
    _currentTileGid = [_roadLayer tileGidAt:_player.position];

    
// commented out during patient testing
//    [self updateCars];

    // update all visible patients
    [_bgLayer enumerateChildNodesWithName:@"patient" usingBlock:^(SKNode *node, BOOL *stop) {
        XXXPatient *patientNode = (XXXPatient *)node;
        [patientNode updatePatient];
    }];
    

}

#pragma mark Tilemap stuff

- (void)createWorld {
    
    _worldNode = [SKNode node];

    [self addChild:_worldNode];
    
    _bgLayer = [JSTileMap mapNamed:@"road-map-01_with_spawn_points.tmx"];
    _roadLayer = [_bgLayer layerNamed:@"road-tiles"];
    _spawnPoints = [_bgLayer groupNamed:@"spawns"];
    
    if (_bgLayer) {
        
        [_worldNode addChild:_bgLayer];
    }
    
    // Get player spawn point
    NSDictionary *playerSpawn = [_spawnPoints objectNamed:@"player.spawn"];
    
    _playerSpawnPoint = [self centerOfObject:playerSpawn];
    
    // Get hospital spawn points
    NSArray *hospitalSpawns = [_spawnPoints objectsNamed:@"hospital"];
    for (NSDictionary *object in hospitalSpawns) {
        [self addHospitalAtPoint:[self centerOfObject:object]];
    }
    
    // Get patient spawn points
    // TODO: these spawn points would probably spawn patients at a random interval, and possibly a random severity level, depending on how we want to do it.
    NSArray *patientSpawns = [_spawnPoints objectsNamed:@"patient"];
    for (NSDictionary *object in patientSpawns) {
//        [self addPatientSeverity: atPoint:<#(CGPoint)#>]
    }
    
}

-(CGPoint)centerOfObject:(NSDictionary *)object {
    /* Calculates the center point of a TMX Object based on the x/y offset and size. */
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

- (void) rotateViewBy: (CGFloat)rotationDegrees {
    // this seems vey jerky when the rotation happens.
    CGFloat duration = (fabsf(rotationDegrees) / _player.CHARACTER_ROTATION_DEGREES_PER_SEC) * 1.05; // based on the speed of the player's rotation, how long will it take to rotate the target amount? This syncs the camera rotation with the player rotation.

    // we can probably declare this as an ivar to save memory, right?
    SKAction *rotate = [SKAction rotateByAngle:DegreesToRadians(rotationDegrees) duration:duration];
    rotate.timingMode = SKActionTimingEaseInEaseOut;
    
    //[self runAction:rotate];
}





#pragma mark Game logic
- (void)didBeginContact:(SKPhysicsContact *)contact {
    /* This method is basically handling all the game logic right now */

    SKPhysicsBody *other =
    (contact.bodyA.categoryBitMask == categoryPlayer ?
     contact.bodyB : contact.bodyA);
    
    
    if (other.categoryBitMask == categoryPatient) {
        XXXPatient *patientNode = (XXXPatient *)other.node;
        [_player loadPatient:patientNode];


    } else if (other.categoryBitMask == categoryHospital) {
        if (_player.patient) {
            [scoreKeeper scoreEventPatientDeliveredPoints:_player.patient.severity.points timeToLive:30]; // timeToLive is temp
            [_player unloadPatient];
        }
        
#if DEBUG
        NSLog(@"at hospital");
#endif
    }
    
    
}


- (void)authorizeTurnEvent: (CGFloat)degrees {
    /*
     Called directly by user input. Evaluates the player's current position, and executes a turn only if it ends on a road tile.
     */
    
    // TODO: for testing, try throwing up some sort of overlay that lets you know when you need to make a turning decision; something that shows the directions you can turn right now. that might be enough to improve the feeling of the controls.

    
    // begin by modeling the requested turn from the player's current position; return a target point
    CGFloat rads = DegreesToRadians(degrees);
    CGFloat newAngle = _player.targetAngleRadians + rads; // the angle the player will face after the turn
    
    // calculate the center point of the turn. this makes it easy to figure out the target point.
    CGPoint centerPoint = CGPointMake(_player.position.x + _player.CHARACTER_TURN_RADIUS * cosf(newAngle),
                                      _player.position.y + _player.CHARACTER_TURN_RADIUS * sinf(newAngle));

    // normalize the center point. since the rotation function assumes an anchor point of zero, we need to perform the rotation on a point relative to the origin and then translate it back to get the real target.
    CGPoint centerPointNormalized = CGPointSubtract(_player.position, centerPoint);
   
    CGPoint rotatedPoint = CGPointRotate(centerPointNormalized, degrees);
    
    CGPoint targetPoint = CGPointAdd(rotatedPoint, centerPoint);
    
    
    // with the target point, get the target tile and determine a) if it's a road tile, and b) if the point within the road tile is a road surface (and not the border)
    SKSpriteNode *targetTile = [_roadLayer tileAt:targetPoint]; // gets the the tile object being considered for the turn
    NSString *targetTileRoadType = [_bgLayer propertiesForGid:  [_roadLayer tileGidAt:targetPoint]  ][@"road"];
    
    CGPoint positionInTargetTile = [targetTile convertPoint:targetPoint fromNode:_bgLayer]; // the position of the target within the target tile
    
//        #if DEBUG
//        SKSpriteNode *targetPointSprite = [SKSpriteNode spriteNodeWithColor:[SKColor redColor] size:CGSizeMake(10, 10)];
//        targetPointSprite.name = @"DEBUG_targetPointSprite";
//        targetPointSprite.position = positionInTargetTile;
//        targetPointSprite.zPosition = targetTile.zPosition + 1;
//        [targetTile addChild:targetPointSprite];
//        [targetPointSprite runAction:[SKAction sequence:@[[SKAction waitForDuration:0.5],[SKAction removeFromParent]]]];
//
//        NSLog(@"targetTileRoadType = %@", targetTileRoadType);
//        #endif


    if (targetTileRoadType) {
        // check the coordinates to make sure it's on ROAD SURFACE within the tile
        
        // TODO: put this into a new tilemap class, so we can define the bounds for all tiles at the same time

        CGMutablePathRef path = CGPathCreateMutable(); // create a path to store the bounds for the road surface
        
        NSInteger offsetX = 128; // anchor point of tile (0.5, 0.5)
        NSInteger offsetY = 128;
        
        if (        [targetTileRoadType isEqualToString:@"ew"]) {
            
            CGPathMoveToPoint(path, NULL, 0 - offsetX, 70 - offsetY);
            CGPathAddLineToPoint(path, NULL, 256 - offsetX, 70 - offsetY);
            CGPathAddLineToPoint(path, NULL, 256 - offsetX, 186 - offsetY);
            CGPathAddLineToPoint(path, NULL, 0 - offsetX, 186 - offsetY);

            
            
        } else if ( [targetTileRoadType isEqualToString:@"nesw"]) {


            CGPathMoveToPoint(path, NULL, 70 - offsetX, 0 - offsetY);
            CGPathAddLineToPoint(path, NULL, 186 - offsetX, 0 - offsetY);
            CGPathAddLineToPoint(path, NULL, 186 - offsetX, 70 - offsetY);
            CGPathAddLineToPoint(path, NULL, 256 - offsetX, 70 - offsetY);
            CGPathAddLineToPoint(path, NULL, 256 - offsetX, 186 - offsetY);
            CGPathAddLineToPoint(path, NULL, 186 - offsetX, 186 - offsetY);
            CGPathAddLineToPoint(path, NULL, 186 - offsetX, 256 - offsetY);
            CGPathAddLineToPoint(path, NULL, 70 - offsetX, 256 - offsetY);
            CGPathAddLineToPoint(path, NULL, 70 - offsetX, 186 - offsetY);
            CGPathAddLineToPoint(path, NULL, 0 - offsetX, 186 - offsetY);
            CGPathAddLineToPoint(path, NULL, 0 - offsetX, 70 - offsetY);
            CGPathAddLineToPoint(path, NULL, 70 - offsetX, 70 - offsetY);
            

            
        } else if ( [targetTileRoadType isEqualToString:@"ns"]) {

            CGPathMoveToPoint(path, NULL, 70 - offsetX, 0 - offsetY);
            CGPathAddLineToPoint(path, NULL, 186 - offsetX, 0 - offsetY);
            CGPathAddLineToPoint(path, NULL, 186 - offsetX, 256 - offsetY);
            CGPathAddLineToPoint(path, NULL, 70 - offsetX, 256 - offsetY);

        } else if ( [targetTileRoadType isEqualToString:@"en"]) {

            CGPathMoveToPoint(path, NULL, 70 - offsetX, 70 - offsetY);
            CGPathAddLineToPoint(path, NULL, 256 - offsetX, 70 - offsetY);
            CGPathAddLineToPoint(path, NULL, 256 - offsetX, 186 - offsetY);
            CGPathAddLineToPoint(path, NULL, 186 - offsetX, 186 - offsetY);
            CGPathAddLineToPoint(path, NULL, 186 - offsetX, 256 - offsetY);
            CGPathAddLineToPoint(path, NULL, 70 - offsetX, 256 - offsetY);

        } else if ( [targetTileRoadType isEqualToString:@"nw"]) {
            
            CGPathMoveToPoint(path, NULL, 0 - offsetX, 70 - offsetY);
            CGPathAddLineToPoint(path, NULL, 186 - offsetX, 70 - offsetY);
            CGPathAddLineToPoint(path, NULL, 186 - offsetX, 256 - offsetY);
            CGPathAddLineToPoint(path, NULL, 70 - offsetX, 256 - offsetY);
            CGPathAddLineToPoint(path, NULL, 70 - offsetX, 186 - offsetY);
            CGPathAddLineToPoint(path, NULL, 0 - offsetX, 186 - offsetY);

        } else if ( [targetTileRoadType isEqualToString:@"es"]) {
            
            CGPathMoveToPoint(path, NULL, 70 - offsetX, 0 - offsetY);
            CGPathAddLineToPoint(path, NULL, 186 - offsetX, 0 - offsetY);
            CGPathAddLineToPoint(path, NULL, 186 - offsetX, 70 - offsetY);
            CGPathAddLineToPoint(path, NULL, 256 - offsetX, 70 - offsetY);
            CGPathAddLineToPoint(path, NULL, 256 - offsetX, 186 - offsetY);
            CGPathAddLineToPoint(path, NULL, 70 - offsetX, 186 - offsetY);

        } else if ( [targetTileRoadType isEqualToString:@"sw"]) {
            
            CGPathMoveToPoint(path, NULL, 70 - offsetX, 0 - offsetY);
            CGPathAddLineToPoint(path, NULL, 186 - offsetX, 0 - offsetY);
            CGPathAddLineToPoint(path, NULL, 186 - offsetX, 186 - offsetY);
            CGPathAddLineToPoint(path, NULL, 0 - offsetX, 186 - offsetY);
            CGPathAddLineToPoint(path, NULL, 0 - offsetX, 70 - offsetY);
            CGPathAddLineToPoint(path, NULL, 70 - offsetX, 70 - offsetY);

        } else if ( [targetTileRoadType isEqualToString:@"nes"]) {
            
            CGPathMoveToPoint(path, NULL, 70 - offsetX, 0 - offsetY);
            CGPathAddLineToPoint(path, NULL, 186 - offsetX, 0 - offsetY);
            CGPathAddLineToPoint(path, NULL, 186 - offsetX, 70 - offsetY);
            CGPathAddLineToPoint(path, NULL, 256 - offsetX, 70 - offsetY);
            CGPathAddLineToPoint(path, NULL, 256 - offsetX, 186 - offsetY);
            CGPathAddLineToPoint(path, NULL, 186 - offsetX, 186 - offsetY);
            CGPathAddLineToPoint(path, NULL, 186 - offsetX, 256 - offsetY);
            CGPathAddLineToPoint(path, NULL, 70 - offsetX, 256 - offsetY);

        } else if ( [targetTileRoadType isEqualToString:@"new"]) {
            
            CGPathMoveToPoint(path, NULL, 0 - offsetX, 70 - offsetY);
            CGPathAddLineToPoint(path, NULL, 256 - offsetX, 70 - offsetY);
            CGPathAddLineToPoint(path, NULL, 186 - offsetX, 70 - offsetY);
            CGPathAddLineToPoint(path, NULL, 186 - offsetX, 186 - offsetY);
            CGPathAddLineToPoint(path, NULL, 186 - offsetX, 256 - offsetY);
            CGPathAddLineToPoint(path, NULL, 70 - offsetX, 256 - offsetY);
            CGPathAddLineToPoint(path, NULL, 70 - offsetX, 186 - offsetY);
            CGPathAddLineToPoint(path, NULL, 0 - offsetX, 186 - offsetY);

        } else if ( [targetTileRoadType isEqualToString:@"nsw"]) {
            
            CGPathMoveToPoint(path, NULL, 0 - offsetX, 70 - offsetY);
            CGPathAddLineToPoint(path, NULL, 70 - offsetX, 70 - offsetY);
            CGPathAddLineToPoint(path, NULL, 70 - offsetX, 0 - offsetY);
            CGPathAddLineToPoint(path, NULL, 186 - offsetX, 0 - offsetY);
            CGPathAddLineToPoint(path, NULL, 186 - offsetX, 256 - offsetY);
            CGPathAddLineToPoint(path, NULL, 70 - offsetX, 256 - offsetY);
            CGPathAddLineToPoint(path, NULL, 70 - offsetX, 186 - offsetY);
            CGPathAddLineToPoint(path, NULL, 0 - offsetX, 186 - offsetY);

        } else if ( [targetTileRoadType isEqualToString:@"esw"]) {
            
            CGPathMoveToPoint(path, NULL, 0 - offsetX, 70 - offsetY);
            CGPathAddLineToPoint(path, NULL, 70 - offsetX, 70 - offsetY);
            CGPathAddLineToPoint(path, NULL, 70 - offsetX, 0 - offsetY);
            CGPathAddLineToPoint(path, NULL, 186 - offsetX, 0 - offsetY);
            CGPathAddLineToPoint(path, NULL, 186 - offsetX, 70 - offsetY);
            CGPathAddLineToPoint(path, NULL, 256 - offsetX, 70 - offsetY);
            CGPathAddLineToPoint(path, NULL, 256 - offsetX, 186 - offsetY);
            CGPathAddLineToPoint(path, NULL, 0 - offsetX, 186 - offsetY);

        }
        
        CGPathCloseSubpath(path); // close the path
            
        
        BOOL isWithinBounds = CGPathContainsPoint(path, NULL, positionInTargetTile, FALSE);
        
        if (isWithinBounds) { // if the point is within the bounding path..
            [_player turnByAngle:degrees];
        }

//        #if DEBUG
//        if (isWithinBounds) {
//            targetPointSprite.color = [SKColor blueColor];
//        }
//        
//        SKShapeNode *bounds = [SKShapeNode node];
//        bounds.path = path;
//        bounds.fillColor = [SKColor whiteColor];
//        bounds.alpha = 0.5;
//        bounds.zPosition = targetPointSprite.zPosition - 1;
//        
//        [targetTile addChild:bounds];
//        [bounds runAction:[SKAction sequence:@[[SKAction waitForDuration:1],[SKAction removeFromParent]]]];
//        #endif

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
                    [self rotateViewBy:-90];
                    
                    break;
                    
                case NSRightArrowFunctionKey:
                    [self authorizeTurnEvent:-90];
                    [self rotateViewBy:90];
                    
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
