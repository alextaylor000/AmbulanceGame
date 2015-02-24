//
//  AMBTutorial.m
//  AmbulanceGame
//
//  Created by Alex Taylor on 2015-02-20.
//  Copyright (c) 2015 Alex Taylor. All rights reserved.
//

#import "AMBTutorial.h"

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

+ (instancetype)tutorialOverlay {
    return [[super alloc]initWithTexture:sTutorialStartAndStop]; // this is where we specify the first texture to load
}

- (void)playerDidPerformEvent:(PlayerEvent)event {
    

    if (_tutorialIsActive) {
        switch (_tutorialState) {
            case TutorialStateStep01:
                if (event == PlayerEventStartMoving || event == PlayerEventStopMoving) {
                    [self swapTextureTo:sTutorialSwipe];
                    _tutorialState = TutorialStateStep02;
                }
        
                break;

            case TutorialStateStep02:
                if (event == PlayerEventChangeLanes || event == PlayerEventTurnCorner) {
                    [self swapTextureTo:sTutorialSwipeAndHold];
                    _tutorialState = TutorialStateStep03;
                }
                break;

            case TutorialStateStep03:
                if (event == PlayerEventConstantMovement) {
                    [self swapTextureTo:sTutorialTapAndHold];
                    _tutorialState = TutorialStateStep04;
                }

                break;

            case TutorialStateStep04:
                if (event == PlayerEventSlowDown) {
                    [self swapTextureTo:sTutorialYellowArrow];
                    _tutorialState = TutorialStateStep05;
                }

                break;

            case TutorialStateStep05:
                if (event == PlayerEventPickupPatient) {
                    [self swapTextureTo:sTutorialWhiteArrow];
                    _tutorialState = TutorialStateStep06;
                }

                break;

            case TutorialStateStep06:
                if (event == PlayerEventDeliverPatient) {
                    [self swapTextureTo:sTutorialFuel];
                    _tutorialState = TutorialStateStep07;
                }

                break;

            case TutorialStateStep07:
                if (event == PlayerEventPickupFuel) { // TODO: this should automatically switch states after a few seconds
                    [self swapTextureTo:sTutorialInvincibility];
                    _tutorialState = TutorialStateStep08;
                }

                break;

            case TutorialStateStep08:
                if (event == PlayerEventPickupInvincibility) { // TODO: this should automatically switch states after a few seconds
                    [self swapTextureTo:sTutorialEnd];
                    _tutorialState = TutorialStateEnd;
                    [self endTutorialAfterDelayOf:3];
                }

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

- (void)endTutorialAfterDelayOf:(CGFloat)seconds {
    SKAction *end = [SKAction sequence:@[ [SKAction waitForDuration:seconds],
                                          sTextureFadeOut,
                                          [SKAction removeFromParent]]];
    [self runAction:end];
}

- (void)swapTextureTo:(SKTexture *)newTexture {
    [self runAction:[SKAction sequence:@[sTextureFadeOut, [SKAction setTexture:newTexture], sTextureFadeIn]]];
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
        sTutorialYellowArrow = [tutorialAtlas textureNamed:@"tutorial_yellow-arrow"];
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
static SKTexture *sTutorialYellowArrow = nil;
static SKTexture *sTutorialWhiteArrow = nil;
static SKTexture *sTutorialFuel = nil;
static SKTexture *sTutorialInvincibility = nil;
static SKTexture *sTutorialEnd = nil;

static SKAction *sTextureFadeIn = nil;
static SKAction *sTextureFadeOut = nil;



@end
