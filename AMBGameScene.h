//
//  AMBGameScene.h
//  CharacterTests
//
//  Created by Alex Taylor on 2014-09-13.
//  Copyright (c) 2014 Alex Taylor. All rights reserved.
//
//  Provides high-level functions for all game scenes


#import <SpriteKit/SpriteKit.h>


@class JSTileMap;

@interface AMBGameScene : SKScene <UIGestureRecognizerDelegate>

@property UISwipeGestureRecognizer *gestureSwipeLeft;
@property UISwipeGestureRecognizer *gestureSwipeRight;
@property UISwipeGestureRecognizer *gestureSwipeUp;
@property UISwipeGestureRecognizer *gestureSwipeDown;
@property UITapGestureRecognizer *gestureTap;
@property UILongPressGestureRecognizer *gestureLongPress;

- (JSTileMap *)tileMapFromFile:(NSString *)filename;
    


@end
