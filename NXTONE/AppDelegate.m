//
//  AppDelegate.m
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

#import "AppDelegate.h"

@implementation AppDelegate

//--------------------------------------------------------
// アプリが起動したら呼ばれる。
//--------------------------------------------------------
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	[statusField setStringValue:(@"Status: Disconnected")];
	[sendButton setEnabled: NO];
	[setBeepCommandButton setEnabled: NO];
	[self openBTDeviceConnection];
}


//--------------------------------------------------------
// デバイスへの接続or切断を切り替える
//--------------------------------------------------------
-(void)toggleConnection:(id)sender
{
	//RFCOMMChannelが開いていれば閉じる
	if ([rfcommChannel isOpen] == TRUE){
		[self closeRFCOMMChannel];
		return;
	}
	
	//deviceに接続されていれば切断、切断されていれば接続する
	if ([device isConnected] == TRUE){
		[self closeBTDeviceConnection];
		return;
	}
	else
	{
		[self openBTDeviceConnection];
		return;
	}
}


//--------------------------------------------------------
// Bluetoothデバイス選択画面を表示させる
//--------------------------------------------------------
- (void)openBTDeviceConnection
{
	IOBluetoothDeviceSelectorController *ctrl = [IOBluetoothDeviceSelectorController deviceSelector];
	if ( ctrl == nil ){
		NSLog(@"ERROR - IOBluetoothDeviceSelectorController object");
		return;
	}
	
	//uuidを割り振り
	IOBluetoothSDPUUID *uuid = [IOBluetoothSDPUUID uuid16:kBluetoothSDPUUID16ServiceClassSerialPort];
	[ctrl addAllowedUUID:uuid];
	
	//デバイスが選択されたら"sheetDidEnd:"が呼ばれる
	[ctrl beginSheetModalForWindow:self.window
						  modalDelegate:self
						 didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:)
							 contextInfo:uuid];
}


//--------------------------------------------------------
// RFCOMM Channelを開く（SheetModalから呼ばれる）
//--------------------------------------------------------
- (void)sheetDidEnd:(IOBluetoothDeviceSelectorController *)ctrl
			returnCode:(int)returnCode
		  contextInfo:(IOBluetoothSDPUUID *)uuid
{
	//エラーチェック
	if (returnCode == kIOBluetoothUIUserCanceledErr){
		NSLog(@"ERROR - kIOBluetoothUIUserCanceledErr");
		return;
	}
	
	if (returnCode != kIOBluetoothUISuccess){
		NSLog(@"ERROR - !kIOBluetoothUISuccess");
		return;
	}
	
	if (([ctrl getResults] == nil) || [[ctrl getResults] count] == 0){
		NSLog(@"ERROR - no results found");
		return;
	}
	
	//----------------------------------------------------------------------------
	
	//選択されたデバイスの情報を取得
	device = [[ctrl getResults] objectAtIndex:0];
		
	//deviceのServiceRecordを取得
	IOBluetoothSDPServiceRecord *sdpServiceRecord = [device getServiceRecordForUUID:uuid];
	
	//deviceがRFCOMM Channelをサポートしているか確認
	BluetoothRFCOMMChannelID rfcommChannelId = 0;
	if ([sdpServiceRecord getRFCOMMChannelID:&rfcommChannelId] != kIOReturnSuccess)
	{
		NSLog(@"ERROR - no service in selected device.");
		return;
	}
	
	//RFCOMM Channelを開く。シーケンスが完了すると"rfcommChannelOpenComplete:"が呼ばれる
	if (([device openRFCOMMChannelAsync:&rfcommChannel
								 withChannelID:rfcommChannelId delegate:self] != kIOReturnSuccess))
	{
		NSLog(@"ERROR - open RFCOMM channel failed.");
		return;
	}
	
	//statusFieldの変更
	[statusField setStringValue:(@"Status: Connecting...")];
	
}


//--------------------------------------------------------
// 正常にRFCOMMChannelが開いた確認
// RFCOMMChannelを開くシーケンスが終わると（RFCOMM channelより呼ばれる）
//--------------------------------------------------------
- (void)rfcommChannelOpenComplete:(IOBluetoothRFCOMMChannel*)rfcommChannel
									status:(IOReturn)status
{
	if (status == kIOReturnSuccess)
	{
		NSLog(@"Hellow World");
		//開いた合図にビープを再生
		[self playBeep];
		
		//ボタン、フィールド類を設定
		[statusField setStringValue:(@"Status: Connected")];
		[toggleConnectionButton setTitle:@"Disconnect"];
		[sendButton setEnabled: YES];
		[setBeepCommandButton setEnabled: YES];
		
		return;
	}
	NSLog(@"Googbye World");
	//失敗した場合はデバイスの接続を閉じる
	[self	closeBTDeviceConnection];
}


