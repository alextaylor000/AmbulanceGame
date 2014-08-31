//
//  XXXPatient.m
//  CharacterTests
//
//  Created by Alex Taylor on 2014-08-30.
//  Copyright (c) 2014 Alex Taylor. All rights reserved.

/*
 
 Patient Class
 
 Properties:
 - Severity Rating 
    - # medical supplies (defined elsewhere through severity)
    - Time to Live (defined elsewhere through severity)
 - Position
 - Sprite object (before they're picked up)
 - State
    - waiting for pickup
    - picked up
    - delivered
    - died
 
 
*/

#import "XXXPatient.h"

@implementation XXXPatient


- (instancetype) initWithSeverity:(PatientSeverity)severity position:(CGPoint)position {
    if (self = [super initWithImageNamed:@"patient01.png"]) {
        // TODO: Variable image (swap out with appropriate level # indicator)
        self.position = position;

        self.severity = severity;
        self.state = WaitingForPickup;
    }
    
    return self;
}





@end
