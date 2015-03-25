//
//  FlyerMenu.m
//  BrigadeiPhone
//
//  Created by Sydney Pratte on 2/20/2014.
//  Copyright (c) 2014 Sydney Pratte. All rights reserved.
//

#import "FlyerMenu.h"
#import "Flyer.h"

@implementation FlyerMenu {
    
    NSArray *menuItems;
    CGPoint point;
    CGFloat endRadius;
    CGFloat nearRadius;
    CGFloat farRadius;
    CGFloat menuAngle;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor colorWithRed:0/255.0f green:0/255.0f blue:0/255.0f alpha:0.75f];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame andWithMenuItems:(NSArray *)items atPoint:(CGPoint)p
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor colorWithRed:0/255.0f green:0/255.0f blue:0/255.0f alpha:0.75f];
        menuItems = items;
        point = p;
        endRadius = 100.0f;
        nearRadius = 90.0f;
        farRadius = 110.0;
        menuAngle = M_PI_2;
        
        [self openMenu];
    }
    return self;
}

// Animate menu opening
- (void)openMenu
{
    // add menu button items
    int count = [menuItems count];
    int n = 0;
    for (int i = 1; i <= [menuItems count]; i++)
    {
        CGPoint endPoint;
        CGPoint farPoint;
        CGPoint nearPoint;
        
        Flyer *item = [menuItems objectAtIndex:i-1];
        if (i == 1) {
            endPoint = CGPointMake(point.x + -endRadius * sinf(i * menuAngle / (count - 1)), point.y - endRadius * cosf(i * menuAngle / (count - 1)));
            farPoint = CGPointMake(point.x + -farRadius * sinf(i * menuAngle / (count - 1)), point.y - farRadius * cosf(i * menuAngle / (count - 1)));
            nearPoint = CGPointMake(point.x + -nearRadius * sinf(i * menuAngle / (count - 1)), point.y - nearRadius * cosf(i * menuAngle / (count - 1)));
        }
        else {
            endPoint = CGPointMake(point.x + endRadius * sinf(n * menuAngle / (count - 1)), point.y - endRadius * cosf(n * menuAngle / (count - 1)));
            farPoint = CGPointMake(point.x + farRadius * sinf(n * menuAngle / (count - 1)), point.y - farRadius * cosf(n * menuAngle / (count - 1)));
            nearPoint = CGPointMake(point.x + nearRadius * sinf(n * menuAngle / (count - 1)), point.y - nearRadius * cosf(n * menuAngle / (count - 1)));
            n++;
        }
        item.center = point;
        
        CAKeyframeAnimation *positionAnimation = [CAKeyframeAnimation animationWithKeyPath:@"position"];
        positionAnimation.duration = 0.30f;
        CGMutablePathRef path = CGPathCreateMutable();
        CGPathMoveToPoint(path, NULL, item.center.x, item.center.y);
        CGPathAddLineToPoint(path, NULL, farPoint.x, farPoint.y);
        CGPathAddLineToPoint(path, NULL, nearPoint.x, nearPoint.y);
        CGPathAddLineToPoint(path, NULL, endPoint.x, endPoint.y);
        positionAnimation.path = path;
        CGPathRelease(path);
        
        
        [item.layer addAnimation:positionAnimation forKey:@"id"];
        item.center = endPoint;
        
        [self addSubview:item];
    }
    
}


@end
