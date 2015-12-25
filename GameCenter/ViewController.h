//
//  ViewController.h
//  GameCenter
//
//  Created by mac1 on 15/9/25.
//  Copyright © 2015年 zjf. All rights reserved.
//

#import <UIKit/UIKit.h>
@interface ViewController : UIViewController

@property(nonatomic,assign) IBOutlet UIButton* loginButton;
@property(nonatomic,assign) IBOutlet UIButton* rechargeButton;


- (IBAction)loginCallback:(id)sender;
- (IBAction)rechargeCallback:(id)sender;

@end

