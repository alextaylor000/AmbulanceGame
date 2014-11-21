//
//  XXXCharacter.h
//  CharacterTests
//
//  Created by Alex Taylor on 2014-07-06.
//  Copyright (c) 2014 Alex Taylor. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>
#import "AMBMovingCharacter.h"
#import "AMBPatient.h"

typedef enum {
    AmbulanceIsOccupied,
    AmbulanceIsEmpty
} AmbulanceState;


@interface AMBPlayer : AMBMovingCharacter

@property AmbulanceState state;
@property AMBPatient *patient;

- (void)changeState:(AmbulanceState)newState;
- (BOOL)loadPatient:(AMBPatient *)patient;
- (BOOL)unloadPatient;
@end
