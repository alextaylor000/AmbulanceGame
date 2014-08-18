//
//  XXXMyScene.m
//  CharacterTests
//
//  Created by Alex Taylor on 2014-07-06.
//  Copyright (c) 2014 Alex Taylor. All rights reserved.
//

#import "XXXMyScene.h"
#import "XXXCharacter.h"
#import "Tilemap.h"

#import "SKTUtils.h"

#define kNumberCars   15

static const float KEY_PRESS_INTERVAL_SECS = 0.25; // ignore key presses more frequent than this interval

@interface XXXMyScene ()

@property NSTimeInterval lastUpdateTimeInterval;
@property NSTimeInterval lastKeyPress;
@property SKSpriteNode *worldNode;
@property Tilemap *bgLayer;
@property XXXCharacter *player;


@end

@implementation XXXMyScene{
    
    NSMutableArray *_cars;
    int _nextCar;
    double _nextCarSpawn;
    
}

-(id)initWithSize:(CGSize)size {    
    if (self = [super initWithSize:size]) {
        /* Setup your scene here */
        
        self.backgroundColor = [SKColor colorWithRed:0.15 green:0.15 blue:0.3 alpha:1.0];
        self.anchorPoint = CGPointMake(0.5, 0.5);

        [self createWorld];
        
        
        [self addPlayer];

        [self addCars];//Adds inital enamies to the screen
        [self initalizeCarVariables];
    }
    return self;
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
    _player.position = CGPointMake(1500,300);
    
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
    
    // debug player
    //NSLog(@"pos=%1.3f,%1.3f",_player.position.x,_player.position.y);
    
    // logging for determining tile id
//    NSArray *nodes = [_bgLayer nodesAtPoint:_player.position];
//    
//    for (SKNode *n in nodes) {
//        NSLog(@"node %@ at %1.0f,%1.0f",n.name,n.position.x,n.position.y);
//    }
    
    [self updateCars];
    NSLog(@"%f, %f",_player.direction.x, _player.direction.y);

}

#pragma mark Tilemap stuff
- (Tilemap *)createTilemap {
    return [[Tilemap alloc]initWithAtlasNamed:@"level" tileSize:CGSizeMake(200, 200) grid:@[
@"xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
@"xoooooooooooooooooooooooooooooooooooooooox",
@"xoxxoxxoxxoxxoxxoxxoxxoxxoxxoxxoxxoxxoxxox",
@"xoooooooooooooooooooooooooooooooooooooooox",
@"xxxxoxxoxxoxxxxxoxxoxxoxxoxxoxxoxxoxxoxxox",
@"xoooooooooooooooooooooooooooooooooooooooox",
@"xoxxoxxoxxoxxoxxoxxoxxoxxoxxoxxoxxoxxoxxox",
@"xoooooooooooooooooooooooooooooooooooooooox",
@"xoxxoxxoxxoxxxxxoxxoxxoxxxxxoxxoxxoxxoxxox",
@"xoooooooooooooooooooooooooooooooooooooooox",
@"xoxxoxxoxxoxxoxxoxxoxxxoxoxxoxxoxxoxxoxxox",
@"xoooooooooooooooooooooooxooooxooooooooooox",
@"xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
]];

}

- (void)createWorld {
    _bgLayer = [self createTilemap];
    
    _worldNode = [SKSpriteNode node];
    [_worldNode addChild:_bgLayer];

    [self addChild:_worldNode];
    
    self.anchorPoint = CGPointMake(0.5, 0.5);
    _worldNode.position = CGPointMake(-_bgLayer.layerSize.width/2, -_bgLayer.layerSize.height/2);
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
- (void)authorizeTurnEvent: (CGFloat)degrees {
    // this is a start for calculating the center position, but it only works some of the time.. probably b/c of positive vs. negative angles. look up that video again.

    CGFloat rads = DegreesToRadians(degrees);
    CGFloat requestedAngle = _player.targetAngleRadians + rads;
    
    CGPoint centerPoint = CGPointMake(_player.position.x + _player.CHARACTER_TURN_RADIUS * cosf(requestedAngle),
                                      _player.position.y + _player.CHARACTER_TURN_RADIUS * sinf(requestedAngle));
    
    
    
//    SKSpriteNode *centerPointSprite = [SKSpriteNode spriteNodeWithColor:[SKColor redColor] size:CGSizeMake(10, 10)];
//    centerPointSprite.position = centerPoint;
//    [_bgLayer addChild:centerPointSprite];
    
    CGPoint originPoint = CGPointSubtract(_player.position, centerPoint);
    CGPoint rotatedPlayer = CGPointMake(originPoint.x * cosf(rads) - originPoint.y * sinf(rads),
                                        originPoint.x * sinf(rads) + originPoint.y * cosf(rads));
    
    CGPoint targetPoint = CGPointAdd(rotatedPlayer, centerPoint);
    
//    SKSpriteNode *targetPointSprite = [SKSpriteNode spriteNodeWithColor:[SKColor blueColor] size:CGSizeMake(10, 10)];
//    targetPointSprite.name = @"DEBUG_targetPointSprite";
//    targetPointSprite.position = targetPoint;
//    targetPointSprite.zPosition = -5;
//    
//    
//    [_bgLayer addChild:targetPointSprite];

    SKNode *targetTile = [_bgLayer nodeAtPoint:targetPoint];
    
    NSLog(@"target tile is %@ at %1.5f,%1.5f", targetTile.name, targetTile.position.x,targetTile.position.y );
    

    
    if ([targetTile.name isEqualToString:@"road"]) {
        NSLog(@"turning...");
        [_player turnByAngle:degrees];
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
