//
//  XXXMyScene.m
//  CharacterTests
//
//  Created by Alex Taylor on 2014-07-06.
//  Copyright (c) 2014 Alex Taylor. All rights reserved.
//

#import "XXXMyScene.h"
#import "XXXCharacter.h"
#import "SKTUtils.h"

static const float KEY_PRESS_INTERVAL_SECS = 0.5; // ignore key presses more frequent than this interval

@interface XXXMyScene ()

@property NSTimeInterval lastUpdateTimeInterval;
@property NSTimeInterval lastKeyPress;
@property XXXCharacter *player;


@end

@implementation XXXMyScene

-(id)initWithSize:(CGSize)size {    
    if (self = [super initWithSize:size]) {
        /* Setup your scene here */
        
        self.backgroundColor = [SKColor colorWithRed:0.15 green:0.15 blue:0.3 alpha:1.0];
        
        [self addPlayer];
    }
    return self;
}

- (void) addPlayer {
    _player = [[XXXCharacter alloc] init];
    _player.position = CGPointMake(self.scene.frame.size.width/2,self.scene.frame.size.height/2);
    
    [self.scene addChild:_player];
    
    
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
}

#pragma mark Character

#pragma mark Controls
- (void)handleKeyboardEvent: (NSEvent *)theEvent keyDown:(BOOL)downOrUp {
    
    if (self.sceneLastUpdate - _lastKeyPress < KEY_PRESS_INTERVAL_SECS ) return;
    
    if ([theEvent modifierFlags] & NSNumericPadKeyMask) { // arrow keys
        //NSLog(@"key press");
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
