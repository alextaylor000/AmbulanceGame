//
//  AMBTutorial.h
//  AmbulanceGame
//
//  Created by Alex Taylor on 2015-02-20.
//  Copyright (c) 2015 Alex Taylor. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

typedef enum {
    TutorialStateStep01 = 1,
    TutorialStateStep02,
    TutorialStateStep03,
    TutorialStateStep04,
    TutorialStateStep05,
    TutorialStateStep06,
    TutorialStateStep07,
    TutorialStateStep08,
    TutorialStateEnd

} TutorialState;

typedef enum {
    PlayerEventStartMoving,
    PlayerEventStopMoving,
    PlayerEventSlowDown,
    PlayerEventChangeLanes,
    PlayerEventTurnCorner,
    PlayerEventConstantMovement,
    PlayerEventPickupFuel,
    PlayerEventPickupInvincibility,
    PlayerEventPickupPatient,
    PlayerEventDeliverPatient,
    PlayerEventKillPatient
} PlayerEvent;

@interface AMBTutorial : SKSpriteNode

@property TutorialState tutorialState;

+ (void)loadSharedAssets;
+ (instancetype)tutorialOverlay; // loads the tutorial overlay with the first specified step.
- (void) beginTutorialAfterDelayOf:(CGFloat)seconds;
- (void) playerDidPerformEvent:(PlayerEvent)event;



@end
