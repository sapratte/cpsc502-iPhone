//
//  RetailTabBarController.m
//  SOD-iOS-Client
//
//  Created by Sydney Pratte on 2015-03-22.
//  Copyright (c) 2015 ASE Group. All rights reserved.
//

#import "RetailTabBarController.h"
#import "FlyerMenu.h"
#import "Flyer.h"

@interface RetailTabBarController ()

@end

@implementation RetailTabBarController {
	
	BOOL chooseflyer;
	UIButton* button;
	FlyerMenu *menu;
}


- (void)viewWillAppear:(BOOL)animated {
	
	NSArray *selectedImages = @[@"scan_selected@2x.png", @"social_selected@2x.png", @"wishlist_selected@2x.png", @"accsel@2x.png"];
	NSArray *images = @[@"scan@2x.png", @"social@2x.png", @"wishlist@2x.png", @"account@2x.png"];
	
	for (UITabBarItem *item in self.tabBar.items) {
		
		if (![item.title isEqualToString:@"Center"]) {
			item.selectedImage = [[UIImage imageNamed:selectedImages[item.tag]] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
			item.image = [[UIImage imageNamed:images[item.tag]] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
		}
	}
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
	
	
	
	[super viewDidLoad];
	
	UIImage *buttonImage;
	
	// Set the tab bar background
	self.tabBar.backgroundImage = [UIImage imageNamed:@"tabbar.png"];
	self.selectedIndex = 2;
	chooseflyer = NO;
	
	// Test
	for (UITabBarItem *item in self.tabBar.items)
	{
		NSLog(@"Height: %f, Weight: %f", self.tabBar.frame.size.height, self.tabBar.frame.size.width);
		
		if ([item.title isEqualToString:@"Center"]) {
			if (!chooseflyer)
				buttonImage = [UIImage imageNamed:@"flyer.png"];
			else
				buttonImage = [UIImage imageNamed:@"flyer_selected.png"];
		}
	}
	
	button = [UIButton buttonWithType:UIButtonTypeCustom];
	button.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin;
	button.frame = CGRectMake(0.0, 0.0, buttonImage.size.width, buttonImage.size.height);
	[button setBackgroundImage:buttonImage forState:UIControlStateNormal];
	
	
	CGFloat heightDifference = buttonImage.size.height - self.tabBar.frame.size.height;
	if (heightDifference < 0)
		button.center = self.tabBar.center;
	else
	{
		CGPoint center = self.tabBar.center;
		center.y = center.y - heightDifference/2.0;
		button.center = center;
	}
	
	[button addTarget:self action:@selector(flyerButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
	
	[self.view addSubview:button];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)flyerButtonPressed:(UIButton *)sender
{
	self.selectedIndex = 2;
	chooseflyer = !chooseflyer;
	if (chooseflyer) {
		[button setBackgroundImage:[UIImage imageNamed:@"flyer_selected.png"] forState:UIControlStateNormal];
		[self displayFlyerMenu];
	}
	else {
		[button setBackgroundImage:[UIImage imageNamed:@"flyer.png"] forState:UIControlStateNormal];
		[menu removeFromSuperview];
	}
}


// Create the flyer options menu and diplay it
- (void)displayFlyerMenu
{
	CGRect frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height - self.tabBar.frame.size.height);
	NSArray *items = [self makeMenuItems];
	menu = [[FlyerMenu alloc] initWithFrame:frame andWithMenuItems:items atPoint:self.tabBar.center];
	
	[self.view addSubview:menu];
	[self.view bringSubviewToFront:button];
}

// Make the buttons for the flyer menu
- (NSArray *)makeMenuItems
{
	CGRect frame = CGRectMake(0, 0, 39, 39);
	Flyer *item1 = [[Flyer alloc] initWithFrame:frame andName:@"Sport 1" andWithImage:[UIImage imageNamed:@"subnav.png"]];
	Flyer *item2 = [[Flyer alloc] initWithFrame:frame andName:@"Sport 2" andWithImage:[UIImage imageNamed:@"subnav.png"]];
	Flyer *item3 = [[Flyer alloc] initWithFrame:frame andName:@"Sport 3" andWithImage:[UIImage imageNamed:@"subnav.png"]];
	
	NSArray *items = @[item1, item2, item3];
	return items;
}






/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
