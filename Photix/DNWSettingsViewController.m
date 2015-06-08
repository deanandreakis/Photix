//
//  DNWSettingsViewController.m
//  Photix
//
//  Created by Dean Andreakis on 4/27/15.
//  Copyright (c) 2015 deanware. All rights reserved.
//

#import "DNWSettingsViewController.h"

@interface DNWSettingsViewController ()

@property (strong, nonatomic) IBOutlet UIButton* tip99Button;
@property (strong, nonatomic) IBOutlet UIButton* tip199Button;
@property (strong, nonatomic) IBOutlet UIButton* tip499Button;
@property (strong, nonatomic) IBOutlet UIButton* emailButton;

@end

@implementation DNWSettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
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

-(IBAction)tip99ButtonSelected:(id)sender {
    NSLog(@"99 cent tip");
}

-(IBAction)tip199ButtonSelected:(id)sender {
    NSLog(@"199 cent tip");
}

-(IBAction)tip499ButtonSelected:(id)sender {
    NSLog(@"499 cent tip");
}

-(IBAction)emailButtonSelected:(id)sender {
    MFMailComposeViewController *mailViewController = [[MFMailComposeViewController alloc] init];
    mailViewController.mailComposeDelegate = self;
    [mailViewController setSubject:@"OilPaintPlus Support"];
    [self presentViewController:mailViewController animated:YES completion:nil];
}

#pragma mark MFMailComposeViewControllerDelegate

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
