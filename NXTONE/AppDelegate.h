//
//  AppDelegate.h
//  NXTONE
//
//  Lego NXT Mindstormsに、Bluetooth経由でダイレクトコマンドを送る、シンプルなプログラムです。
//  Simple application for sending Direct Command to LEGO NXT Mindstorms over Bluetooth.
//
//  https://github.com/ll0s0ll/NXTONE
//
//  MIT License
//  Copyright (c) 2012 Shun ITO.
//

#import <Cocoa/Cocoa.h>
#import <IOBluetoothUI/IOBluetoothUI.h>
#import <IOBluetooth/objc/IOBluetoothSDPUUID.h>
#import <IOBluetooth/objc/IOBluetoothRFCOMMChannel.h>


@interface AppDelegate : NSObject <NSApplicationDelegate>
{
	IBOutlet NSTextField *input;
	IBOutlet NSTextField *returnPackage;
	IBOutlet NSTextField *statusField;
	IBOutlet NSButton *sendButton;
	IBOutlet NSButton *toggleConnectionButton;
	IBOutlet NSButton *setBeepCommandButton;
	
	IOBluetoothDevice *device;
	IOBluetoothRFCOMMChannel *rfcommChannel;
}

@property (assign) IBOutlet NSWindow *window;

- (IBAction)toggleConnection:(id)sender;
- (IBAction)WriteMessage:(id)sender;
- (IBAction)SetBeepCommand:(id)sender;

@end
