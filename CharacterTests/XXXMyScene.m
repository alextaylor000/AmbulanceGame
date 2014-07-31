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


static const float KEY_PRESS_INTERVAL_SECS = 0.25; // ignore key presses more frequent than this interval

@interface XXXMyScene ()

@property NSTimeInterval lastUpdateTimeInterval;
@property NSTimeInterval lastKeyPress;
@property SKSpriteNode *worldNode;
@property Tilemap *bgLayer;
@property XXXCharacter *player;


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
    _player.position = CGPointMake(1500,300);

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
//    NSLog(@"pos=%1.0f,%1.0f",_player.position.x,_player.position.y);
    
    // logging for determining tile id
    NSArray *nodes = [_bgLayer nodesAtPoint:_player.position];
    
    for (SKNode *n in nodes) {
//        NSLog(@"node %@ at %1.0f,%1.0f",n.name,n.position.x,n.position.y);
    }

    

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
    SKAction *rotate = [SKAction rotateByAngle:DegreesToRadians(rotationDegrees) duration:1.0];
    [_bgLayer runAction:rotate];
}



#pragma mark Game logic
- (void)authorizeTurnEvent {
    // determines whether the character is allowed to turn
    /*
     
     1. figure out what the current target destination would be if the player turned right now
        player.position + (current_direction_normalized * radius)
     */
//    CGPoint targetDestination =
}


#pragma mark Controls
- (void)handleKeyboardEvent: (NSEvent *)theEvent keyDown:(BOOL)downOrUp {
    
    if (self.sceneLastUpdate - _lastKeyPress < KEY_PRESS_INTERVAL_SECS ) return;
    
    if ([theEvent modifierFlags] & NSNumericPadKeyMask) { // arrow keys
        _lastKeyPress = self.sceneLastUpdate;
        
        NSString *theArrow = [theEvent charactersIgnoringModifiers];
        unichar keyChar = 0;

        
        SKAction *rotate;
        
        if ([theArrow length] == 1) {
            keyChar = [theArrow characterAtIndex:0];
            
            switch (keyChar) {
                case NSUpArrowFunctionKey:
                    [_player startMoving];
                    break;
                    
                case NSLeftArrowFunctionKey:
                    [_player turnByAngle:90];

                    
                    
                    break;
                    
                case NSRightArrowFunctionKey:
                    [_player turnByAngle:-90];


                    
                    
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
