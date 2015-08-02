//
//  DNWSettingsViewController.m
//  Photix
//
//  Created by Dean Andreakis on 4/27/15.
//  Copyright (c) 2015 deanware. All rights reserved.
//

#import "DNWSettingsViewController.h"
#import "Constants.h"
#import "PhotixIAPHelper.h"
#import <StoreKit/StoreKit.h>

#define ALERTVIEW_99_BUY 0
#define ALERTVIEW_99_IAP_DISABLED 1
#define ALERTVIEW_99_IAP_PRODUCT_NOT_AVAILABLE 2

#define ALERTVIEW_199_BUY 3
#define ALERTVIEW_199_IAP_DISABLED 4
#define ALERTVIEW_199_IAP_PRODUCT_NOT_AVAILABLE 5

#define ALERTVIEW_499_BUY 6
#define ALERTVIEW_499_IAP_DISABLED 7
#define ALERTVIEW_499_IAP_PRODUCT_NOT_AVAILABLE 8

@interface DNWSettingsViewController (){
    NSArray *_products;
    NSNumberFormatter * _priceFormatter;
    SKProduct* _99Product;
    SKProduct* _199Product;
    SKProduct* _499Product;
}

@property (strong, nonatomic) UIActivityIndicatorView* activityIndicatorView;
@property (strong, nonatomic) UIAlertView* pleaseWaitAlertView;

@end

@implementation DNWSettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    self.pleaseWaitAlertView = [[UIAlertView alloc] initWithTitle:@"" message:@"Please Wait..." delegate:nil cancelButtonTitle:nil otherButtonTitles:nil];
    [self.view addSubview:self.pleaseWaitAlertView];
    [self.pleaseWaitAlertView addSubview:self.activityIndicatorView];
    self.activityIndicatorView.color = [UIColor blueColor];
    self.activityIndicatorView.center = CGPointMake(self.view.center.x, self.view.center.y + 35);
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    _priceFormatter = [[NSNumberFormatter alloc] init];
    [_priceFormatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
    [_priceFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
    
    [self getProducts];
}

- (void)viewWillAppear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(productPurchased:) name:IAPHelperProductPurchasedNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(transactionFailed:) name:IAPHelperTransactionFailedNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark IAP
//called when transaction is completed and successfully purchased or restored.
- (void)productPurchased:(NSNotification *)notification {
    [self.activityIndicatorView stopAnimating];
    [self.pleaseWaitAlertView dismissWithClickedButtonIndex:0 animated:YES];
    
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:USER_PURCHASED_TIP];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)transactionFailed:(NSNotification *)notification {
    
    [self.activityIndicatorView stopAnimating];
    [self.pleaseWaitAlertView dismissWithClickedButtonIndex:0 animated:YES];
}

- (void)getProducts {
    _products = nil;
    _99Product = nil;
    _199Product = nil;
    _499Product = nil;
    
    [[PhotixIAPHelper sharedInstance] requestProductsWithCompletionHandler:^(BOOL success, NSArray *products) {
        if (success) {
            _products = products;
            for (SKProduct* product in _products) {
                if([product.productIdentifier isEqualToString:STOREKIT_PRODUCT_ID_GENEROUS_99]) {
                    _99Product = product;
                }
                else if([product.productIdentifier isEqualToString:STOREKIT_PRODUCT_ID_MASSIVE_199]) {
                    _199Product = product;
                }
                else if([product.productIdentifier isEqualToString:STOREKIT_PRODUCT_ID_AMAZING_499]) {
                    _499Product = product;
                }
            }
            //NSLog(@"IAP Response: %@", _products);
        } else {
            //leave the _bgProduct and _soundProduct nil
        }
    }];
}

#pragma mark Button Handlers

