//
//  ViewController.m
//  GameCenter
//
//  Created by mac1 on 15/9/25.
//  Copyright © 2015年 zjf. All rights reserved.
//

#import "ViewController.h"
#import "GameCenter.h"
#import "AppleInAppPurchase.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];


    // Dispose of any resources that can be recreated.
}


- (void)loginCallback:(id)sender
{

    [[GameCenter getInstance] loginGameCenter:^(GameCenterLoginCallbackVO *result) {
        
    }];

}

- (void)rechargeCallback:(id)sender
{
    [[AppleInAppPurchase getInstance] purchase:@"ddtank_coin_4.99" payload:@"helloWorld1234helloWorld1234helloWorld1234helloWorld1234--helloWorld1234" callback:^(AppleInAppPurchaseCallbackVO *result) {

    }];
}




@end
