//
//  IdCardSignViewController.swift
//  MoppApp
//
/*
 * Copyright 2017 Riigi Infosüsteemide Amet
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
 *
 */
enum IdCardSigningError: Error {
    case signingCancelled
}

protocol IdCardSignViewControllerDelegate : class {
    func idCardSignDidFinished(cancelled: Bool, success: Bool, error: Error?)
}

class IdCardSignViewController : MoppViewController {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var pin2TextField: UITextField!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var signButton: UIButton!
    @IBOutlet weak var pin2TextFieldTitleLabel: UILabel!
    @IBOutlet weak var loadingSpinner: SpinnerView!
    @IBOutlet weak var titleLabelBottomToCancelButtonCSTR: NSLayoutConstraint!
    @IBOutlet weak var titleLabelBottomToPin2TextFieldCSTR: NSLayoutConstraint!
    
    var containerPath: String!
    weak var delegate: IdCardSignViewControllerDelegate!
    
    enum State {
        case initial
        case readerNotFound     // Reader not found/selected
        case idCardNotFound     // ID card not found
        case readyForSigning    // Reader and ID card found
        case signing            // Signing in-progress
        case wrongPin2
    }
    
    var state: State = .initial {
        didSet {
            updateStateUI(newState: state)
        }
    }
    
    var pin2AttemptsLeft: UInt = 0
    var initialStateStartedTime: TimeInterval = 0
    var initialStateExpirationTimer: Timer? = nil
    var idCardPersonalData: MoppLibPersonalData? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        MoppLibCardReaderManager.sharedInstance().delegate = self
    
        cancelButton.setTitle(L(.actionCancel).uppercased())
        signButton.setTitle(L(.actionSign).uppercased())
    
        pin2TextField.delegate = self
        pin2TextField.addTarget(self, action: #selector(editingChanged(sender:)), for: .editingChanged)
        pin2TextField.layer.borderColor = UIColor.moppContentLine.cgColor
        pin2TextField.layer.borderWidth = 1.0
        pin2TextField.moppPresentDismissButton()
        
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name.UIApplicationDidBecomeActive,
            object: nil,
            queue: OperationQueue.main) { [weak self]_ in
            guard let sself = self else { return }
            let showLoading =
                sself.state == .initial ||
                sself.state == .readerNotFound ||
                sself.state == .idCardNotFound ||
                sself.state == .signing
            self?.loadingSpinner.show(showLoading)
            self?.pin2TextField.resignFirstResponder()
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        if (pin2TextField != nil) {
            pin2TextField.removeTarget(self, action: #selector(editingChanged(sender:)), for: .editingChanged)
        }
    }
    
    @objc func editingChanged(sender: UITextField) {
        let count = (sender.text?.count ?? 0)
        signButton.isEnabled = count >= 4 && count <= 6
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        updateStateUI(newState: state)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        MoppLibCardReaderManager.sharedInstance().startDetecting()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        MoppLibCardReaderManager.sharedInstance().stopDetecting()
    }
    
    @objc func changeState() {
        state = .readyForSigning
    }
    
    func updateStateUI(newState: State) {
        print("Update state", newState)
        switch newState {
        case .initial:
            signButton.isEnabled = false
            pin2TextField.isHidden = true
            pin2TextField.text = nil
            pin2TextFieldTitleLabel.isHidden = true
            pin2TextFieldTitleLabel.text = nil
            pin2TextFieldTitleLabel.textColor = UIColor.moppBaseBackground
            loadingSpinner.show(true)
            titleLabel.text = L(.cardReaderStateInitial)
        case .readerNotFound:
            signButton.isEnabled = false
            pin2TextField.isHidden = true
            pin2TextField.text = nil
            pin2TextFieldTitleLabel.isHidden = true
            pin2TextFieldTitleLabel.text = nil
            pin2TextFieldTitleLabel.textColor = UIColor.moppBaseBackground
            loadingSpinner.show(true)
            titleLabel.text = L(.cardReaderStateReaderNotFound)
        case .idCardNotFound:
            signButton.isEnabled = false
            pin2TextField.isHidden = true
            pin2TextField.text = nil
            pin2TextFieldTitleLabel.isHidden = true
            pin2TextFieldTitleLabel.text = nil
            pin2TextFieldTitleLabel.textColor = UIColor.moppBaseBackground
            loadingSpinner.show(true)
            titleLabel.text = L(.cardReaderStateIdCardNotFound)
        case .readyForSigning:
            let fullname = idCardPersonalData?.fullName() ?? String()
            let personalCode = idCardPersonalData?.personalIdentificationCode ?? String()
            titleLabel.text = L(.cardReaderStateReady, [fullname, personalCode])
            signButton.isEnabled = false
            pin2TextField.isHidden = false
            pin2TextField.text = nil
            pin2TextFieldTitleLabel.isHidden = false
            pin2TextFieldTitleLabel.text = L(.pin2TextfieldLabel)
            pin2TextFieldTitleLabel.textColor = UIColor.moppText
            loadingSpinner.show(false)
        case .signing:
            signButton.isEnabled = false
            pin2TextField.isHidden = true
            pin2TextField.text = nil
            pin2TextFieldTitleLabel.isHidden = true
            pin2TextFieldTitleLabel.text = nil
            pin2TextFieldTitleLabel.textColor = UIColor.moppBaseBackground
            loadingSpinner.show(true)
            titleLabel.text = L(.signingInProgress)
        case .wrongPin2:
            let fullname = idCardPersonalData?.fullName() ?? String()
            let personalCode = idCardPersonalData?.personalIdentificationCode ?? String()
            titleLabel.text = L(.cardReaderStateReady, [fullname, personalCode])
            signButton.isEnabled = false
            pin2TextField.isHidden = false
            pin2TextField.text = nil
            pin2TextFieldTitleLabel.isHidden = false
            pin2TextField.text = nil
            loadingSpinner.show(false)
            pin2TextFieldTitleLabel.textColor = UIColor.moppError
            pin2TextFieldTitleLabel.text = pin2AttemptsLeft > 1 ? L(.wrongPin2, [pin2AttemptsLeft, pin2AttemptsLeft]) : L(.wrongPin2Single)
        }
        
        if newState == .initial {
            initialStateExpirationTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: false, block: { [weak self]_ in
                DispatchQueue.main.async {
                    self?.state = .readerNotFound
                }
            })
        } else {
            initialStateExpirationTimer?.invalidate()
            initialStateExpirationTimer = nil
        }
        
        view.layoutIfNeeded()
    }
    
