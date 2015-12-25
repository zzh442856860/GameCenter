
//  GameCenter.m
//  GameCenter
//
//  Created by mac1 on 15/9/25.
//  Copyright © 2015年 zjf. All rights reserved.
//

#import "GameCenter.h"
#import <GameKit/GameKit.h>
#import <CommonCrypto/CommonDigest.h>
#import "GTMBase64.h"

#pragma mark -- GameCenterLoginCallbackVO
@implementation GameCenterLoginCallbackVO
@synthesize message = _message;
@synthesize certificateData = _certificateData;
@synthesize signature = _signature;
@synthesize signatureData = _signatureData;
@synthesize playerID = _playerID;
@synthesize displayName = _displayName;

- (id)init:(BOOL)isSuccess message:(NSString*)message
{
    self = [super init];
    if (self) {
        isSuccess = NO;
    }

    return self;
}

- (void)dealloc
{
    [_message release];
    [_certificateData release];
    [_signature release];
    [_signatureData release];
    [_playerID release];
    [_displayName release];
    [super dealloc];
}
@end

#pragma mark -- GameCenter
static GameCenter* _instance = nil;
static UIActivityIndicatorView* _activityIndicatorView;
static BOOL _isFirstLogin = YES;
static UIViewController* _currentGameCenterController;
static GameCenterLoginCallback _gameCenterLoginCallback;
@implementation GameCenter


+(GameCenter*)getInstance
{
    if (_instance == nil) {
        _instance = [[GameCenter alloc] init];
    }
    return _instance;
}

+(void)destroyInstance
{
    if (_instance) {
        [_instance release];
        _instance = nil;
    }
}
- (id)init
{
    self = [super init];
    if (self) {
        _currentGameCenterController = nil;
        _gameCenterLoginCallback = nil;

        UIWindow* window = [[UIApplication sharedApplication] keyWindow];
        _activityIndicatorView = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0, 0, window.frame.size.width, window.frame.size.height)];
        _activityIndicatorView.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhiteLarge;
        _activityIndicatorView.color = [UIColor blackColor];
        [_activityIndicatorView setCenter:window.center];
        [window addSubview:_activityIndicatorView];
    }
    return self;
}


- (void)dealloc
{
    if (_activityIndicatorView) {
        [_activityIndicatorView release];
        _activityIndicatorView = nil;
    }
    [super dealloc];
}


- (BOOL) initGameCenter
{
    Class gcClass = (NSClassFromString(@"GKLocalPlayer"));
    NSString *reqSysVer = @"4.1";
    NSString *currSysVer = [[UIDevice currentDevice] systemVersion];
    BOOL osVersionSupported = ([currSysVer compare:reqSysVer options:NSNumericSearch] != NSOrderedAscending);
    return (gcClass && osVersionSupported);
}


- (void)loginGameCenter:(GameCenterLoginCallback)callback
{
    _gameCenterLoginCallback = callback;
    if (![self initGameCenter])
    {
        _gameCenterLoginCallback([[[GameCenterLoginCallbackVO alloc] init:NO message:@"no-support-game-center"] autorelease]);
        return;
    }
    [_activityIndicatorView startAnimating];

    if ([GKLocalPlayer localPlayer].isAuthenticated) {
        [self loginGameCenterSuccessCallback];
    }
    else
    {
        if (!_isFirstLogin)
        {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"gamecenter:"]];
        }

        [GKLocalPlayer localPlayer].authenticateHandler = ^(UIViewController *viewController, NSError *error){

            if (viewController) {
                [_activityIndicatorView stopAnimating];
                if (_isFirstLogin) {
                    _currentGameCenterController = [[UIViewController alloc] init];
                    UIWindow* window = [[UIApplication sharedApplication] keyWindow];
                    [window addSubview:[_currentGameCenterController view]];
                    [_currentGameCenterController presentViewController:viewController animated: YES completion:nil];
                }
                _isFirstLogin = NO;
            }
            else if ([GKLocalPlayer localPlayer].isAuthenticated)
            {
                _isFirstLogin = NO;
                if (_currentGameCenterController) {
                    [_currentGameCenterController dismissViewControllerAnimated:NO completion:nil];
                    [_currentGameCenterController.view removeFromSuperview];
                    [_currentGameCenterController release];
                    _currentGameCenterController = nil;
                }

                [self loginGameCenterSuccessCallback];
            }
            else
            {
                [_activityIndicatorView stopAnimating];
                if (_isFirstLogin) {
                    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"gamecenter:"]];
                }
                _isFirstLogin = NO;
                if (_currentGameCenterController) {
                    [_currentGameCenterController dismissViewControllerAnimated:NO completion:nil];
                    [_currentGameCenterController.view removeFromSuperview];
                    [_currentGameCenterController release];
                    _currentGameCenterController = nil;
                }
            }
        };
    }

}


- (void)loginGameCenterSuccessCallback
{

    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0) {
        [[GKLocalPlayer localPlayer] generateIdentityVerificationSignatureWithCompletionHandler:^(NSURL * _Nullable publicKeyUrl, NSData * _Nullable signature, NSData * _Nullable salt, uint64_t timestamp, NSError * _Nullable error) {
            [_activityIndicatorView startAnimating];
            NSMutableString* saveKeyValue = [NSMutableString stringWithString:@"GameCenterLoginVerify_"];
            [saveKeyValue appendString:publicKeyUrl.absoluteString];

            NSString* certificateData = [[NSUserDefaults standardUserDefaults] stringForKey:saveKeyValue];
            if (certificateData == nil) {
                NSData *contentData = [NSData dataWithContentsOfURL:publicKeyUrl];
                certificateData = [GTMBase64 stringByEncodingData:contentData];
                [[NSUserDefaults standardUserDefaults] setObject:certificateData forKey:saveKeyValue];
                [[NSUserDefaults standardUserDefaults] synchronize];
            }

            //build payload
            NSMutableData *payload = [[NSMutableData alloc] init];
            [payload appendData:[[GKLocalPlayer localPlayer].playerID dataUsingEncoding:NSUTF8StringEncoding]];
            [payload appendData:[[[NSBundle mainBundle] bundleIdentifier] dataUsingEncoding:NSUTF8StringEncoding]];
            uint64_t timestampBE = CFSwapInt64HostToBig(timestamp);
            [payload appendBytes:&timestampBE length:sizeof(timestampBE)];
            [payload appendData:salt];

            GameCenterLoginCallbackVO* callbackVO = [[[GameCenterLoginCallbackVO alloc] init:YES message:@"Success"] autorelease];
            [callbackVO setCertificateData:certificateData];
            [callbackVO setSignatureData:[GTMBase64 stringByEncodingData:payload]];
            [callbackVO setSignature:[GTMBase64 stringByEncodingData:signature]];
            [callbackVO setPlayerID:[GKLocalPlayer localPlayer].playerID];
            [callbackVO setDisplayName:[GKLocalPlayer localPlayer].displayName];
            [_activityIndicatorView stopAnimating];

            _gameCenterLoginCallback(callbackVO);
        }];
    }
    else
    {
        [_activityIndicatorView stopAnimating];
        _gameCenterLoginCallback([[[GameCenterLoginCallbackVO alloc] init:NO message:@""] autorelease]);
    }
    
}
@end
