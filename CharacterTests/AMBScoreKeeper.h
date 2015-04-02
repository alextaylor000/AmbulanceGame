//
//  AMBScoreKeeper.h
//  CharacterTests
//
//  Created by Alex Taylor on 2014-09-05.
//  Copyright (c) 2014 Alex Taylor. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SpriteKit/SpriteKit.h>

@class AMBPatient;

/* Game rules used by other classes */
@interface AMBScoreKeeper : NSObject

@property SKScene *scene; // stores the scene instance so we can create labels

/** Overall score for play session */
@property (readonly, nonatomic) NSInteger score;
@property (readonly, nonatomic) NSInteger numPatientsDelivered;

@property SKLabelNode *labelScore;
@property SKSpriteNode *notificationNode;


+ (AMBScoreKeeper *)sharedInstance;
+ (void)loadSharedAssets;

/* Labels */
-(SKLabelNode *)createScoreLabelWithPoints:(NSInteger)points atPos:(CGPoint)position;
-(SKSpriteNode *)createNotificationAtPos:(CGPoint)pos;

/* Scoring Events */
- (void) handleEventDeliveredPatient:(AMBPatient *)patient;
- (void) handleEventCarHit;
- (void) handleEventOutOfFuel;
- (void) handleEventInvincible;


@end
