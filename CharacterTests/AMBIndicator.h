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

@interface AMBIndicator : NSObject

@property (nonatomic) NSMutableArray *targetObjects;



- (void)addTarget:(id)object;
- (void)removeTarget:(id)object;
- (BOOL)targetIsOnscreen:(SKSpriteNode *)target;

@end
