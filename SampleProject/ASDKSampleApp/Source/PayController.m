//
//  PayController.m
//  ASDKSampleApp
//
//  Created by Max Zhdanov on 12.02.16.
//  Copyright © 2016 TCS Bank. All rights reserved.
//

#import "PayController.h"

#import "ASDKTestSettings.h"
#import <ASDKUI/ASDKUI.h>

#import "ASDKCardIOScanner.h"

#import "PaymentSuccessViewController.h"
#import "TransactionHistoryModelController.h"
#import "ASDKCardsListDataController.h"

@implementation PayController

+ (ASDKPaymentFormStarter *)paymentFormStarter
{
	ASDKStringKeyCreator *stringKeyCreator = [[ASDKStringKeyCreator alloc] initWithPublicKeyString:[ASDKTestSettings testPublicKey]];
	ASDKAcquiringSdk *acquiringSdk = [ASDKAcquiringSdk acquiringSdkWithTerminalKey:[ASDKTestSettings testActiveTerminal]
																		   payType:nil//@"O"//@"T"
																		  password:[ASDKTestSettings testTerminalPassword]
															   publicKeyDataSource:stringKeyCreator];
	
	[acquiringSdk setDebug:YES];
	[acquiringSdk setTestDomain:YES];
	[acquiringSdk setLogger:nil];
	
	return [ASDKPaymentFormStarter paymentFormStarterWithAcquiringSdk:acquiringSdk];
}

+ (NSString *)customerKey
{
	return @"user-key";
//	return @"testMerchantApplePay";
//	return @"testCustomerKey1@gmail.com";
}

+ (UIAlertController *)alertWithError:(ASDKAcquringSdkError *)error
{
	NSString *alertTitle = error.errorMessage ? error.errorMessage : @"Ошибка";
	NSString *alertDetails = error.errorDetails ? error.errorDetails : error.userInfo[kASDKStatus];
	
	UIAlertController *alertController = [UIAlertController alertControllerWithTitle:alertTitle message:alertDetails preferredStyle:UIAlertControllerStyleAlert];
	
	[alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Close", @"Закрыть") style:UIAlertActionStyleCancel
													  handler:^(UIAlertAction *action) {
														  [alertController dismissViewControllerAnimated:YES completion:nil];
													  }]];
	return alertController;
}

+ (UIAlertController *)alertForCancel
{
	UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"CanceledPayment", @"Оплата отменена") message:nil preferredStyle:UIAlertControllerStyleAlert];
	
	UIAlertAction *cancelAction = [UIAlertAction
								   actionWithTitle:NSLocalizedString(@"Close", @"Закрыть")
								   style:UIAlertActionStyleCancel
								   handler:^(UIAlertAction *action)
								   {
									   [alertController dismissViewControllerAnimated:YES completion:nil];
								   }];
	
	[alertController addAction:cancelAction];
	
	return alertController;
}

+ (void)buyItemWithName:(NSString *)name
            description:(NSString *)description
                 amount:(NSNumber *)amount
			  recurrent:(BOOL)recurrent
			 makeCharge:(BOOL)makeCharge
  additionalPaymentData:(NSDictionary *)data
			receiptData:(NSDictionary *)receiptData
     fromViewController:(UIViewController *)viewController
                success:(void (^)(ASDKPaymentInfo *paymentInfo))onSuccess
              cancelled:(void (^)())onCancelled
                  error:(void(^)(ASDKAcquringSdkError *error))onError
{
	ASDKPaymentFormStarter *paymentFormStarter = [PayController paymentFormStarter];

    double randomOrderId = arc4random()%10000000;
	
	//Настройка дизайна
	ASDKDesignConfiguration *designConfiguration = [[ASDKDesignConfiguration alloc] init];
	// используем ASDKTestSettings для переключения настроект во время работы приложения, для быстрой демонстрации
	if ([ASDKTestSettings customNavBarColor])
	{
		[designConfiguration setNavigationBarColor:[UIColor orangeColor] navigationBarItemsTextColor:[UIColor darkGrayColor] navigationBarStyle:UIBarStyleDefault];
	}
	
	if ([ASDKTestSettings customButtonPay])
	{
		[designConfiguration setPayButtonColor:[UIColor greenColor] payButtonPressedColor:[UIColor blueColor] payButtonTextColor:[UIColor whiteColor]];
	}

	if ([ASDKTestSettings customButtonCancel])
	{
		UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithTitle:@"Отказаться" style:UIBarButtonItemStylePlain target:nil action:nil];
		[cancelButton setTintColor:[UIColor redColor]];
		[designConfiguration setCustomBackButton:cancelButton];
	}
	//
	[designConfiguration setPayFormItems:@[//@(PayFormItems_ProductTitle),
										   //@(PayFormItems_ProductDescription),
										   @(PayFormItems_Amount),
										   @(PayFormItems_PyamentCardRequisites),
										   //@(PayFormItems_Email),
										   @(PayFormItems_Empty20px),
										   @(PayFormItems_PayButton),
										   //@(PayFormItems_SecureLogos)
										   ]];

	//[designConfiguration setPayButtonTitle:[NSString stringWithFormat:@"Оплатить %.2f руб", [amount doubleValue]]];
	paymentFormStarter.designConfiguration = designConfiguration;

