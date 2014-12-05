//
//  AMBIndicator.h
//  CharacterTests
//
//  Created by Alex Taylor on 2014-11-16.
//  Copyright (c) 2014 Alex Taylor. All rights reserved.
//
//  Manages the on-screen indicators

#import <Foundation/Foundation.h>
#import <SpriteKit/SpriteKit.h>

typedef enum {
    IndicatorHospital,
    IndicatorPatient,
    IndicatorFuel
} IndicatorType;

@interface AMBIndicator : NSObject

@property (nonatomic) NSMutableArray *targetObjects;


- (instancetype)initForScene:(SKScene *)scene;
- (void)addTarget:(id)object type:(IndicatorType)type;
- (void)removeTarget:(id)object;

- (void)update;


@end