    override func willEnterForeground() {
        super.willEnterForeground()
        loadingSpinner.show(true)
    }
    
    @IBAction func cancelAction() {
        let signingCancelled = state == .signing
        dismiss(animated: false) {
            [weak self] in
            guard let sself = self else { return }
            var error: IdCardSigningError? = nil
            if signingCancelled {
                error = .signingCancelled
            }
            sself.delegate?.idCardSignDidFinished(cancelled: true, success: false, error: error)
        }
    }
    
    @IBAction func signAction() {
        guard let pin2 = pin2TextField.text else {
            // TODO: Display error message about empty PIN 2 text field
            return
        }
        
        state = .signing
        MoppLibContainerActions.sharedInstance().addSignature(containerPath, withPin2:pin2, controller: self, success: { [weak self] container, signatureAdded in
            DispatchQueue.main.async {
                self?.dismiss(animated: false, completion: {
                    self?.delegate?.idCardSignDidFinished(cancelled: false, success: signatureAdded, error: nil)
                })
            }
        }, failure: { [weak self] error in
            guard let nsError = error as NSError? else { return }
            if nsError.code == Int(MoppLibErrorCode.moppLibErrorWrongPin.rawValue) { // Wrong PIN2 error
                DispatchQueue.main.async {
                    self?.pin2AttemptsLeft = (nsError.userInfo[kMoppLibUserInfoRetryCount] as? NSNumber)?.uintValue ?? 0
                    self?.state = .wrongPin2
                }
            } else {
                DispatchQueue.main.async {
                    self?.dismiss(animated: false, completion: {
                        self?.delegate?.idCardSignDidFinished(cancelled: false, success: false, error: error)
                    })
                }
            }
        })
        
    }
}

extension IdCardSignViewController : MoppLibCardReaderManagerDelegate {
    func moppLibCardReaderStatusDidChange(_ readerStatus: MoppLibCardReaderStatus) {
        switch readerStatus {
        case .ReaderNotConnected:
            state = .readerNotFound
        case .ReaderConnected:
            state = .idCardNotFound
        case .CardConnected:
            MoppLibCardActions.minimalCardPersonalData(with: self, success: { [weak self] moppLibPersonalData in
                DispatchQueue.main.async {
                    self?.idCardPersonalData = moppLibPersonalData
                    self?.state = .readyForSigning
                }
            }, failure: { [weak self]_ in
                self?.state = .readerNotFound
            })
        }
    }
}

extension IdCardSignViewController : UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if string.count == 0 {
            return true
        }
        let text = (textField.text ?? String()) + string
        return text.isNumeric && text.count < 12
    }
}