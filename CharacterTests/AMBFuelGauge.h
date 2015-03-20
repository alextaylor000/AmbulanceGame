//
//  AMBFuelGauge.h
//  AmbulanceGame
//
//  Created by Alex Taylor on 2015-03-15.
//  Copyright (c) 2015 Alex Taylor. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

static const CGFloat fuelCapacity = 124; // 124 total degrees in the gauge's rotation, this makes it easier

/** Number of seconds a single unit of fuel lasts for. */
static const CGFloat fuelUnitDuration = 0.25;

/** Amount of fuel you get when you run over a fuel powerup */
static const NSInteger fuelUnitsInPowerup = 4;

@interface AMBFuelGauge : SKSpriteNode 

@property (nonatomic) CGFloat fuelAmount;
@property BOOL fuelIsBeingUsed;
@property CGFloat fuelTimer; // times when the fuel started being depleted by startMoving

+ (AMBFuelGauge *)fuelGaugeWithAmount:(NSInteger)startingAmount;
+ (void)loadSharedAssets;
- (void)updateWithTimeSinceLastUpdate:(CFTimeInterval)delta;
- (void)addFuel:(NSInteger)amt;
- (void)startTimer;
- (void)stopTimer;





@end
