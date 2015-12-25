//
//  AppleInAppPurchase.m
//  GameCenter
//
//  Created by mac1 on 15/9/29.
//  Copyright © 2015年 zjf. All rights reserved.
//

#define PRODUCTS_INFO_SAVE_KEY  [NSString stringWithFormat:@"in-app-purchase-products-info-%@",[[NSBundle mainBundle] bundleIdentifier]]
#define PRODUCTIDS_SAVE_KEY  [NSString stringWithFormat:@"in-app-purchase-productIds-%@",[[NSBundle mainBundle] bundleIdentifier]]

#import "AppleInAppPurchase.h"


#pragma mark --AppleInAppPurchaseCallbackVO
@implementation AppleInAppPurchaseCallbackVO
@synthesize message = _message;
@synthesize receipt = _receipt;
@synthesize payload = _payload;
@synthesize productId = _productId;
@synthesize orderId = _orderId;
@synthesize codeStatus = _codeStatus;

- (id) init:(CodeStatus)codeStatus message:(NSString*)message;
{
    self = [super init];
    if (self) {
        _codeStatus = codeStatus;
        [self setMessage:message];
    }
    return self;
}

- (void)dealloc
{
    [_message release];
    [_receipt release];
    [_orderId release];
    [_productId release];
    [_payload release];
    [super dealloc];
}
@end

#pragma mark --AppleInAppPurchase

static AppleInAppPurchase* _instance = nil;
static UIActivityIndicatorView* _activityIndicatorView = nil;
static NSMutableArray* _transactions = nil;
static AppleInAppPurchaseCallback _purchaseCallback = nil;
static NSMutableArray* _productIds = nil;
static NSMutableArray* _productsInfo = nil;
static NSString* _previousProductID = nil;
static NSString* _previousPayload = nil;

@implementation AppleInAppPurchase
@synthesize isSupportInAppPurchase = _isSupportInAppPurchase;

+(AppleInAppPurchase*)getInstance
{

    if (nil == _instance) {
        _instance = [[AppleInAppPurchase alloc] init];
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

-(id) init
{

    self = [super init];
    if (self) {
        _requestProductsArray = nil;
        _productsInfo = [[NSMutableArray alloc] init];
        _transactions = [[NSMutableArray alloc] init];

        _isSupportInAppPurchase = YES;
        [[SKPaymentQueue defaultQueue] addTransactionObserver:self];

        if (![SKPaymentQueue canMakePayments]) {
            _isSupportInAppPurchase = NO;
            UIAlertView* alertView = [[[UIAlertView alloc] initWithTitle:nil message:@"no-suporot-In-App-Purchase" delegate:nil cancelButtonTitle:@"Sure" otherButtonTitles:nil, nil] autorelease];
            [alertView show];
        }

        UIWindow* window = [[UIApplication sharedApplication] keyWindow];
        _activityIndicatorView = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0, 0, window.frame.size.width, window.frame.size.height)];
        _activityIndicatorView.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhiteLarge;
        _activityIndicatorView.color = [UIColor blackColor];
        _activityIndicatorView.backgroundColor = [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:0.5];
        [_activityIndicatorView setCenter:window.center];
        [window addSubview:_activityIndicatorView];
    }
    return self;
}


-(void) dealloc
{

    if (_productsInfo) {
        [_productsInfo release];
        _productsInfo = nil;
    }

    if (_activityIndicatorView) {
        [_activityIndicatorView removeFromSuperview];
        [_activityIndicatorView release];
        _activityIndicatorView = nil;
    }

    if (_transactions) {
        [_transactions release];
        _transactions = nil;
    }

    if (_productIds) {
        [_productIds release];
        _productIds = nil;
    }

    if (_requestProductsArray) {
        [_requestProductsArray release];
        _requestProductsArray = nil;
    }

    if (_previousProductID) {
        [_previousProductID release];
        _previousProductID = nil;
    }

    if (_previousPayload) {
        [_previousPayload release];
        _previousPayload = nil;
    }

    [[SKPaymentQueue defaultQueue] removeTransactionObserver:self];
    [super dealloc];
}


- (void)purchase:(NSString*)productId payload:(NSString*)payload callback:(AppleInAppPurchaseCallback)callback
{
    if (!_isSupportInAppPurchase) {
        return;
    }
    _purchaseCallback = callback;
    if (_requestProductsArray==nil || _requestProductsArray.count <= 0) {
        [self startRequestProductsInfo:true];
        if (_previousProductID) {
            [_previousProductID release];
        }
        _previousProductID = productId;
        [_previousProductID retain];

        if (_previousPayload) {
            [_previousPayload release];
        }
        _previousPayload = payload;
        [_previousPayload retain];
        return;
    }

    for (SKProduct *product in _requestProductsArray) {
        if ([product.productIdentifier isEqualToString:productId]) {
            SKMutablePayment *payment = [SKMutablePayment paymentWithProduct:product];
            if (floor(NSFoundationVersionNumber) >= floor(NSFoundationVersionNumber_iOS_7_0)) {
                payment.applicationUsername = payload;
            }
            [[SKPaymentQueue defaultQueue] addPayment:payment];
        }
    }

}

//恢复库存订单
- (void)restoreInventoryOrder:(AppleInAppPurchaseCallback)callback
{
    _purchaseCallback = callback;
    for (SKPaymentTransaction *transaction in _transactions) {
        [self postTransactionToServer:transaction];
    }
}