-(IBAction)tip99ButtonSelected:(id)sender {
    NSLog(@"99 cent tip");
    
        if(_99Product != nil) {
            if (![[PhotixIAPHelper sharedInstance] productPurchased:_99Product.productIdentifier]) { //have not purchased product
                if ([SKPaymentQueue canMakePayments]) { //make sure they are allowed to perform IAP per parental controls settings
                    
                    [_priceFormatter setLocale:_99Product.priceLocale];
                    
                    NSMutableString* myString = [[NSMutableString alloc] initWithCapacity:25];
                    [myString appendString:_99Product.localizedTitle];
                    [myString appendString:@": "];
                    [myString appendString:_99Product.localizedDescription];
                    [myString appendString:@"\n"];
                    [myString appendString:NSLocalizedString(@"Price: ",nil)];
                    [myString appendString:[_priceFormatter stringFromNumber:_99Product.price]];
                    
                    UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Confirm Purchase of the Generous Tip",nil)
                                                                        message:myString
                                                                       delegate:self
                                                              cancelButtonTitle:NSLocalizedString(@"Cancel",nil)
                                                              otherButtonTitles:NSLocalizedString(@"Buy",nil), nil];
                    alertView.tag = ALERTVIEW_99_BUY;
                    [alertView show];
                    
                } else {
                    
                    UIAlertView *tmp = [[UIAlertView alloc]
                                        
                                        initWithTitle:NSLocalizedString(@"Prohibited",nil)
                                        
                                        message:NSLocalizedString(@"This feature is available via In-App Purchase. Parental Control is enabled, cannot make a purchase!",nil)
                                        
                                        delegate:self
                                        
                                        cancelButtonTitle:nil
                                        
                                        otherButtonTitles:NSLocalizedString(@"Ok",nil), nil];
                    
                    tmp.tag = ALERTVIEW_99_IAP_DISABLED;
                    
                    [tmp show];
                }
            }
        } else {
            //the products are nil so the original product fetch in getProducts() failed
            UIAlertView *tmp = [[UIAlertView alloc]
                                
                                initWithTitle:NSLocalizedString(@"Product Not Available",nil)
                                
                                message:NSLocalizedString(@"This product is not currently available. Please try again later.",nil)
                                
                                delegate:self
                                
                                cancelButtonTitle:nil
                                
                                otherButtonTitles:NSLocalizedString(@"Ok",nil), nil];
            
            tmp.tag = ALERTVIEW_99_IAP_PRODUCT_NOT_AVAILABLE;
            
            [tmp show];
        }
}

-(IBAction)tip199ButtonSelected:(id)sender {
    NSLog(@"199 cent tip");
    
    if(_199Product != nil) {
        if (![[PhotixIAPHelper sharedInstance] productPurchased:_199Product.productIdentifier]) { //have not purchased product
            if ([SKPaymentQueue canMakePayments]) { //make sure they are allowed to perform IAP per parental controls settings
                
                [_priceFormatter setLocale:_199Product.priceLocale];
                
                NSMutableString* myString = [[NSMutableString alloc] initWithCapacity:25];
                [myString appendString:_199Product.localizedTitle];
                [myString appendString:@": "];
                [myString appendString:_199Product.localizedDescription];
                [myString appendString:@"\n"];
                [myString appendString:NSLocalizedString(@"Price: ",nil)];
                [myString appendString:[_priceFormatter stringFromNumber:_199Product.price]];
                
                UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Confirm Purchase of the Massive Tip",nil)
                                                                    message:myString
                                                                   delegate:self
                                                          cancelButtonTitle:NSLocalizedString(@"Cancel",nil)
                                                          otherButtonTitles:NSLocalizedString(@"Buy",nil), nil];
                alertView.tag = ALERTVIEW_199_BUY;
                [alertView show];
                
            } else {
                
                UIAlertView *tmp = [[UIAlertView alloc]
                                    
                                    initWithTitle:NSLocalizedString(@"Prohibited",nil)
                                    
                                    message:NSLocalizedString(@"This feature is available via In-App Purchase. Parental Control is enabled, cannot make a purchase!",nil)
                                    
                                    delegate:self
                                    
                                    cancelButtonTitle:nil
                                    
                                    otherButtonTitles:NSLocalizedString(@"Ok",nil), nil];
                
                tmp.tag = ALERTVIEW_199_IAP_DISABLED;
                
                [tmp show];
            }
        }
    } else {
        //the products are nil so the original product fetch in getProducts() failed
        UIAlertView *tmp = [[UIAlertView alloc]
                            
                            initWithTitle:NSLocalizedString(@"Product Not Available",nil)
                            
                            message:NSLocalizedString(@"This product is not currently available. Please try again later.",nil)
                            
                            delegate:self
                            
                            cancelButtonTitle:nil
                            
                            otherButtonTitles:NSLocalizedString(@"Ok",nil), nil];
        
        tmp.tag = ALERTVIEW_199_IAP_PRODUCT_NOT_AVAILABLE;
        
        [tmp show];
    }
}

