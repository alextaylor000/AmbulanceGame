//
//  AMBIndicator.m
//  CharacterTests
//
//  Created by Alex Taylor on 2014-11-16.
//  Copyright (c) 2014 Alex Taylor. All rights reserved.
//

#import "AMBIndicator.h"
#import "AMBCamera.h"
#import "AMBLevelScene.h"
#import "SKTUtils.h"



@interface AMBIndicator ()

@property (nonatomic)AMBLevelScene *scene;

@end

@implementation AMBIndicator

        


- (instancetype)initForScene:(AMBLevelScene *)scene {
    if (self = [super init]) {
        _targetObjects = [[NSMutableArray alloc]init];
        
        // store the scene and camera so we can reference its positioning in the update loop
        _scene = scene;
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

- (void)update {
    [_targetObjects enumerateObjectsUsingBlock:^(id arrObj, NSUInteger idx, BOOL *stop) {
        id targetObject = [arrObj valueForKey:@"target"];
        
        SKSpriteNode *indicator;
        
        if ([arrObj valueForKey:@"indicator"] == nil) {
            indicator = [self createIndicator];
            [arrObj setObject:indicator forKey:@"indicator"];
            [_scene addChild:indicator];
            
        } else {
            indicator = [arrObj valueForKey:@"indicator"];
        }
        
        if ([self targetIsOnscreen:targetObject]) {
            indicator.hidden = YES;
        } else {
            indicator.hidden = NO;
            indicator.position = [self calculateIndicatorPositionForTarget:targetObject];
            indicator.zRotation = atan2f(indicator.position.y, indicator.position.x);
        }

    }];
}

- (BOOL)targetIsOnscreen:(SKSpriteNode *)target {
    CGPoint targetPos = target.position;
    CGRect screenRect;
    screenRect.origin = CGPointMake(_scene.camera.position.x - (_scene.size.width/2), _scene.camera.position.y - (_scene.size.height/2));
    screenRect.size = _scene.size;
    
    if (CGRectContainsPoint(screenRect, [target.parent convertPoint:targetPos toNode:_scene.camera])) {
        return YES;
    }

    return NO;
}

- (SKSpriteNode *)createIndicator {
    SKSpriteNode *indicator = [SKSpriteNode spriteNodeWithImageNamed:@"osi_hospital"];
    indicator.zPosition = 100;
    return indicator;
}

- (CGPoint)calculateIndicatorPositionForTarget:(SKSpriteNode *)target {

    CGFloat halfHeight = _scene.frame.size.height/2 - 40; // 20 points of padding from screen edge
    CGFloat halfWidth = _scene.frame.size.width/2 - 40;
    
    CGPoint targetPos = [_scene.camera convertPoint:target.position fromNode:_scene.tilemap];
    targetPos = CGPointRotate(targetPos, RadiansToDegrees(_scene.camera.rotation)); // apply the camera's effective rotation. remember, it's the worldnode that is rotating, so the camera actually never rotates
    
#if DEBUG
    NSLog(@"targetPos=%1.0f,%1.0f",targetPos.x,targetPos.y);
#endif
    CGFloat slope = targetPos.y / targetPos.x;
    CGPoint indicatorPos;
    
    if (targetPos.y > 0) {
        indicatorPos = CGPointMake(halfHeight / slope, halfHeight);
    } else {
        indicatorPos = CGPointMake(-halfHeight / slope, -halfHeight);
    }
    
    if (indicatorPos.x > halfWidth) {
        indicatorPos = CGPointMake(halfWidth, halfWidth * slope);
    } else if (indicatorPos.x < -halfWidth) {
        indicatorPos = CGPointMake(-halfWidth, -halfWidth * slope);
    }
   
    return indicatorPos;
    
}

@end