- (NSArray*)getProductsInfo
{
    if (_productsInfo && [_productsInfo count] > 0)
    {
        return _productsInfo;
    }
    
    NSString* fullpath = [[NSBundle mainBundle] pathForResource:@"AppleInAppPurchaseProductsInfo.plist"
                                                         ofType:nil
                                                    inDirectory:@""];
    NSDictionary* dictionary = [[NSDictionary dictionaryWithContentsOfFile:fullpath] retain];

    NSMutableArray* productIds = [[NSMutableArray alloc] init];
    [_productsInfo removeAllObjects];



    for (NSDictionary* dic in [dictionary allValues])
    {
        [_productsInfo addObject:dic];
        [productIds addObject:[NSString stringWithFormat:@"%@",[dic objectForKey:@"productIdentifier"]]];
    }
    _productIds = productIds;

    return _productsInfo;
}


- (void)finishTransaction:(NSString*)orderId
{
    for (SKPaymentTransaction *transaction in _transactions)  {
        if ([transaction.transactionIdentifier isEqualToString:orderId]) {
            [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
            [_transactions removeObject:transaction];
        }
    }
}

- (void)startRequestProductsInfo:(BOOL)visible
{
    if (_isSupportInAppPurchase==NO) {
        return;
    }

    if (_productIds == nil || _productIds.count <= 0)
    {
        [self getProductsInfo];
    }


    if (visible) {
        [_activityIndicatorView startAnimating];
    }

    SKProductsRequest *request=[[SKProductsRequest alloc] initWithProductIdentifiers:[[[NSSet alloc] initWithArray:_productIds] autorelease]];
    [request setDelegate:self];
    [request start];
}

#pragma mark - SKProductsRequestDelegate
- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response
{
    NSArray* products = [[response products] retain];

    if (products && [products count] > 0) {
        if (_requestProductsArray) {
            [_requestProductsArray release];
        }
        _requestProductsArray = [[NSMutableArray alloc] initWithArray:products];

        [self purchase:_previousProductID payload:_previousPayload callback:_purchaseCallback];
    }
    else
    {
        _purchaseCallback([[AppleInAppPurchaseCallbackVO alloc] init]);
    }
}


#pragma mark - SKRequestDelegate
- (void)request:(SKRequest *)request didFailWithError:(NSError *)error
{
    [_activityIndicatorView stopAnimating];
    _purchaseCallback([[[AppleInAppPurchaseCallbackVO alloc] init:CodeStatusRequestProductFailed message:@""] autorelease]);
}

- (void)requestDidFinish:(SKRequest *)request NS_AVAILABLE_IOS(3_0)
{
    [_activityIndicatorView stopAnimating];
}


#pragma mark - SKPaymentTransactionObserver
- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions
{
    for (SKPaymentTransaction *transaction in transactions) {
        switch (transaction.transactionState) {
            case SKPaymentTransactionStatePurchased:
                [self completeTransaction:transaction];
                break;
            case SKPaymentTransactionStateFailed:
                [self failedTransaction:transaction];
                break;
            case SKPaymentTransactionStateRestored:
                [self restoreTransaction:transaction];
                break;
            case SKPaymentTransactionStatePurchasing:
                break;
            default:
                break;
        }
    }
}

#pragma mark --支付结果处理
- (void)postTransactionToServer:(SKPaymentTransaction *)transaction
{
    if (transaction == nil) {
        return;
    }

    NSString* receipt = nil;
    NSString* payload = @"";
    if (floor(NSFoundationVersionNumber) < NSFoundationVersionNumber_iOS_7_0) {
        receipt = [self encode:(uint8_t *)transaction.transactionReceipt.bytes length:transaction.transactionReceipt.length];
    } else {
        NSURL *receiptURL = [[NSBundle mainBundle] appStoreReceiptURL];
        NSData *recData = [[NSData dataWithContentsOfURL:receiptURL] base64EncodedDataWithOptions:0];
        receipt = [[[NSString alloc] initWithData:recData encoding:NSUTF8StringEncoding] autorelease];
        payload = transaction.payment.applicationUsername;
    }

    NSString* orderId = transaction.transactionIdentifier;
    NSString* productId = transaction.payment.productIdentifier;
    if (_purchaseCallback) {
        id ret = [[AppleInAppPurchaseCallbackVO alloc] init:CodeStatusPruchaseSuccess message:@""];
        [ret setOrderId:orderId];
        [ret setProductId:productId];
        [ret setPayload:payload];
        [ret setReceipt:receipt];
        _purchaseCallback(ret);
    }

}

- (void)completeTransaction:(SKPaymentTransaction *)transaction {
    [_transactions addObject:transaction];
    [self postTransactionToServer:transaction];
}

- (void)restoreTransaction:(SKPaymentTransaction *)transaction {
    [_transactions addObject:transaction.originalTransaction];
    [self postTransactionToServer:transaction.originalTransaction];
}

- (void)failedTransaction:(SKPaymentTransaction *)transaction {
    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
    _purchaseCallback([[AppleInAppPurchaseCallbackVO alloc] init:CodeStatusPurchaseFailed message:transaction.error.localizedDescription]);
}


- (NSString *)encode:(const uint8_t *)input length:(NSInteger)length {
    static char table[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=";

    NSMutableData *data = [NSMutableData dataWithLength:((length + 2) / 3) * 4];
    uint8_t *output = (uint8_t *)data.mutableBytes;

    for (NSInteger i = 0; i < length; i += 3) {
        NSInteger value = 0;
        for (NSInteger j = i; j < (i + 3); j++) {
            value <<= 8;

            if (j < length) {
                value |= (0xFF & input[j]);
            }
        }

        NSInteger index = (i / 3) * 4;
        output[index + 0] =                    table[(value >> 18) & 0x3F];
        output[index + 1] =                    table[(value >> 12) & 0x3F];
        output[index + 2] = (i + 1) < length ? table[(value >> 6)  & 0x3F] : '=';
        output[index + 3] = (i + 2) < length ? table[(value >> 0)  & 0x3F] : '=';
    }

    return [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding] ;
}


@end
