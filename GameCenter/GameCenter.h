//
//  GameCenter.h
//  GameCenter
//
//  Created by mac1 on 15/9/25.
//  Copyright © 2015年 zjf. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


@interface GameCenterLoginCallbackVO : NSObject
{
}

@property(nonatomic,assign)BOOL isSuccess;
@property(nonatomic,retain)NSString* message;
@property(nonatomic,retain)NSString* certificateData;
@property(nonatomic,retain)NSString* signature;
@property(nonatomic,retain)NSString* signatureData;
@property(nonatomic,retain)NSString* playerID;
@property(nonatomic,retain)NSString* displayName;
@end

typedef void (^GameCenterLoginCallback)(GameCenterLoginCallbackVO* result);

@interface GameCenter : NSObject
{
}

+ (GameCenter*)getInstance;
+ (void)destroyInstance;

- (void)loginGameCenter:(GameCenterLoginCallback) callback;

@end
