//
//  ViewController.h
//  SOD-iOS-Client
//
//  Created by ASE Group on 3/13/2014.
//  Copyright (c) 2014 ASE Group. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController <UITextFieldDelegate>
@property (retain, nonatomic) IBOutlet UITextView *txtStatus;
@property (retain, nonatomic) IBOutlet UITextField *userSpecifiedID;

@end
