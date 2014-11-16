//
//  AMBIndicator.m
//  CharacterTests
//
//  Created by Alex Taylor on 2014-11-16.
//  Copyright (c) 2014 Alex Taylor. All rights reserved.
//

#import "AMBIndicator.h"

@interface AMBIndicator ()

@property (nonatomic) NSMutableArray *targetObjectSprites; // stores references to the sprites generated

@end

@implementation AMBIndicator

- (id)init {
    if (self = [super init]) {
        _targetObjects = [[NSMutableArray alloc]init];
    }
    
    return self;
}

- (void)addTarget:(id)object {
    [_targetObjects addObject:object];

}

- (void)removeTarget:(id)object {
    [_targetObjects removeObject:object];
}


@end
