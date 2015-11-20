#import "HockeyApp.h"
#import <HockeySDK/HockeySDK.h>
#import <Cordova/CDVViewController.h>

@implementation HockeyApp

- (id)init
{
    self = [super init];
    initialized = NO;
    crashMetaData = [NSMutableDictionary new];
    return self;
}

- (void) start:(CDVInvokedUrlCommand*)command
{
    NSArray* arguments = command.arguments;
    CDVPluginResult* pluginResult = nil;

    if (initialized == YES) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"hockeyapp cordova plugin: plugin is already started!"];
    } else if ([arguments count] > 1) {
        NSString* token = [arguments objectAtIndex:0];
        NSString* autoSend = [arguments objectAtIndex:1];
        
        // no-op this for now. Appears to do nothing on ios side?
        // NSString* ignoreDefaultHandler = [arguments objectAtIndex:2];

        if ([autoSend isEqual:@"true"]) {
            [[BITHockeyManager sharedHockeyManager].crashManager setCrashManagerStatus:BITCrashManagerStatusAutoSend];
        }
        
        [[BITHockeyManager sharedHockeyManager] configureWithIdentifier:token
                                                               delegate:self];
        [[BITHockeyManager sharedHockeyManager] startManager];
        [[BITHockeyManager sharedHockeyManager].authenticator authenticateInstallation];
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
        initialized = YES;

    } else {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"hockeyapp cordova plugin: missing arguments!"];
    }

    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void) feedback:(CDVInvokedUrlCommand*)command
{
    CDVPluginResult* pluginResult = nil;
    if(initialized == YES) {
        [[BITHockeyManager sharedHockeyManager].feedbackManager showFeedbackListView];
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    }
    else {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"hockeyapp cordova plugin is not started, call hockeyapp.start(successcb, errorcb, appid) first!"];
    }
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void) checkForUpdate:(CDVInvokedUrlCommand*)command
{
    CDVPluginResult* pluginResult = nil;
    if(initialized == YES) {
        [[BITHockeyManager sharedHockeyManager].updateManager checkForUpdate];
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    }
    else {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"hockeyapp cordova plugin is not started, call hockeyapp.start(successcb, errorcb, hockeyapp_id) first!"];
    }
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void) forceCrash:(CDVInvokedUrlCommand *)command {
    [[BITHockeyManager sharedHockeyManager].crashManager generateTestCrash];
}

- (void) addMetaData:(CDVInvokedUrlCommand *)command {
    NSData* arguments = [[command.arguments objectAtIndex:0] dataUsingEncoding:NSUTF8StringEncoding];
    CDVPluginResult* pluginResult = nil;
    
    if(initialized == YES) {
        NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains (NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        NSString *fileName = [documentsDirectory stringByAppendingPathComponent:@"crashMetaData.txt"];
        if([[NSFileManager defaultManager] fileExistsAtPath:fileName]) {
            [[NSFileManager defaultManager] removeItemAtPath:fileName error:nil];
        }

        [[NSFileManager defaultManager] createFileAtPath:fileName contents:nil attributes:nil];

        if (crashMetaData == nil) {
            crashMetaData = [NSMutableDictionary new];
        }

        NSError *error;
        NSDictionary* newMetaData = [NSJSONSerialization JSONObjectWithData:arguments options:0 error:&error];
        [crashMetaData addEntriesFromDictionary:newMetaData];

        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:crashMetaData options:0 error:&error];
        if (jsonData) {
            NSString *crashLogString = [[NSString alloc] initWithBytes:[jsonData bytes] length:[jsonData length] encoding:NSUTF8StringEncoding];
            NSFileHandle *file = [NSFileHandle fileHandleForUpdatingAtPath:fileName];
            [file seekToEndOfFile];
            [file writeData:[crashLogString dataUsingEncoding:NSUTF8StringEncoding]];
            [file closeFile];
        }
        
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    }
    else {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"hockeyapp cordova plugin is not started, call hockeyapp.start(successcb, errorcb, hockeyapp_id) first!"];
    }
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

#pragma mark - BITCrashManagerDelegate

- (NSString *)applicationLogForCrashManager:(BITCrashManager *)crashManager {
    NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains (NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *fileName = [documentsDirectory stringByAppendingPathComponent:@"crashMetaData.txt"];

    NSString *logData = [NSString stringWithContentsOfFile:fileName encoding:NSUTF8StringEncoding error:nil];
    
    return logData;
}

@end
