//
//  AMBFuelGauge.m
//  AmbulanceGame
//
//  Created by Alex Taylor on 2015-03-15.
//  Copyright (c) 2015 Alex Taylor. All rights reserved.
//

#import "AMBFuelGauge.h"
#import "SKTUtils.h"

@interface AMBFuelGauge ()

@property SKSpriteNode *needle;

@end

@implementation AMBFuelGauge

+ (AMBFuelGauge *)fuelGaugeWithAmount:(NSInteger)startingAmount {
    AMBFuelGauge *fuelGauge = [AMBFuelGauge node];
    
    SKSpriteNode *background =  [SKSpriteNode spriteNodeWithTexture:sFuelGaugeBackground];
    fuelGauge.needle =      [SKSpriteNode spriteNodeWithTexture:sFuelGaugeNeedle];
    SKSpriteNode *foreground =  [SKSpriteNode spriteNodeWithTexture:sFuelGaugeForeground];
    
    [fuelGauge addChild:background];
    [fuelGauge addChild:fuelGauge.needle];
    [fuelGauge addChild:foreground];
    
    fuelGauge.needle.anchorPoint = CGPointMake(1, 0.5);
    fuelGauge.needle.position = CGPointMake(fuelGauge.needle.size.width/2, 0);
    
    NSInteger degrees = [AMBFuelGauge getDegreesForAmount:startingAmount];
    fuelGauge.needle.zRotation = DegreesToRadians(degrees);
    return fuelGauge;
}


- (void)addFuel:(NSInteger)amt {
    _fuelAmount = MIN(_fuelAmount + amt, fuelCapacity);
    NSInteger degrees = [AMBFuelGauge getDegreesForAmount:_fuelAmount];
    
    SKAction *rotate = [SKAction rotateToAngle:DegreesToRadians(degrees) duration:1 shortestUnitArc:YES];
    [_needle runAction:rotate];

}

+ (NSInteger)getDegreesForAmount:(NSInteger)amt {
    // 124 degrees total rotation
    // -62 degrees: FULL
    // 62 degrees:  EMPTY
    // (fuel)/capacity = pct

    return -(amt - (fuelCapacity/2));
}



+ (void)loadSharedAssets {
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        SKTextureAtlas *gameObjectSprites = [SKTextureAtlas atlasNamed:@"GameObjectSprites"];
        sFuelGaugeBackground = [gameObjectSprites textureNamed:@"fuelgauge_bg"];
        sFuelGaugeForeground = [gameObjectSprites textureNamed:@"fuelgauge_inner-dial"];
        sFuelGaugeNeedle = [gameObjectSprites textureNamed:@"fuelgauge_needle"];
        
    });
    
}


static SKTexture *sFuelGaugeBackground = nil;
static SKTexture *sFuelGaugeNeedle = nil;
static SKTexture *sFuelGaugeForeground = nil;



@end
