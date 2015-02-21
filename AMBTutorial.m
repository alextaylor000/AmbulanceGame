//
//  AMBTutorial.m
//  AmbulanceGame
//
//  Created by Alex Taylor on 2015-02-20.
//  Copyright (c) 2015 Alex Taylor. All rights reserved.
//

#import "AMBTutorial.h"

@implementation AMBTutorial

- (instancetype)init {
    if (self = [super init]) {
        _tutorialState = TutorialStateStep01;
    }
    
    return self;
}

- (void)playerDidPerformEvent:(PlayerEvent)event {
    
    switch (_tutorialState) {
        case TutorialStateStep01:
            if (event == PlayerEventStartMoving || event == PlayerEventStartMoving) {
                // step 02
            }
    
            break;

        case TutorialStateStep02:
            //
            break;

        case TutorialStateStep03:
            //
            break;

        case TutorialStateStep04:
            //
            break;

        case TutorialStateStep05:
            //
            break;

        case TutorialStateStep06:
            //
            break;

        case TutorialStateStep07:
            //
            break;

        case TutorialStateStep08:
            //
            break;
            
    }
    
}

@end
