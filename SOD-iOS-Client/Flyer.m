//
//  Flyer.m
//  BrigadeiPhone
//
//  Created by Sydney Pratte on 2/20/2014.
//  Copyright (c) 2014 Sydney Pratte. All rights reserved.
//

#import "Flyer.h"

@implementation Flyer

@synthesize itemName;
@synthesize image = _image;
@synthesize highlightedImage = _highlightedImage;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame andName:(NSString *)name andWithImage:(UIImage *)image
{
    self = [super initWithFrame:frame];
    if (self) {
        
        _image = image;
        
        self = [UIButton buttonWithType:UIButtonTypeCustom];
        self.frame = frame;
        [self setImage:image forState:UIControlStateNormal];
        
        self.titleLabel.text = name;
        [self.titleLabel setHidden:YES];
        
    }
    return self;
}

@end