//Настройка сканнера карт
    paymentFormStarter.cardScanner = [ASDKCardIOScanner scanner];

	[paymentFormStarter presentPaymentFormFromViewController:viewController
                                                     orderId:[NSNumber numberWithDouble:randomOrderId].stringValue
                                                      amount:amount
                                                       title:name
                                                 description:description
													  cardId:[ASDKTestSettings makeNewCard] ? nil:@""// nil - новая нужно вводить реквизиты карты, @"" - последняя сохраненная, @"836252" - карта по CardId
                                                       email:nil 
                                                 customerKey:[PayController customerKey]
												   recurrent:recurrent
												  makeCharge:makeCharge
									   additionalPaymentData:data
												 receiptData:receiptData
                                                     success:^(ASDKPaymentInfo *paymentInfo)
     {
		 [[TransactionHistoryModelController sharedInstance] addTransaction:@{@"paymentId":paymentInfo.paymentId, @"paymentInfo":paymentInfo.dictionary, @"summ":amount, @"description":description, kASDKStatus:paymentInfo.status}];

         PaymentSuccessViewController *vc = [[PaymentSuccessViewController alloc] init];
         vc.amount = amount;
         UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:vc];
         
         [viewController presentViewController:nc animated:YES completion:nil];
         
         onSuccess(paymentInfo);
     }
                                                   cancelled:^
     {
         [viewController presentViewController:[PayController alertForCancel] animated:YES completion:nil];
         onCancelled();
     }
                                                       error:^(ASDKAcquringSdkError *error)
     {
         [viewController presentViewController:[PayController alertWithError:error] animated:YES completion:nil];
         onError(error);
     }];
}

+ (void)chargeWithRebillId:(NSNumber *)rebillId
					amount:(NSNumber *)amount
			   description:(NSString *)description
	 additionalPaymentData:(NSDictionary *)data
			   receiptData:(NSDictionary *)receiptData
		fromViewController:(UIViewController *)viewController
				   success:(void (^)(ASDKPaymentInfo *paymentInfo))onSuccess
					 error:(void (^)(ASDKAcquringSdkError *error))onError
{
	ASDKPaymentFormStarter *paymentFormStarter = [PayController paymentFormStarter];

	double randomOrderId = arc4random()%10000000;

	paymentFormStarter.cardScanner = [ASDKCardIOScanner scanner];

	[paymentFormStarter chargeWithRebillId:rebillId amount:amount orderId:[NSNumber numberWithDouble:randomOrderId].stringValue description:description customerKey:[PayController customerKey] additionalPaymentData:data receiptData:receiptData
		success:^(ASDKPaymentInfo *paymentInfo) {
			[[TransactionHistoryModelController sharedInstance] addTransaction:@{@"paymentId":paymentInfo.paymentId, @"paymentInfo":paymentInfo.dictionary, @"summ":amount, @"description":([description length] > 0 ? description: @""), kASDKStatus:paymentInfo.status}];

			PaymentSuccessViewController *vc = [[PaymentSuccessViewController alloc] init];
			vc.amount = amount;

			UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:vc];

			[viewController presentViewController:nc animated:YES completion:nil];

			onSuccess(paymentInfo);
		} error:^(ASDKAcquringSdkError *error) {
			[viewController presentViewController:[PayController alertWithError:error] animated:YES completion:nil];
			onError(error);
		}];
}

