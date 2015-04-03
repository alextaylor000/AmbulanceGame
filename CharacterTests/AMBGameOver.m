//
//  AMBGameOver.m
//  AmbulanceGame
//
//  Created by Alex Taylor on 2015-04-03.
//  Copyright (c) 2015 Alex Taylor. All rights reserved.
//

#import "AMBGameOver.h"


@interface AMBGameOver ()

@property AMBScoreKeeper *scoreKeeper;

@end

@implementation AMBGameOver

- (instancetype)initWithSize:(CGSize)size scoreKeeper:(AMBScoreKeeper *)sc {
        if (self = [super initWithSize:size]) {
            self.backgroundColor = [SKColor yellowColor];
            _scoreKeeper = sc;
            
            SKLabelNode *gameOver = [SKLabelNode labelNodeWithText:@"GAME OVER!"];
            gameOver.fontColor = [SKColor blackColor];
            gameOver.fontSize = 45;
            [self addChild:gameOver];
            
        }
    return self;
}

@end
