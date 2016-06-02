# phund.applepay.stripe

This plugin is a basic implementation of Stripe and Apple Pay.
Use https://github.com/stripe/stripe-ios (v7.0.2)


## Installation

    cordova plugin add https://github.com/phund/cordova-plugin-applepay-strip.git

## Supported Platforms

- iOS

## Methods

- ApplePay.getAllowsApplePay
- ApplePay.setMerchantId
- ApplePay.getStripeToken

## ApplePay.getAllowsApplePay

Returns successfully if the device is setup for Apple Pay (correct software version, correct hardware & has card added).

    ApplePay.getAllowsApplePay(successCallback, errorCallback);

## ApplePay.setMerchantId

Set your Apple-given merchant ID.

    ApplePay.setMerchantId(successCallback, errorCallback, "merchant.my.id");

## ApplePay.getStripeToken

Request a stripe token for an Apple Pay card.

    ApplePay.getStripeToken(successCallback, errorCallback, amount, description, currency);

### Example

    ApplePay.setMerchantId("merchant.apple.test");

    function onError(err) {
        alert(JSON.stringify(err));
    }
    function onSuccess(response) {
        alert(response);
    }

    ApplePay.getStripeToken(onSuccess, onError, 10.00, "Delicious Cake", "USD");

