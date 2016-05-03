//
//  AMBFuelGauge.m
//  AmbulanceGame
//
//  Created by Alex Taylor on 2015-03-15.
//  Copyright (c) 2015 Alex Taylor. All rights reserved.
//

#import "AMBFuelGauge.h"
#import "SKTUtils.h"
#import "AMBLevelScene.h"

@interface AMBFuelGauge ()

@property SKSpriteNode *background;
@property SKSpriteNode *backgroundWhite;
@property SKSpriteNode *foreground;
@property SKSpriteNode *needle;

@end

@implementation AMBFuelGauge

+ (AMBFuelGauge *)fuelGaugeWithAmount:(NSInteger)startingAmount {
    AMBFuelGauge *fuelGauge = [AMBFuelGauge node];
    
    fuelGauge.fuelTimer = 0;
    fuelGauge.isOutOfFuel = NO;

    fuelGauge.background =  [SKSpriteNode spriteNodeWithTexture:sFuelGaugeBackground];
    fuelGauge.backgroundWhite = [SKSpriteNode spriteNodeWithTexture:sFuelGaugeBackgroundWhite];
    fuelGauge.needle =      [SKSpriteNode spriteNodeWithTexture:sFuelGaugeNeedle];
    fuelGauge.foreground =  [SKSpriteNode spriteNodeWithTexture:sFuelGaugeForeground];
    
    fuelGauge.backgroundWhite.alpha = 0;
    
    [fuelGauge addChild:fuelGauge.background];
    [fuelGauge addChild:fuelGauge.backgroundWhite];
    [fuelGauge addChild:fuelGauge.needle];
    [fuelGauge addChild:fuelGauge.foreground];
    
    fuelGauge.needle.anchorPoint = CGPointMake(1, 0.5);
    fuelGauge.needle.position = CGPointMake(fuelGauge.needle.size.width/2, 0);
    
    NSInteger degrees = [AMBFuelGauge getDegreesForAmount:startingAmount];
    fuelGauge.needle.zRotation = DegreesToRadians(degrees);


    
    return fuelGauge;
}


- (void)addFuel:(NSInteger)amt {
    _fuelAmount = MIN(_fuelAmount + amt, fuelCapacity);
    NSInteger degrees = [AMBFuelGauge getDegreesForAmount:_fuelAmount];
    
    [_backgroundWhite runAction:sFuelGaugeFlash];
    
    [_needle removeAllActions];
    
    SKAction *rotate = [SKAction rotateToAngle:DegreesToRadians(degrees) duration:0.75 shortestUnitArc:YES];
    rotate.timingMode = SKActionTimingEaseOut;
    [_needle runAction:rotate completion:^(void){
        
        [self startNeedleAnimation];
    }];

}

+ (NSInteger)getDegreesForAmount:(NSInteger)amt {
    // 124 degrees total rotation
    // -62 degrees: FULL
    // 62 degrees:  EMPTY
    // (fuel)/capacity = pct

    return -(amt - (fuelCapacity/2));
}


- (CGSize)size {
    return self.background.size;
}



- (void)updateWithTimeSinceLastUpdate:(CFTimeInterval)delta {

    if (_fuelIsBeingUsed) {
        
        _fuelTimer += delta;
        
        if (_fuelTimer >= fuelUnitDuration) {
            _fuelTimer = 0; // reset the timer
            _fuelAmount--;  // decrement fuel
            
            if (_fuelAmount == 0) {
                _fuelIsBeingUsed = NO;
                [self outOfFuel];
                
            } // fuelAmount = 0
            
        } // fuelTimer > fuelUnitDuration
        
    } // fuelIsBeingUsed
    

    
}

- (void)startTimer {
    _fuelIsBeingUsed = YES;
    [self startNeedleAnimation];
    self.paused = NO;
    
}

- (void)startNeedleAnimation {
    // needle action
    if (![_needle actionForKey:@"timer"] && _fuelIsBeingUsed) {
        NSTimeInterval timeTilEmpty = ( _fuelAmount / fuelCapacity ) * (fuelUnitDuration * fuelCapacity);
        SKAction *timer = [SKAction rotateToAngle:DegreesToRadians(62) duration:timeTilEmpty shortestUnitArc:YES];
        [_needle runAction:timer withKey:@"timer"];
    }

}

- (void)stopTimer {
    _fuelIsBeingUsed = NO;
    self.paused = YES;
}

- (void)outOfFuel {
    _isOutOfFuel = YES;

    AMBLevelScene *scene = (AMBLevelScene *)self.scene;
    [scene gameOverBecause:GameOverReasonOutOfFuel];
}

+ (void)loadSharedAssets {
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        SKTextureAtlas *gameObjectSprites = [SKTextureAtlas atlasNamed:@"GameObjectSprites"];
        sFuelGaugeBackground = [gameObjectSprites textureNamed:@"fuelgauge_bg"];
        sFuelGaugeBackgroundWhite = [gameObjectSprites textureNamed:@"fuelgauge_bg_white"];
        sFuelGaugeForeground = [gameObjectSprites textureNamed:@"fuelgauge_inner-dial"];
        sFuelGaugeNeedle = [gameObjectSprites textureNamed:@"fuelgauge_needle"];
        
        sFuelGaugeFlash = [SKAction sequence:@[[SKAction fadeAlphaTo:0.8 duration:0.075], [SKAction fadeAlphaTo:0.0 duration:0.25]]];
        
    });
    
}


static SKTexture *sFuelGaugeBackground = nil;
static SKTexture *sFuelGaugeBackgroundWhite = nil;
static SKTexture *sFuelGaugeNeedle = nil;
static SKTexture *sFuelGaugeForeground = nil;
static SKAction *sFuelGaugeFlash = nil;



@end
