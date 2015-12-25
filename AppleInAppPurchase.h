//
//  AppleInAppPurchase.h
//  GameCenter
//
//  Created by mac1 on 15/9/29.
//  Copyright © 2015年 zjf. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>

typedef enum
{
    CodeStatusPruchaseSuccess        = 0x0001,      //支付成功
    CodeStatusRequestProductFailed   = 0x0002,      //请求商品失败
    CodeStatusPurchaseFailed         = 0x0003,      //支付失败
}CodeStatus;

@interface AppleInAppPurchaseCallbackVO : NSObject
{
}
@property(nonatomic,assign)int16_t codeStatus;
@property(nonatomic,retain)NSString* message;
@property(nonatomic,retain)NSString* receipt;
@property(nonatomic,retain)NSString* orderId;
@property(nonatomic,retain)NSString* productId;
@property(nonatomic,retain)NSString* payload;

@end

typedef void (^AppleInAppPurchaseCallback)(AppleInAppPurchaseCallbackVO* result);

@interface AppleInAppPurchase : NSObject<SKProductsRequestDelegate,SKPaymentTransactionObserver>
{
@private
    BOOL _isSupportInAppPurchase;
    NSArray* _requestProductsArray;
}

@property(nonatomic,assign)BOOL isSupportInAppPurchase;

+ (AppleInAppPurchase*)getInstance;
+ (void)destroyInstance;

// 获取商品信息
- (NSArray*)getProductsInfo;

//发起支付请求
- (void)purchase:(NSString*)productId payload:(NSString*)payload callback:(AppleInAppPurchaseCallback)callback;

//完成订单交易
- (void)finishTransaction:(NSString*)orderId;

//恢复库存订单
- (void)restoreInventoryOrder:(AppleInAppPurchaseCallback)callback;

@end
