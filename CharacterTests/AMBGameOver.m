//
//  AMBGameOver.m
//  AmbulanceGame
//
//  Created by Alex Taylor on 2015-04-03.
//  Copyright (c) 2015 Alex Taylor. All rights reserved.
//

#import "AMBGameOver.h"

typedef enum {
    GameOverLabelFormatHeadline,
    GameOverLabelFormatCategory,
    GameOverLabelFormatValue,
} GameOverLabelFormat;


@interface AMBGameOver ()

@property AMBScoreKeeper *scoreKeeper;

@end

@implementation AMBGameOver

- (instancetype)initWithSize:(CGSize)size scoreKeeper:(AMBScoreKeeper *)sc {
        if (self = [super initWithSize:size]) {
            self.backgroundColor = [SKColor yellowColor];
            _scoreKeeper = sc;

            self.anchorPoint = CGPointMake(0, 0.5);
            
            SKLabelNode *gameOver = [SKLabelNode labelNodeWithText:@"GAME OVER!"];
            gameOver.position = CGPointMake(GAMEOVER_LEFT_JUSTIFICATION, 100);
            [self formatLabelNode:gameOver withFormat:GameOverLabelFormatHeadline];
            [self addChild:gameOver];
            
            
            SKLabelNode *numPatients = [SKLabelNode labelNodeWithText:@"Patients saved:"];
            [self formatLabelNode:numPatients withFormat:GameOverLabelFormatCategory];
            numPatients.position = CGPointMake(GAMEOVER_LEFT_JUSTIFICATION, -50);
            
                SKLabelNode *numPatientsPoints = [SKLabelNode labelNodeWithText:[NSString stringWithFormat:@"%ld / %ld", (long)_scoreKeeper.patientsDelivered, (long)_scoreKeeper.patientsTotal]];
                [self formatLabelNode:numPatientsPoints withFormat:GameOverLabelFormatValue];
                [numPatients addChild: numPatientsPoints];
            
            [self addChild:numPatients];
            
            
            SKLabelNode *score = [SKLabelNode labelNodeWithText:@"Total Score:"];
            [self formatLabelNode:score withFormat:GameOverLabelFormatCategory];
            score.position = CGPointMake(GAMEOVER_LEFT_JUSTIFICATION, -100);
            
            SKLabelNode *scorePoints = [SKLabelNode labelNodeWithText:[_scoreKeeper scoreDisplay:_scoreKeeper.score]];
                [self formatLabelNode:scorePoints withFormat:GameOverLabelFormatValue];
                [score addChild:scorePoints];
            
            [self addChild:score];
            
            
            
        }
    return self;
}

- (void)formatLabelNode:(SKLabelNode *)label withFormat:(GameOverLabelFormat)format {
    switch (format) {
        case GameOverLabelFormatHeadline:
            label.fontName = @"AvenirNext-Bold";
            label.fontColor = [SKColor blackColor];
            label.fontSize = 60;
            label.horizontalAlignmentMode = SKLabelHorizontalAlignmentModeLeft;
            break;
            
        case GameOverLabelFormatCategory:
            label.fontName = @"AvenirNext-Regular";
            label.fontColor = [SKColor blackColor];
            label.fontSize = 45;
            label.horizontalAlignmentMode = SKLabelHorizontalAlignmentModeLeft;
            break;
            
        case GameOverLabelFormatValue:
            label.fontName = @"AvenirNext-Bold";
            label.fontColor = [SKColor blackColor];
            label.fontSize = 45;
            label.horizontalAlignmentMode = SKLabelHorizontalAlignmentModeRight;
            label.position = CGPointMake(GAMEOVER_VALUE_PADDING, 0);

            break;
            
    }
    
    
}

- (void)update:(NSTimeInterval)currentTime {
    // update the score
    [_scoreKeeper update];

}

@end
