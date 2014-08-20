//
//  XXXMyScene.m
//  CharacterTests
//
//  Created by Alex Taylor on 2014-07-06.
//  Copyright (c) 2014 Alex Taylor. All rights reserved.
//

#import "XXXMyScene.h"
#import "XXXCharacter.h"
#import "Tilemap.h"     // for supporting ASCII maps
#import "JSTilemap.h"   // for supporting TMX maps
#import "SKTUtils.h"


static const float KEY_PRESS_INTERVAL_SECS = 0.25; // ignore key presses more frequent than this interval

@interface XXXMyScene ()

@property NSTimeInterval lastUpdateTimeInterval;
@property NSTimeInterval lastKeyPress;
@property SKSpriteNode *worldNode;
@property JSTileMap *bgLayer;
@property XXXCharacter *player;

@property TMXLayer *cityLayer;
@property TMXLayer *roadLayer;
@property NSInteger currentTileGid;

@end

@implementation XXXMyScene

-(id)initWithSize:(CGSize)size {    
    if (self = [super initWithSize:size]) {
        /* Setup your scene here */
        
        self.backgroundColor = [SKColor colorWithRed:0.15 green:0.15 blue:0.3 alpha:1.0];
        self.anchorPoint = CGPointMake(0.5, 0.5);

        [self createWorld];
        
        
        [self addPlayer];

        
    }
    return self;
}



- (void) addPlayer {
    _player = [[XXXCharacter alloc] init];
    
    CGPoint spawnPoint = [_roadLayer pointForCoord:CGPointMake(35, 12)];
    
    _player.position = spawnPoint;
    
    [_bgLayer addChild:_player];
    
    
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
//    NSLog(@"pos=%1.3f,%1.3f",_player.position.x,_player.position.y);
    CGPoint playerTmxCoord = [_roadLayer coordForPoint:_player.position];
    //NSLog(@"coords=%1.0f,%1.0f",playerTmxCoord.x,playerTmxCoord.y);
    
    
    _currentTileGid = [_roadLayer tileGidAt:_player.position];
    NSString *roadType = [_bgLayer propertiesForGid:_currentTileGid][@"road"];
    //NSLog(@"GID: %ld   type: %@",(long)currentTileGid, roadType);
    

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
    
    _worldNode = [SKSpriteNode node];

    [self addChild:_worldNode];
    
    _bgLayer = [JSTileMap mapNamed:@"road-map-01.tmx"];
    _roadLayer = [_bgLayer layerNamed:@"road-tiles"];
    
    if (_bgLayer) {
		// center map on scene's anchor point
        //		CGRect mapBounds = [_bgLayer calculateAccumulatedFrame];
        //		_bgLayer.position = CGPointMake(-mapBounds.size.width/2.0, -mapBounds.size.height/2.0);
        
        [_worldNode addChild:_bgLayer];
    }
    

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
    /*
     Called directly by user input. Evaluates the player's current position, and executes a turn only if it ends on a road tile.
     */
    
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
    
        #if DEBUG
        SKSpriteNode *targetPointSprite = [SKSpriteNode spriteNodeWithColor:[SKColor blueColor] size:CGSizeMake(10, 10)];
        targetPointSprite.name = @"DEBUG_targetPointSprite";
        targetPointSprite.position = positionInTargetTile;
        [targetTile addChild:targetPointSprite];
        [targetPointSprite runAction:[SKAction sequence:@[[SKAction waitForDuration:0.5],[SKAction removeFromParent]]]];

        NSLog(@"targetTileRoadType = %@", targetTileRoadType);
        #endif


    if (targetTileRoadType) {
        // check the coordinates to make sure it's on ROAD SURFACE within the tile
        
        // TODO: put this into a new tilemap class, so we can define the bounds for all tiles at the same time
        SKSpriteNode *bounds = [SKSpriteNode spriteNodeWithColor:[SKColor whiteColor] size:CGSizeZero]; // this sprite will never be drawn to screen        
        
        if (        [targetTileRoadType isEqualToString:@"ew"]) {
            bounds.size = CGSizeMake(targetTile.size.width, targetTile.size.height - 120);
//            bounds.position = CGPointMake(0, 0);
            
        } else if ( [targetTileRoadType isEqualToString:@"nesw"]) {
            bounds.size = CGSizeMake(targetTile.size.width, targetTile.size.height - 120);
//            bounds.position = CGPointMake(0, 0);
            
            SKSpriteNode *boundsNS = [SKSpriteNode spriteNodeWithColor:[SKColor whiteColor] size:CGSizeZero];
            boundsNS.size = CGSizeMake(targetTile.size.width - 120, targetTile.size.height);
            
            
        } else if ( [targetTileRoadType isEqualToString:@"ns"]) {
            bounds.size = CGSizeMake(targetTile.size.width - 120, targetTile.size.height);
//            bounds.position = CGPointMake(0, 0);
        }
        
        
        if ([bounds containsPoint:positionInTargetTile]) {
            [_player turnByAngle:degrees];
        }

        #if DEBUG
        [targetTile addChild:bounds];
        [bounds runAction:[SKAction sequence:@[[SKAction waitForDuration:0.5],[SKAction removeFromParent]]]];
        #endif

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