+ (BOOL)isPayWithAppleAvailable
{
	return [ASDKPaymentFormStarter isPayWithAppleAvailable];
}

+ (void)buyWithApplePayAmount:(NSNumber *)amount
				  description:(NSString *)description
						email:(NSString *)email
			  appleMerchantId:(NSString *)appleMerchantId
			  shippingMethods:(NSArray<PKShippingMethod *> *)shippingMethods
			  shippingContact:(PKContact *)shippingContact
	   shippingEditableFields:(PKAddressField)shippingEditableFields
					recurrent:(BOOL)recurrent
		additionalPaymentData:(NSDictionary *)data
				  receiptData:(NSDictionary *)receiptData
		   fromViewController:(UIViewController *)viewController
					  success:(void (^)(ASDKPaymentInfo *paymentIfo))onSuccess
					cancelled:(void (^)())onCancelled
						error:(void(^)(ASDKAcquringSdkError *error))onError
{
	ASDKPaymentFormStarter *paymentFormStarter = [PayController paymentFormStarter];
	[paymentFormStarter payWithApplePayFromViewController:viewController
												   amount:amount
												  orderId:[NSNumber numberWithDouble:(arc4random()%10000000)].stringValue
											  description:description
											  customerKey:[PayController customerKey]
												sendEmail:([email length] > 0)
													email:email
										  appleMerchantId:appleMerchantId
										  shippingMethods:shippingMethods
										  shippingContact:shippingContact
								   shippingEditableFields:shippingEditableFields
												recurrent:YES
									additionalPaymentData:data
											  receiptData:receiptData
												  success:^(ASDKPaymentInfo *paymentInfo) {
													  [[TransactionHistoryModelController sharedInstance] addTransaction:@{@"paymentId":paymentInfo.paymentId, @"paymentInfo":paymentInfo.dictionary, @"summ":amount, @"description":description, kASDKStatus:paymentInfo.status}];
													  PaymentSuccessViewController *vc = [[PaymentSuccessViewController alloc] init];
													  vc.amount = amount;
													  UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:vc];
													  
													  [viewController presentViewController:nc animated:YES completion:nil];
													  
													  onSuccess(paymentInfo);
												  }
												cancelled:^{
													  [viewController presentViewController:[PayController alertForCancel] animated:YES completion:nil];
													  onCancelled();
												  }
													error:^(ASDKAcquringSdkError *error) {
														if (error)
														{
															[viewController presentViewController:[PayController alertWithError:error] animated:YES completion:nil];
														}

													  onError(error);
												  }];
	//
}

+ (void)checkStatusTransaction:(NSString *)paymentId
	   fromViewController:(UIViewController *)viewController
				  success:(void (^)(ASDKPaymentStatus status))onSuccess
					error:(void(^)(ASDKAcquringSdkError *error))onError
{
	ASDKPaymentFormStarter *paymentFormStarter = [PayController paymentFormStarter];
	
	[paymentFormStarter checkStatusTransaction:paymentId success:^(ASDKPaymentStatus status) {
		onSuccess(status);
	} error:^(ASDKAcquringSdkError *error) {
		onError(error);
	}];
}

+ (void)refundTransaction:(NSString *)paymentId
	   fromViewController:(UIViewController *)viewController
				  success:(void (^)())onSuccess
					error:(void (^)(ASDKAcquringSdkError *error))onError
{
	ASDKPaymentFormStarter *paymentFormStarter = [PayController paymentFormStarter];
	
	[paymentFormStarter refundTransaction:paymentId success:^{
		 onSuccess();
	} error:^(ASDKAcquringSdkError *error) {
		NSString *errorTitle = [error.errorMessage length] > 0 ? error.errorMessage: @"Reject error";

		UIAlertController *alertController = [UIAlertController alertControllerWithTitle:errorTitle message:error.errorDetails preferredStyle:UIAlertControllerStyleAlert];
		
		UIAlertAction *cancelAction = [UIAlertAction
									   actionWithTitle:NSLocalizedString(@"Close", @"Закрыть")
									   style:UIAlertActionStyleCancel
									   handler:^(UIAlertAction *action)
									   {
										   [alertController dismissViewControllerAnimated:YES completion:nil];
									   }];
		
		[alertController addAction:cancelAction];
		
		[viewController presentViewController:alertController animated:YES completion:nil];
		
		onError(error);
	}];
}

@end
