//
//  AMBTutorial.m
//  AmbulanceGame
//
//  Created by Alex Taylor on 2015-02-20.
//  Copyright (c) 2015 Alex Taylor. All rights reserved.
//

#import "AMBTutorial.h"
#import "AMBLevelScene.h"
#import "AMBTimer.h"

@interface AMBTutorial ()

@property BOOL tutorialIsActive;


@end

@implementation AMBTutorial

- (instancetype)initWithTexture:(SKTexture *)texture {
    if (self = [super initWithTexture:texture]) {
        _tutorialState = TutorialStateStep01;
        _tutorialIsActive = NO;
        self.alpha = 0;

    }
    
    return self;
}

- (AMBLevelScene *)characterScene {
    AMBLevelScene *scene = (id)[self scene];
    
    if ([scene isKindOfClass:[AMBLevelScene class]]) {
        return scene;
    } else {
        return nil;
    }
}


+ (instancetype)tutorialOverlay {
    return [[super alloc]initWithTexture:sTutorialStartAndStop]; // this is where we specify the first texture to load
}

- (void)playerDidPerformEvent:(PlayerEvent)event {

    
    if (_tutorialIsActive) {
        switch (_tutorialState) {
            case TutorialStateStep01:
                if (event == PlayerEventStartMoving || event == PlayerEventStopMoving) {
                    [self swapTextureTo:sTutorialSwipe afterDelay:0.5];
                    _tutorialState = TutorialStateStep02;
                }
        
                break;

            case TutorialStateStep02:
                if (event == PlayerEventChangeLanes || event == PlayerEventTurnCorner) {
                    [self swapTextureTo:sTutorialSwipeAndHold afterDelay:0.5];
                    _tutorialState = TutorialStateStep03;
                }
                break;

            case TutorialStateStep03:
                if (event == PlayerEventConstantMovement) {
                    /* player has held down constant movement, change states and wait for a turn */
                    _tutorialState = TutorialStateStep03A;

                }

                break;

            case TutorialStateStep03A:
                if (event == PlayerEventTurnCorner) {
                    [self swapTextureTo:sTutorialTapAndHold afterDelay:0.5];
                    _tutorialState = TutorialStateStep04;
                    
                }
                
                break;
                
                
            case TutorialStateStep04:
                if (event == PlayerEventSlowDown) {
                    [self swapTextureTo:sTutorialMinimap afterDelay:0.5];
                    _tutorialState = TutorialStateStep05;
                }

                break;

            case TutorialStateStep05:
                if (event == PlayerEventPickupPatient) {
                    [self swapTextureTo:sTutorialWhiteArrow afterDelay:0.5];
                    _tutorialState = TutorialStateStep06;
                } else if (event == PlayerEventDeliverPatient) {
                    _tutorialState = TutorialStateStep07;
                    [self finishTutorial];
                }

                break;

            case TutorialStateStep06:
                if (event == PlayerEventDeliverPatient) {
                    // begin the auto-guided part of the tutorial
                    _tutorialState = TutorialStateStep07;
                    [self finishTutorial];
                }

                break;

            case TutorialStateStep07:
//                if (event == PlayerEventPickupFuel) { // TODO: this should automatically switch states after a few seconds
//                    [self swapTextureTo:sTutorialInvincibility afterDelay:0.5];
//                    _tutorialState = TutorialStateStep08;
//                }

                break;

            case TutorialStateStep08:
//                if (event == PlayerEventPickupInvincibility) { // TODO: this should automatically switch states after a few seconds
//                    [self swapTextureTo:sTutorialEnd afterDelay:0.5];
//                    _tutorialState = TutorialStateEnd;
//                    [self endTutorialAfterDelayOf:3];
//                }
                
            case TutorialStateEnd:
                //

                break;
                
        } // switch
    } // if tutorialIsActive
    
}

- (void)beginTutorialAfterDelayOf:(CGFloat)seconds {

    
    
    SKAction *begin = [SKAction sequence:@[ [SKAction waitForDuration:seconds],
                                            sTextureFadeIn,
                                            [SKAction runBlock:^{ _tutorialIsActive = YES; }]]];
    [self runAction:begin];

}

- (void)finishTutorial {
    
    [self runAction:[SKAction sequence:@[
                                         [SKAction waitForDuration:0.5],
                                         sTextureFadeOut,
                                         [SKAction setTexture:sTutorialFuel],
                                         sTextureFadeIn,
                                         
                                         [SKAction waitForDuration:4],
                                         
                                         sTextureFadeOut,
                                         [SKAction setTexture:sTutorialInvincibility],
                                         sTextureFadeIn,
                                         
                                         [SKAction waitForDuration:4],
                                         
                                         sTextureFadeOut,
                                         [SKAction setTexture:sTutorialEnd],
                                         sTextureFadeIn,
                                         
                                         [SKAction waitForDuration:2.5],
                                         
                                         sTextureFadeOut,
                                         
                                         [SKAction runBlock:^{[self endTutorialAfterDelayOf:0];}],
                                         
                                         [SKAction removeFromParent]
                                         

                                          ]]];
}

- (void)endTutorialAfterDelayOf:(CGFloat)seconds {
    AMBLevelScene *__weak scene = [self characterScene];
    [scene didCompleteTutorial];
}

- (void)swapTextureTo:(SKTexture *)newTexture afterDelay:(CGFloat)seconds {
    [self runAction:[SKAction sequence:@[[SKAction waitForDuration:seconds], sTextureFadeOut, [SKAction setTexture:newTexture], sTextureFadeIn]]];
}




+ (void)loadSharedAssets {
    
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        SKTextureAtlas *tutorialAtlas = [SKTextureAtlas atlasNamed:@"tutorial"];
        sIncomingTexture = [tutorialAtlas textureNamed:@"tutorial_invincibility"]; // just a placeholder so the action below doesn't load a nil object
        sTutorialStartAndStop = [tutorialAtlas textureNamed:@"tutorial_start-and-stop"];
        sTutorialSwipe = [tutorialAtlas textureNamed:@"tutorial_swipe"];
        sTutorialSwipeAndHold = [tutorialAtlas textureNamed:@"tutorial_swipe-and-hold"];
        sTutorialTapAndHold = [tutorialAtlas textureNamed:@"tutorial_tap-and-hold"];
        sTutorialMinimap = [tutorialAtlas textureNamed:@"tutorial_minimap"];
        sTutorialWhiteArrow = [tutorialAtlas textureNamed:@"tutorial_white-arrow"];
        sTutorialFuel = [tutorialAtlas textureNamed:@"tutorial_fuel"];
        sTutorialInvincibility = [tutorialAtlas textureNamed:@"tutorial_invincibility"];
        sTutorialEnd = [tutorialAtlas textureNamed:@"tutorial_end"];

        sTextureFadeIn = [SKAction fadeInWithDuration:0.5];
        sTextureFadeOut = [SKAction fadeOutWithDuration:0.5];

        
    });
    
}

static SKTexture *sIncomingTexture = nil;
static SKTexture *sTutorialStartAndStop = nil;
static SKTexture *sTutorialSwipe = nil;
static SKTexture *sTutorialSwipeAndHold = nil;
static SKTexture *sTutorialTapAndHold = nil;
static SKTexture *sTutorialMinimap = nil;
static SKTexture *sTutorialWhiteArrow = nil;
static SKTexture *sTutorialFuel = nil;
static SKTexture *sTutorialInvincibility = nil;
static SKTexture *sTutorialEnd = nil;

static SKAction *sTextureFadeIn = nil;
static SKAction *sTextureFadeOut = nil;



@end
