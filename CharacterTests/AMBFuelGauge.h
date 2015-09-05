//
//  AMBFuelGauge.h
//  AmbulanceGame
//
//  Created by Alex Taylor on 2015-03-15.
//  Copyright (c) 2015 Alex Taylor. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>
//#import "AMBConstants.h"

@interface AMBFuelGauge : SKSpriteNode 

@property (nonatomic) CGFloat fuelAmount;
@property BOOL fuelIsBeingUsed;
@property BOOL isOutOfFuel;
@property CGFloat fuelTimer; // times when the fuel started being depleted by startMoving

+ (AMBFuelGauge *)fuelGaugeWithAmount:(NSInteger)startingAmount;
+ (void)loadSharedAssets;
- (void)updateWithTimeSinceLastUpdate:(CFTimeInterval)delta;
- (void)addFuel:(NSInteger)amt;
- (void)startTimer;
- (void)stopTimer;





@end
