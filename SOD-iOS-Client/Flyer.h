//
//  Flyer.h
//  BrigadeiPhone
//
//  Created by Sydney Pratte on 2/20/2014.
//  Copyright (c) 2014 Sydney Pratte. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface Flyer : UIButton

@property (nonatomic, weak) NSString* itemName;
@property (nonatomic, weak) UIImage *image;
@property (nonatomic, weak) UIImage *highlightedImage;

- (id)initWithFrame:(CGRect)frame andName:(NSString *)name andWithImage:(UIImage *)image;

@end