//--------------------------------------------------------
// BTデバイスよりデータを受信した際にRFCOMM channelより呼ばれる
//--------------------------------------------------------
- (void)rfcommChannelData:(IOBluetoothRFCOMMChannel *)rfcommChannel
							data:(void *)dataPointer
						 length:(size_t)dataLength
{
	NSLog(@"Received new data");
	
	//16進数に変換
	NSString *tmp_str;
	NSString *hexMessage = [NSString string];
	for (int i = 0; i < dataLength; i++)
	{
		tmp_str = [NSString stringWithFormat:@"0x%02X ", *((unsigned char *)dataPointer+i)];
		hexMessage = [hexMessage stringByAppendingString:tmp_str];
	}
	
	//フィールドに結果を設定
	[returnPackage setStringValue:hexMessage];
}


//--------------------------------------------------------
// BTデバイスとのRFCOMM channelが閉じた際にRFCOMM channelより呼ばれる
//--------------------------------------------------------
- (void)rfcommChannelClosed:(IOBluetoothRFCOMMChannel *)rfcommChannel
{
	NSLog(@"RFCOMM Channel channel closed");
	
	//少し時間を置き、デバイスとの接続を切断
	[self performSelector:@selector(closeBTDeviceConnection)
				  withObject:nil afterDelay:1.0];
	
	//フィールドを設定
	[statusField setStringValue:(@"Status: Disconnecting...")];
}


//--------------------------------------------------------
// BTデバイスとのRFCOMM connectionを閉じる
//--------------------------------------------------------
- (void)closeRFCOMMChannel
{
	NSLog(@"closeRFCOMMChannel");
	[rfcommChannel closeChannel];
}


//--------------------------------------------------------
// BTデバイスとの接続を切断
//--------------------------------------------------------
- (void)closeBTDeviceConnection
{
	NSLog(@"closeBTDeviceConnection");
	//切断
	if ([device closeConnection] != kIOReturnSuccess)
	{
		NSLog(@"Error - failed to close the device connection with error");
	}
	
	//ボタン、フィールド類を設定
	[statusField setStringValue:(@"Status: Disconnected")];
	[toggleConnectionButton setTitle:@"Connect"];
	[sendButton setEnabled: NO];
	[setBeepCommandButton setEnabled: NO];
	
	[device release];
	device = nil;
}


//--------------------------------------------------------
// ビープを再生する
//--------------------------------------------------------
- (void)playBeep
{
	//ビープを再生する命令を作成
	char message[] = {
		0x06,
		0x00,
		0x80,
		0x03,
		0x0B,
		0x02,
		0xF4,
		0x01
	};
	
	//messageを送信
	[rfcommChannel writeAsync:message length:8 refcon:self];
}


//--------------------------------------------------------
// メッセージを送信する
//--------------------------------------------------------
- (void)WriteMessage:(id)sender
{
//	NSLog(@"WriteMessage");
	
	//入力された内容を' 'で分割する
	NSArray *separatedStringArray = [[input stringValue] componentsSeparatedByString:@" "];
	
	//入力された書式を確認
	for (NSString *tmp_s in separatedStringArray)
	{		//NSLog(@"%@", [tmp_s description]);
		
		//'0x'から始まっているか
		if (![tmp_s hasPrefix:@"0x"])
		{
			NSLog(@"ERROR - Not start'0x'");
			return;
		}
		
		//3文字以上4文字以内か
		if ([tmp_s length] > 4 || [tmp_s length] < 3)
		{
			NSLog(@"ERROR - length over 4chars or less 3chars");
			return;
		}
	}

	//16進数表記の文字列を整数に変換
	unsigned long count = separatedStringArray.count; //NSLog(@"%lu", count);
	char convertedMessages[count];
	for (int i=0; i < count; i++)
	{
		NSScanner *scanner = [NSScanner scannerWithString:[separatedStringArray objectAtIndex:i]];
		
		unsigned int tmp_i;
		[scanner scanHexInt:&tmp_i];//NSLog(@"Hex->int %u", tmp_i);	//NSLog(@"Hex->int 0x%02X", tmp_i);

		convertedMessages[i] = tmp_i;
	}
	
	//convertedMessagesを送信
	[rfcommChannel writeAsync:convertedMessages length:count refcon:self];
	NSLog(@"send the message");
	
	//フィールドの設定
	[returnPackage setStringValue:@"None"];
}


//--------------------------------------------------------
// ビープを0.5秒間鳴らすコマンドをセットする
//--------------------------------------------------------
- (void)SetBeepCommand:(id)sender
{
	[input setStringValue:@"0x06 0x00 0x00 0x03 0x0B 0x02 0xF4 0x01"];
}

@end
