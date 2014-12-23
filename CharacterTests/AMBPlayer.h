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

typedef enum {
    PlayerControlsStartMoving,
    PlayerControlsStopMoving,
    PlayerControlsTurnLeft,
    PlayerControlsTurnRight
} PlayerControls;


@interface AMBPlayer : AMBMovingCharacter

@property AmbulanceState state;
@property AMBPatient *patient;
@property CGFloat fuel;
@property CGFloat laneChangeDegrees; // target degrees for lane change

- (void)changeState:(AmbulanceState)newState;
- (BOOL)loadPatient:(AMBPatient *)patient;
- (BOOL)unloadPatient;
- (void)handleInput:(PlayerControls)input keyDown:(BOOL)keyDown;
@end
