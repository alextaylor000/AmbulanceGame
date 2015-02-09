//
//  AMBPowerup.h
//  CharacterTests
//
//  Created by Alex Taylor on 2014-12-04.
//  Copyright (c) 2014 Alex Taylor. All rights reserved.
//

#import "AMBCharacter.h"

static const CGFloat FUEL_EXPIRY_DURATION = 20;
static const CGFloat FUEL_TIMER_INCREMENT = 40; // every x seconds, the fuel gets decremented

typedef NS_ENUM(int, AMBPowerupType) {
    AMBPowerupFuel,
    AMBPowerupInvincibility
};


@interface AMBPowerup : AMBCharacter

- (instancetype)initAsType:(AMBPowerupType)type;

@end
