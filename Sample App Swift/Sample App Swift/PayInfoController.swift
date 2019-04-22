//
//  PayInfoController.swift
//  Pay Info Demo
//
//  Created by Roman Savrulin on 14/03/2019.
//  Copyright © 2019 romansavrulin. All rights reserved.
//

import Foundation
import UIKit
import PassKit
import ASDKUI
import ASDKCore

class PayInfoController: UIViewController {
    
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var payButton: UIButton!
    @IBOutlet weak var attachButton: UIButton!
    
    var purchasePrice: Decimal = 0.0
    
    var authorized: Bool = false
    
    let email = "user@domain.org"
    
    let productTitle = "Product"
    let productDescription = "Descr"
    let customerKey = "101010"
    
    enum PayForm {
        case applePay
        case Card
        case Combo
    }
    
    var payOption:PayForm = .Card
    
    func generateSum() {
        let pricef:Double = Double.random(in: 0 ..< 5)
        purchasePrice = Decimal(pricef)
        priceLabel.text = String(format:"%0.2f", pricef)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addApplePayPaymentButtonToView()
        authorized = false
        
        generateSum()
        
        payButton.isHidden = false
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func PayWithCard(_ sender: UIButton) {
        payOption = .Card
        pay()
    }
    @IBAction func EditCards(_ sender: UIButton) {
        guard let asdk_pfs = ASDKPaymentFormStarter.init(acquiringSdk: asdk) else {
            return //TODO: restore state!
        }
        asdk_pfs.presentCardListForm(from: self, customerKey: customerKey, addHandler: { [weak self] in
            self?.attachCard()
        }, error: payError)
    }
    
    @IBAction func AttachCard(_ sender: UIButton) {
        attachCard()
    }
    
    private func attachCard() {
        guard let asdk_pfs = ASDKPaymentFormStarter.init(acquiringSdk: asdk) else {
            return //TODO: restore state!
        }
        
        guard let design_config = asdk_pfs.designConfiguration else {
            return //TODO: restore state!
        }
        
        let des_elem:Array<NSNumber> =
            [TableViewCellType.CellEmpty20px.rawValue as NSNumber,
             TableViewCellType.CellAmount.rawValue as NSNumber,
             TableViewCellType.CellPaymentCardRequisites.rawValue as NSNumber,
             
             TableViewCellType.CellEmptyFlexibleSpace.rawValue as NSNumber,
             TableViewCellType.CellAttachButton.rawValue as NSNumber,
             TableViewCellType.CellEmpty20px.rawValue as NSNumber,
             TableViewCellType.CellSecureLogos.rawValue as NSNumber
        ]
        
        design_config.setAttachCardItems(des_elem)
        
        print("Pay Form Items: \(String(describing: design_config.payFormItems()?.count))")
        print(design_config.payFormItems())
        
        asdk_pfs.presentAttachForm(
            from: self,
            formTitle: "Attach Form",
            formHeader: "Header",
            description: productDescription,
            email: email,
            cardCheckType: ASDKCardCheckType_NO,//ASDKCardCheckType_3DSHOLD,
            customerKey: customerKey,
            additionalData: nil,
            success: attachSuccess,
            cancelled: payCancelled,
            error: payError)
    }
    
    private func addApplePayPaymentButtonToView() {
        let paymentButton = PKPaymentButton(paymentButtonType: .buy, paymentButtonStyle: .black)
        paymentButton.translatesAutoresizingMaskIntoConstraints = false
        paymentButton.addTarget(self, action: #selector(applePayButtonTapped(sender:)), for: .touchUpInside)
        view.addSubview(paymentButton)
        
        view.addConstraint(NSLayoutConstraint(item: paymentButton, attribute: .centerX, relatedBy: .equal, toItem: view, attribute: .centerX, multiplier: 1, constant: 0))
        view.addConstraint(NSLayoutConstraint(item: paymentButton, attribute: .centerY, relatedBy: .equal, toItem: view, attribute: .centerY, multiplier: 1, constant: 100))
        
        payButton = paymentButton
    }
    
    private func paySuccess(pi:ASDKPaymentInfo?) -> Void {
        print ("Pay Success")
        generateSum()
    }
    
    private func attachSuccess(pi:ASDKResponseAttachCard?) -> Void {
        print("Attach Success")
    }
    
    private func payCancelled() -> Void {
        print("Pay Cancell")
        generateSum()
    }
    
    private func payError(er:ASDKAcquringSdkError?) -> Void {
        print("Pay Error")
        generateSum()
    }
    
    private func pay() {
        guard let asdk_pfs = ASDKPaymentFormStarter.init(acquiringSdk: asdk) else {
            return //TODO: restore state!
        }
        
        guard let design_config = asdk_pfs.designConfiguration else {
            return //TODO: restore state!
        }
        
        let des_elem:Array<NSNumber> =
            [TableViewCellType.CellEmpty20px.rawValue as NSNumber,
             TableViewCellType.CellAmount.rawValue as NSNumber,
             TableViewCellType.CellPaymentCardRequisites.rawValue as NSNumber,
             TableViewCellType.CellAttachButton.rawValue as NSNumber,
             
             TableViewCellType.CellEmpty20px.rawValue as NSNumber,
             TableViewCellType.CellEmptyFlexibleSpace.rawValue as NSNumber,
             TableViewCellType.CellPayButton.rawValue as NSNumber,
             TableViewCellType.CellEmpty20px.rawValue as NSNumber,
             TableViewCellType.CellSecureLogos.rawValue as NSNumber
        ]
        
        design_config.setPayFormItems(des_elem)
        
        print("Pay Form Items: \(String(describing: design_config.payFormItems()?.count))")
        print(design_config.payFormItems())
        
        let pb:UIButton = UIButton(frame: CGRect(x: 0, y: 0, width: 280, height: 60))
        
        pb.backgroundColor = UIColor.red;
        pb.setTitle("Оплатить !!!!", for: UIControl.State.normal)
        //[payButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        //[payButton setTitleColor:[UIColor blueColor] forState:UIControlStateHighlighted];
        
        pb.layer.cornerRadius = 10;
        pb.clipsToBounds = true;
        
        design_config.setCustomPay(pb);
        
        //asdk_pfs.cardScanner //= //ASDKCardIOScanner. // scanner];
        
        let fields:PKAddressField = []//PKAddressField.phone
        
        let orderId = String(arc4random()%10000000);
        
        switch (payOption){
        case .applePay:
            asdk_pfs.payWithApplePay(
                from: self,
                amount: purchasePrice as NSNumber,
                orderId: orderId,
                description: productDescription,
                customerKey: customerKey,
                sendEmail: false,
                email: email,
                appleMerchantId: AppleMerchantID,
                shippingMethods: nil,
                shippingContact: nil,
                shippingEditableFields: fields,
                recurrent: false,
                additionalPaymentData: nil,
                receiptData: nil,
                shopsData: nil,
                shopsReceiptsData: nil,
                success: paySuccess,
                cancelled: payCancelled,
                error: payError)
            break
        case .Card:
            asdk_pfs.presentPaymentForm(
                from: self,
                orderId: orderId,
                amount: purchasePrice as NSNumber,
                title: productTitle,
                description: productDescription,
                cardId: "",
                email: email,
                customerKey: customerKey,
                recurrent: false,
                makeCharge: false,
                additionalPaymentData: nil,
                receiptData: nil,
                success: paySuccess,
                cancelled: payCancelled,
                error: payError)
            break
        default:
            break
            
        }
    }
    
    @objc private func applePayButtonTapped(sender: UIButton) {
        payOption = .applePay
        pay()
    }
}
