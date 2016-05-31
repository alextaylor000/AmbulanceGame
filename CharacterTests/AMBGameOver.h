//
//  AMBGameOver.h
//  AmbulanceGame
//
//  Created by Alex Taylor on 2015-04-03.
//  Copyright (c) 2015 Alex Taylor. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>
#import "AMBScoreKeeper.h"
#import "GameViewController.h"

@interface AMBGameOver : SKScene <UIGestureRecognizerDelegate>
@property UITapGestureRecognizer *gestureTap;
@property (nonatomic, weak) GameViewController *gameViewController;
- (instancetype)initWithSize:(CGSize)size scoreKeeper:(AMBScoreKeeper *)sc;

@end
