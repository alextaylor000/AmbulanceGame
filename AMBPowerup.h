//
//  AMBPowerup.h
//  CharacterTests
//
//  Created by Alex Taylor on 2014-12-04.
//  Copyright (c) 2014 Alex Taylor. All rights reserved.
//

#import "AMBConstants.h"
#import "AMBCharacter.h"


typedef NS_ENUM(int, AMBPowerupType) {
    AMBPowerupFuel,
    AMBPowerupInvincibility
};


@interface AMBPowerup : AMBCharacter

- (instancetype)initAsType:(AMBPowerupType)type;

@end
