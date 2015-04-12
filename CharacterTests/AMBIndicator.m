//
//  AMBIndicator.m
//  CharacterTests
//
//  Created by Alex Taylor on 2014-11-16.
//  Copyright (c) 2014 Alex Taylor. All rights reserved.
//

#import "AMBConstants.h"
#import "AMBIndicator.h"
#import "AMBCamera.h"
#import "AMBLevelScene.h"
#import "SKTUtils.h"

#import "AMBHospital.h" // we need access to these to test for class type
#import "AMBPatient.h"
#import "AMBPowerup.h"



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

- (void)addTarget:(id)object type:(IndicatorType)type {
    NSMutableDictionary *targetDict = [[NSMutableDictionary alloc]initWithCapacity:2];
    // TODO: we don't use type here at the moment, do we need it?
    [targetDict setObject:object forKey:@"target"];
    [_targetObjects addObject:targetDict];

}

- (void)removeTarget:(id)object {
    [_targetObjects enumerateObjectsUsingBlock:^(id arrObj, NSUInteger idx, BOOL *stop) {
        id targetObject = [arrObj valueForKey:@"target"];
//        if ([targetObject isEqualTo:object]) { // no known instance of isEqualTo for iOS target
        if (targetObject == object) {
            [arrObj[@"indicator"] removeFromParent];
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
            indicator = [self createIndicatorForNode:targetObject];
            [arrObj setObject:indicator forKey:@"indicator"];
            [_scene addChild:indicator];
            
        } else {
            indicator = [arrObj valueForKey:@"indicator"];
        }
        
        if ([self targetIsOnscreen:targetObject]) {
            [indicator runAction:[SKAction fadeOutWithDuration:OSI_DUR_FADE_OUT] completion:^(void){
                indicator.hidden = YES;
            }];
            
        } else {
            indicator.hidden = NO;

            [indicator runAction:[SKAction fadeInWithDuration:OSI_DUR_FADE_IN]]; // TODO: wtf, this is running every frame! bad coding!

            indicator.position = [self calculateIndicatorPositionForTarget:targetObject];
            indicator.zRotation = atan2f(indicator.position.y, indicator.position.x);
            
            SKSpriteNode *targetObjSprite = targetObject;

            if (targetObjSprite.parent == nil) {
#if DEBUG_INDICATOR
                NSLog(@"Removing indicator for target");
#endif
                [self removeTarget:targetObject];
            }
            
            
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

- (SKSpriteNode *)createIndicatorForNode:(SKNode *)node {

    NSString *spriteName;
    
    if ([node isKindOfClass:[AMBHospital class]]) {
            spriteName = @"osi_hospital";
    } else if ([node isKindOfClass:[AMBPatient class]]) {
            spriteName = @"osi_patient";
    }
    
    SKSpriteNode *indicator = [SKSpriteNode spriteNodeWithImageNamed:spriteName];
    indicator.zPosition = 100;
    indicator.name = spriteName;
    return indicator;
}

- (CGPoint)calculateIndicatorPositionForTarget:(SKSpriteNode *)target {

    CGFloat halfHeight = _scene.frame.size.height/2 - OSI_PADDING;
    CGFloat halfWidth = _scene.frame.size.width/2 - OSI_PADDING;
    
    CGPoint targetPos = [_scene.camera convertPoint:target.position fromNode:_scene.tilemap];
    targetPos = CGPointRotate(targetPos, RadiansToDegrees(_scene.camera.rotation)); // apply the camera's effective rotation. remember, it's the worldnode that is rotating, so the camera actually never rotates
    
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
