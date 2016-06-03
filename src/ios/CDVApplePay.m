#import "CDVApplePay.h"
#import "Stripe.h"
#import <PassKit/PassKit.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>

@implementation CDVApplePay

- (CDVPlugin*)initWithWebView:(UIWebView*)theWebView
{
    NSString*  StripePublishableKey = [self getStipePublicKey];
    [Stripe setDefaultPublishableKey:StripePublishableKey];
    self = (CDVApplePay*)[super initWithWebView:(UIWebView*)theWebView];

    return self;
}

- (NSString*) getStipePublicKey {
    NSDictionary *dict = [[NSBundle mainBundle] infoDictionary] ;
    if ([dict objectForKey:@"StripePublicKey"]) {
        return [dict objectForKey:@"StripePublicKey"];
    }
    return nil;
}


- (void)dealloc
{

}

- (void)onReset
{

}

- (void)setMerchantId:(CDVInvokedUrlCommand*)command
{
    merchantId = [command.arguments objectAtIndex:0];
    NSLog(@"ApplePay set merchant id to %@", merchantId);
}

- (void)getAllowsApplePay:(CDVInvokedUrlCommand*)command
{
    if (merchantId == nil) {
        CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString: @"Please call setMerchantId() with your Apple-given merchant ID."];
        [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
        return;
    }

    PKPaymentRequest *request = [Stripe
                                 paymentRequestWithMerchantIdentifier:merchantId];

    // Configure a dummy request
    NSString *label = @"Premium Llama Food";
    NSDecimalNumber *amount = [NSDecimalNumber decimalNumberWithString:@"10.00"];
    request.paymentSummaryItems = @[
                                    [PKPaymentSummaryItem summaryItemWithLabel:label
                                                                        amount:amount]
                                    ];

    if ([Stripe canSubmitPaymentRequest:request]) {
        CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString: @"user has apple pay"];
        [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
    } else {
        // Debug mode
        CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString: @"in debug mode, simulating apple pay"];
        [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];

        // // Live mode
        // CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString: @"user does not have apple pay"];
        // [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];

    }
}

- (void)getStripeToken:(CDVInvokedUrlCommand*)command
{

    if (merchantId == nil) {
        CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString: @"Please call setMerchantId() with your Apple-given merchant ID."];
        [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
        return;
    }

    PKPaymentRequest *request = [Stripe
                             paymentRequestWithMerchantIdentifier:merchantId];

    // Configure your request here.
    NSString *label = [command.arguments objectAtIndex:1];
    NSDecimalNumber *amount = [NSDecimalNumber decimalNumberWithString:[command.arguments objectAtIndex:0]];
    request.paymentSummaryItems = @[
        [PKPaymentSummaryItem summaryItemWithLabel:label
                                          amount:amount]
    ];

    NSString *cur = [command.arguments objectAtIndex:2];
    request.currencyCode = cur;

    callbackId = command.callbackId;


    // Debug mode
    STPTestPaymentAuthorizationViewController *paymentController;
    paymentController = [[STPTestPaymentAuthorizationViewController alloc]
                             initWithPaymentRequest:request];
    paymentController.delegate = self;
    [self.viewController presentViewController:paymentController animated:YES completion:nil];

    // // Live mode
    // if ([Stripe canSubmitPaymentRequest:request]) {
    //     PKPaymentAuthorizationViewController *paymentController;
    //     paymentController = [[PKPaymentAuthorizationViewController alloc]
    //                          initWithPaymentRequest:request];
    //     paymentController.delegate = self;
    //     [self.viewController presentViewController:paymentController animated:YES completion:nil];
    // } else {
    //     CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString: @"You dont have access to ApplePay"];
    //     [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
    //     return;
    // }
}

- (void)paymentAuthorizationViewController:(PKPaymentAuthorizationViewController *)controller
                       didAuthorizePayment:(PKPayment *)payment
                                completion:(void (^)(PKPaymentAuthorizationStatus))completion {

    void(^tokenBlock)(STPToken *token, NSError *error) = ^void(STPToken *token, NSError *error) {
        if (error) {
            CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString: @"couldn't get a stripe token from STPAPIClient"];
            [self.commandDelegate sendPluginResult:result callbackId:callbackId];
            return;
        }
        else {
            CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString: token.tokenId];
            [self.commandDelegate sendPluginResult:result callbackId:callbackId];
        }
        [self.viewController dismissViewControllerAnimated:YES completion:nil];
    };

    // Debug mode
    STPCard *card = [STPCard new];
    card.number = @"4242424242424242";
    card.expMonth = 12;
    card.expYear = 2020;
    card.cvc = @"123";
    [[STPAPIClient sharedClient] createTokenWithCard:card completion:tokenBlock];

    // // Live mode
    // [[STPAPIClient sharedClient] createTokenWithPayment:payment
    //                 operationQueue:[NSOperationQueue mainQueue]
    //                     completion:tokenBlock];
}

- (void)paymentAuthorizationViewControllerDidFinish:(PKPaymentAuthorizationViewController *)controller {
    CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString: @"user cancelled apple pay"];
    [self.commandDelegate sendPluginResult:result callbackId:callbackId];
    [self.viewController dismissViewControllerAnimated:YES completion:nil];
}

@end