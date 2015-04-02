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


#pragma mark SCORING CONSTANTS
const int SCORE_PATIENT_SEVERITY_1 =                100000;
const int SCORE_PATIENT_SEVERITY_2 =                200000;
const int SCORE_PATIENT_SEVERITY_3 =                300000;
const int SCORE_PATIENT_TTL_BONUS =                 50000;
const int SCORE_SAFE_DRIVING_BONUS =                30000;
const int SCORE_CARS_HIT_MULTIPLIER =               SCORE_SAFE_DRIVING_BONUS / 5; // max number of cars you can hit, then you get a zero safe driving
const int SCORE_END_ALL_PATIENTS_DELIVERED_BONUS =  10000;





typedef enum {
    ScoreKeeperNotificationFuelEmpty,
    ScoreKeeperNotificationFuelUp,
    ScoreKeeperNotificationInvincibility,
    ScoreKeeperNotificationPatientDelivered,
    ScoreKeeperNotificationPatientDied,
    ScoreKeeperNotificationTimeOut
} ScoreKeeperNotifications;


@interface AMBScoreKeeper ()

@property NSInteger carsHit;

@end

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
        _numPatientsDelivered = 0;
        _carsHit = 0;
        
    }
    
   return self;
}



-(SKSpriteNode *)createNotificationAtPos:(CGPoint)pos {

    CGFloat sizeMult = (self.scene.size.width * 0.85) / sNotificationFuelEmpty.size.width; // this assumes that all notifications are the same size

    _notificationNode = [SKSpriteNode spriteNodeWithColor:[SKColor whiteColor] size:CGSizeMake(50, 50)];
    _notificationNode.size = CGSizeMake(sNotificationFuelEmpty.size.width * sizeMult, sNotificationFuelEmpty.size.height * sizeMult);
    _notificationNode.zPosition = 1000;
    _notificationNode.alpha = 0;

    
    return _notificationNode;
}


- (SKLabelNode *)createScoreLabelWithPoints:(NSInteger)points atPos:(CGPoint)position {
    
    _labelScore = [SKLabelNode labelNodeWithFontNamed:@"AvenirNext-Bold"];
    _labelScore.horizontalAlignmentMode = SKLabelHorizontalAlignmentModeRight;
    _labelScore.text = [NSString stringWithFormat:@"+ %ld", (long)points];
    _labelScore.fontColor = [SKColor yellowColor];
    _labelScore.fontSize = 70;
    _labelScore.position = position;
    
    _labelScore.zPosition = 999;
    
    return _labelScore;
}

- (void)updateScoreLabelWithPoints:(NSInteger)points {
    // TODO: Use NSNumberFormatter to output comma-formatted numbers
    _labelScore.text = [NSString stringWithFormat:@"+ %ld", (long)points];
}


- (void) updateScore:(NSInteger)points withMessage:(NSString *)message {
    _score += points;
    
    [self updateScoreLabelWithPoints:_score];

    #if DEBUG
        NSLog(@"[[    SCORE:   %ld    ]]", (long)_score);
    #endif

}

#pragma mark Scoring Events
- (void)handleEventDeliveredPatient:(AMBPatient *)patient {
    NSMutableDictionary *userData = patient.userData;
    NSTimeInterval timeRemaining = [patient getPatientTTL];
    NSTimeInterval timeToLive = [[userData valueForKey:@"timeToLive"] doubleValue];
    PatientSeverity severity = [[userData valueForKey:@"severity"] intValue];
    
    int PATIENT_DELIVERED_BASE_SCORE = SCORE_PATIENT_SEVERITY_1; // init to default amount
    
    switch (severity) {
        case LevelOne:
            PATIENT_DELIVERED_BASE_SCORE = SCORE_PATIENT_SEVERITY_1;
            break;
            
        case LevelTwo:
            PATIENT_DELIVERED_BASE_SCORE = SCORE_PATIENT_SEVERITY_2;
            break;
            
        case LevelThree:
            PATIENT_DELIVERED_BASE_SCORE = SCORE_PATIENT_SEVERITY_3;
            break;
    }
    
    // define the formula for applying points
    NSInteger netPoints = PATIENT_DELIVERED_BASE_SCORE;
    NSInteger patientTTLpoints = SCORE_PATIENT_TTL_BONUS * ( timeRemaining / timeToLive );
    NSInteger safeDriving = SCORE_SAFE_DRIVING_BONUS - ( _carsHit * SCORE_CARS_HIT_MULTIPLIER );
    
    [self updateScore:netPoints withMessage:@"Patient Delivered"];
    [self updateScore:patientTTLpoints withMessage:@"Time Bonus"];
    [self updateScore:safeDriving withMessage:@"Safe Driving Bonus"];

    [self showNotification:ScoreKeeperNotificationPatientDelivered];
    
    
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
