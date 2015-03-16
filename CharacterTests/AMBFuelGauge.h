//
//  AMBFuelGauge.h
//  AmbulanceGame
//
//  Created by Alex Taylor on 2015-03-15.
//  Copyright (c) 2015 Alex Taylor. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

static const NSInteger fuelCapacity = 124; // 124 total degrees in the gauge's rotation, this makes it easier

@interface AMBFuelGauge : SKNode

+ (AMBFuelGauge *)fuelGaugeWithAmount:(NSInteger)startingAmount;
+ (void)loadSharedAssets;
- (void)addFuel:(NSInteger)amt;

@property (nonatomic) NSInteger fuelAmount;


@end
