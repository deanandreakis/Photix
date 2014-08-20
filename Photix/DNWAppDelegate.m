//
//  DNWAppDelegate.m
//  Photix
//
//  Created by Dean Andreakis on 2/8/14.
//  Copyright (c) 2014 deanware. All rights reserved.
//

#import "DNWAppDelegate.h"
#import "DatabaseManager.h"
#import "Constants.h"
#import "Flurry.h"
#import <Crashlytics/Crashlytics.h>
#import "Appirater.h"

@implementation DNWAppDelegate

@synthesize imageToSet, storyboardName;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    //[Appirater setAppId:@"827491007"];
    //[Appirater setDaysUntilPrompt:1];
    //[Appirater setUsesUntilPrompt:5];
    //[Appirater setSignificantEventsUntilPrompt:-1];
    //[Appirater setTimeBeforeReminding:3];
    //[Appirater setDebug:YES];
    
    [Flurry startSession:FLURRY_KEY];
    
    [Crashlytics startWithAPIKey:@"2eaad7ad1fecfce6c414905676a8175bb2a1c253"];
    
    //initialize CoreData
    //[[DatabaseManager sharedDatabaseManager] managedObjectContext];
    
    //if([[DatabaseManager sharedDatabaseManager] isDBNotExist])
    //{
      //  [[DatabaseManager sharedDatabaseManager] prePopulate];
    //}
    
    CGSize result = [[UIScreen mainScreen] bounds].size;
    if(result.height == 568)
    {
        storyboardName = @"MainStoryboardiPhone5";
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:storyboardName bundle:[NSBundle mainBundle]];
        UIViewController *launchViewController = [storyboard instantiateInitialViewController];
        [self.window.rootViewController.view removeFromSuperview];
        self.window.rootViewController = launchViewController;
    }
    else
    {
        storyboardName = @"MainStoryboard";
    }
    
    //[Appirater appLaunched:YES];
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    //[Appirater appEnteredForeground:YES];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Saves changes in the application's managed object context before the application terminates.
    [[DatabaseManager sharedDatabaseManager] saveContext];
}

-(void)executeBlock:(void (^)(void))block
{
    [self performSelectorInBackground:@selector(executeBlockInBG:) withObject:block];
}

-(void)executeBlockInBG:(void (^)(void))block
{
    block();
}

+ (DNWAppDelegate *)appDelegate
{
    return (DNWAppDelegate *)[[UIApplication sharedApplication] delegate];
}

@end
