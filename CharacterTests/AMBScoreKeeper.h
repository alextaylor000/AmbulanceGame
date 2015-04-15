//
//  AMBScoreKeeper.h
//  CharacterTests
//
//  Created by Alex Taylor on 2014-09-05.
//  Copyright (c) 2014 Alex Taylor. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SpriteKit/SpriteKit.h>
#import "AMBConstants.h"

@class AMBPatient;

/* Game rules used by other classes */
@interface AMBScoreKeeper : NSObject

@property SKScene *scene; // stores the scene instance so we can create labels

/** Overall score for play session */
@property (readonly, nonatomic) NSInteger score;
@property (nonatomic) NSInteger patientsTotal;
@property (nonatomic) NSInteger patientsDelivered;

@property SKLabelNode *labelScore;
@property SKLabelNode *labelScoreUpdate;
@property SKSpriteNode *notificationNode;


+ (AMBScoreKeeper *)sharedInstance;
+ (void)loadSharedAssets;
- (id)init;

/* Labels */
-(SKLabelNode *)createScoreLabelWithPoints:(NSInteger)points atPos:(CGPoint)position;
- (SKLabelNode *)createScoreUpdateLabelAtPos:(CGPoint)position;
-(SKSpriteNode *)createNotificationAtPos:(CGPoint)pos;
- (NSString *)scoreDisplay:(NSInteger)score;
- (void)update;

/* Scoring Events */
- (void) handleEventDeliveredPatient:(AMBPatient *)patient;
- (void) handleEventPatientDied;
- (void) handleEventCarHit;
- (void) handleEventOutOfFuel;
- (void) handleEventInvincible;
- (void) handleEventOutOfTime;
- (void) handleEventSavedEveryone;


@end
