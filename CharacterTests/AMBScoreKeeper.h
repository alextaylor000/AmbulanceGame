//
//  AMBScoreKeeper.h
//  CharacterTests
//
//  Created by Alex Taylor on 2014-09-05.
//  Copyright (c) 2014 Alex Taylor. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SpriteKit/SpriteKit.h>
//#import "AMBPatient.h"
@class AMBPatient;

/* Game rules used by other classes */


@interface AMBScoreKeeper : NSObject

@property (readonly, nonatomic) NSInteger score;
@property (readonly, nonatomic) NSTimeInterval elapsedTime;

@property SKLabelNode *labelScore;


+ (AMBScoreKeeper *)sharedInstance;

/* Labels */
-(SKLabelNode *)createScoreLabelWithPoints:(NSInteger)points atPos:(CGPoint)position;


/* Scoring Events */
- (void) scoreEventDeliveredPatient:(AMBPatient *)patient;

@end