-(IBAction)tip499ButtonSelected:(id)sender {
    NSLog(@"499 cent tip");
    
    if(_499Product != nil) {
        if (![[PhotixIAPHelper sharedInstance] productPurchased:_499Product.productIdentifier]) { //have not purchased product
            if ([SKPaymentQueue canMakePayments]) { //make sure they are allowed to perform IAP per parental controls settings
                
                [_priceFormatter setLocale:_499Product.priceLocale];
                
                NSMutableString* myString = [[NSMutableString alloc] initWithCapacity:25];
                [myString appendString:_499Product.localizedTitle];
                [myString appendString:@": "];
                [myString appendString:_499Product.localizedDescription];
                [myString appendString:@"\n"];
                [myString appendString:NSLocalizedString(@"Price: ",nil)];
                [myString appendString:[_priceFormatter stringFromNumber:_499Product.price]];
                
                UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Confirm Purchase of the Amazing Tip",nil)
                                                                    message:myString
                                                                   delegate:self
                                                          cancelButtonTitle:NSLocalizedString(@"Cancel",nil)
                                                          otherButtonTitles:NSLocalizedString(@"Buy",nil), nil];
                alertView.tag = ALERTVIEW_499_BUY;
                [alertView show];
                
            } else {
                
                UIAlertView *tmp = [[UIAlertView alloc]
                                    
                                    initWithTitle:NSLocalizedString(@"Prohibited",nil)
                                    
                                    message:NSLocalizedString(@"This feature is available via In-App Purchase. Parental Control is enabled, cannot make a purchase!",nil)
                                    
                                    delegate:self
                                    
                                    cancelButtonTitle:nil
                                    
                                    otherButtonTitles:NSLocalizedString(@"Ok",nil), nil];
                
                tmp.tag = ALERTVIEW_499_IAP_DISABLED;
                
                [tmp show];
            }
        }
    } else {
        //the products are nil so the original product fetch in getProducts() failed
        UIAlertView *tmp = [[UIAlertView alloc]
                            
                            initWithTitle:NSLocalizedString(@"Product Not Available",nil)
                            
                            message:NSLocalizedString(@"This product is not currently available. Please try again later.",nil)
                            
                            delegate:self
                            
                            cancelButtonTitle:nil
                            
                            otherButtonTitles:NSLocalizedString(@"Ok",nil), nil];
        
        tmp.tag = ALERTVIEW_499_IAP_PRODUCT_NOT_AVAILABLE;
        
        [tmp show];
    }
}

-(IBAction)emailButtonSelected:(id)sender {
    MFMailComposeViewController *mailViewController = [[MFMailComposeViewController alloc] init];
    mailViewController.mailComposeDelegate = self;
    [mailViewController setSubject:@"OilPaintPlus Support"];
    [mailViewController setToRecipients:[NSArray arrayWithObjects:@"dean@deanware.co",nil]];
    [self presentViewController:mailViewController animated:YES completion:nil];
}

#pragma mark MFMailComposeViewControllerDelegate

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    switch (alertView.tag) {
        case ALERTVIEW_99_BUY:
            if(buttonIndex == 0) {//CANCEL
            } else if(buttonIndex == 1) { //BUY
                [[PhotixIAPHelper sharedInstance] buyProduct:_99Product];
                [self.pleaseWaitAlertView show];
                [self.activityIndicatorView startAnimating];
            }
            break;
        case ALERTVIEW_99_IAP_DISABLED:
            break;
        case ALERTVIEW_99_IAP_PRODUCT_NOT_AVAILABLE:
            break;
        case ALERTVIEW_199_BUY:
            if(buttonIndex == 0) {//CANCEL
            } else if(buttonIndex == 1) { //BUY
                [[PhotixIAPHelper sharedInstance] buyProduct:_199Product];
                [self.pleaseWaitAlertView show];
                [self.activityIndicatorView startAnimating];
            }
            break;
        case ALERTVIEW_199_IAP_DISABLED:
            break;
        case ALERTVIEW_199_IAP_PRODUCT_NOT_AVAILABLE:
            break;
        case ALERTVIEW_499_BUY:
            if(buttonIndex == 0) {//CANCEL
            } else if(buttonIndex == 1) { //BUY
                [[PhotixIAPHelper sharedInstance] buyProduct:_499Product];
                [self.pleaseWaitAlertView show];
                [self.activityIndicatorView startAnimating];
            }
            break;
        case ALERTVIEW_499_IAP_DISABLED:
            break;
        case ALERTVIEW_499_IAP_PRODUCT_NOT_AVAILABLE:
            break;
        default:
            break;
    }
    
}

@end
