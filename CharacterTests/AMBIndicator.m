//
//  AMBIndicator.m
//  CharacterTests
//
//  Created by Alex Taylor on 2014-11-16.
//  Copyright (c) 2014 Alex Taylor. All rights reserved.
//

#import "AMBIndicator.h"

@interface AMBIndicator ()



@end

@implementation AMBIndicator

- (id)init {
    if (self = [super init]) {
        _targetObjects = [[NSMutableArray alloc]init];
    }
    
    return self;
}

- (void)addTarget:(id)object {
    NSMutableDictionary *targetDict = [[NSMutableDictionary alloc]initWithCapacity:2];
    
    [targetDict setObject:object forKey:@"target"];
    [_targetObjects addObject:targetDict];

}

- (void)removeTarget:(id)object {
    [_targetObjects enumerateObjectsUsingBlock:^(id arrObj, NSUInteger idx, BOOL *stop) {
        id targetObject = [arrObj valueForKey:@"target"];
        if ([targetObject isEqualTo:object]) {
            [_targetObjects removeObjectAtIndex:idx];
            *stop = YES;
        }
    }];
}


@end
