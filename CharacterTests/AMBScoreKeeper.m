//
//  AMBScoreKeeper.m
//  CharacterTests
//
//  Created by Alex Taylor on 2014-09-05.
//  Copyright (c) 2014 Alex Taylor. All rights reserved.
//

#import "AMBScoreKeeper.h"
#import "AMBLevelScene.h" 
#import "AMBPatient.h"
#import "SKTUtils.h" // for RandomFloatRange

@implementation AMBScoreKeeper

/**
 Instantiates a ScoreKeeper instance, and ensures that only one instance can be created.
 */
+ (AMBScoreKeeper *)sharedInstance {
    static AMBScoreKeeper *_sharedInstance = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        _sharedInstance = [[AMBScoreKeeper alloc]init];
    });
    
    return _sharedInstance;
}

- (id)init {
    if (self = [super init]) {
        /* Initialize anything needed for game logic */
        _score = 0;
        _elapsedTime = 0;
        
        
        
    }
    
   return self;
}

- (SKLabelNode *)createScoreLabelWithPoints:(NSInteger)points atPos:(CGPoint)position {
    
    _labelScore = [SKLabelNode labelNodeWithFontNamed:@"Courier-Bold"];
    _labelScore.horizontalAlignmentMode = SKLabelHorizontalAlignmentModeLeft;
    _labelScore.text = [NSString stringWithFormat:@"SCORE: %ld", (long)points];
    _labelScore.fontColor = [SKColor yellowColor];
    
    _labelScore.position = position;
    
    _labelScore.zPosition = 999;
    
    return _labelScore;
}

-(SKLabelNode *)createEventlabelAtPos:(CGPoint)position {
    if (!_labelEvent) {
        _labelEvent = [SKLabelNode labelNodeWithFontNamed:@"Courier-Bold"];
        _labelEvent.text = @"EVENT!";
        _labelEvent.fontColor = [SKColor yellowColor];
        _labelEvent.fontSize = 60;
        _labelEvent.alpha = 0;
        _labelEvent.zPosition = 1000;
        _labelEvent.position = position;
    }
    
    return _labelEvent;
}

-(SKSpriteNode *)createNotificationAtPos:(CGPoint)pos {
    if (!_notificationNode) {
        CGFloat sizeMult = (self.scene.size.width * 0.85) / sNotificationFuelEmpty.size.width; // this assumes that all notifications are the same size

        _notificationNode = [SKSpriteNode spriteNodeWithColor:[SKColor whiteColor] size:CGSizeMake(50, 50)];
        _notificationNode.size = CGSizeMake(sNotificationFuelEmpty.size.width * sizeMult, sNotificationFuelEmpty.size.height * sizeMult);
        _notificationNode.zPosition = 1000;
        _notificationNode.alpha = 0;
    }
    
    return _notificationNode;
}

- (void)updateScoreLabelWithPoints:(NSInteger)points {
    _labelScore.text = [NSString stringWithFormat:@"SCORE: %ld", (long)points];
}


- (void) updateScore:(NSInteger)points {
    _score += points;
    
    [self updateScoreLabelWithPoints:_score];

    #if DEBUG
        NSLog(@"[[    SCORE:   %ld    ]]", (long)_score);
    #endif

}

#pragma mark Scoring Events
- (void) scoreEventDeliveredPatient:(AMBPatient *)patient {
    NSMutableDictionary *userData = patient.userData;
    
    NSInteger medicalSupplies = [[userData valueForKey:@"medicalSupplies"] integerValue];
    NSTimeInterval timeToLive = [[userData valueForKey:@"timeToLive"] doubleValue];
    NSInteger points =          [[userData valueForKey:@"points"] integerValue];
    
    // define the formula for applying points
    NSInteger netPoints = points;
    
    [self updateScore:netPoints];
    
#if DEBUG
    NSLog(@"patient DELIVERED!");
#endif
    
}

- (void)eventLabelWithText:(NSString *)text {
    _labelEvent.text = text;
    
    SKAction *action;
    action = [SKAction sequence:@[[SKAction fadeInWithDuration:0.075],[SKAction waitForDuration:2.0],[SKAction fadeOutWithDuration:0.075]]];
    [_labelEvent runAction:action];
    
}

- (void)showNotification:(ScoreKeeperNotifications)notification {
    switch (notification) {
        case ScoreKeeperNotificationFuelEmpty:
            _notificationNode.texture = sNotificationFuelEmpty;
            break;

        case ScoreKeeperNotificationFuelUp:
            _notificationNode.texture = sNotificationFuelUp;
            break;
            
        case ScoreKeeperNotificationInvincibility:
            _notificationNode.texture = sNotificationInvincibility;
            break;
            
        case ScoreKeeperNotificationPatientDelivered:
            _notificationNode.texture = sNotificationPatientDelivered;
            break;
            
        case ScoreKeeperNotificationPatientDied:
            _notificationNode.texture = sNotificationPatientDied;
            break;
            
        case ScoreKeeperNotificationTimeOut:
            _notificationNode.texture = sNotificationTimeOut;
            break;
            
    }
    
    [_notificationNode runAction:sNotificationSequence];
}


#pragma mark Assets
+ (void)loadSharedAssets {
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{

        SKTextureAtlas *notifications = [SKTextureAtlas atlasNamed:@"notifications"];
        
        sNotificationFuelEmpty = [notifications textureNamed:@"notification_fuel-empty"];
        sNotificationFuelUp = [notifications textureNamed:@"notification_fuel-up"];
        sNotificationInvincibility = [notifications textureNamed:@"notification_invincibility"];
        sNotificationPatientDelivered = [notifications textureNamed:@"notification_patient-delivered"];
        sNotificationPatientDied = [notifications textureNamed:@"notification_patient-died"];
        sNotificationTimeOut = [notifications textureNamed:@"notification_time-out"];
        
        sNotificationAppear = [SKAction group:@[
                                                [SKAction fadeInWithDuration:0.15]]]; // these are groups so that we can add more complex animation later
        
        sNotificationHide = [SKAction group:@[
                                              [SKAction fadeOutWithDuration:0.15]]];
        
        sNotificationSequence = [SKAction sequence:@[sNotificationAppear, [SKAction waitForDuration:2.5], sNotificationHide]];
        
        
    });
    
}

static SKTexture *sNotificationFuelEmpty = nil;
static SKTexture *sNotificationFuelUp = nil;
static SKTexture *sNotificationInvincibility = nil;
static SKTexture *sNotificationPatientDelivered = nil;
static SKTexture *sNotificationPatientDied = nil;
static SKTexture *sNotificationTimeOut = nil;
static SKAction *sNotificationAppear = nil;
static SKAction *sNotificationHide = nil;
static SKAction *sNotificationSequence = nil;


@end
