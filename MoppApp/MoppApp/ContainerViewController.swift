//
//  ContainerViewController.swift
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
import Foundation


class ContainerViewController : MoppViewController {

    var container: MoppLibContainer!
    var containerPath: String? = nil
    @IBOutlet weak var tableView: UITableView!

    enum Section {
        case error
        case signatures
        case missingSignatures
        case timestamp
        case files
        case importFiles
        case header
        case search
    }

    var isSectionRowEditable: [Section: Bool] = [
        .error          : false,
        .signatures     : true,
        .timestamp      : false,
        .files           : true,
        .header         : false,
        .search         : false
        ]

    var sectionHeaderTitle: [Section: String] = [
        .files           : L(LocKey.containerHeaderFilesTitle),
        .timestamp      : L(LocKey.containerHeaderTimestampTitle),
        .signatures     : L(LocKey.containerHeaderSignaturesTitle)
        ]

    private static let sectionsWithError: [Section] = [.error, .header, .files, .signatures]
    private static let sectionsDefault  : [Section] = [.header, .files, .signatures]
    private static let sectionsNoSignatures : [Section] = [.header, .files, .importFiles]
    
    var sections: [Section] = ContainerViewController.sectionsDefault


    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationItemForPushedViewController()
        NotificationCenter.default.addObserver(self, selector: #selector(signatureCreatedFinished), name: .signatureCreatedFinishedNotificationName, object: nil)
        LandingTabBarController.shared.tabButtonsDelegate = self
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func signatureCreatedFinished() {
        DispatchQueue.main.async {
        [weak self] in
            self?.openContainer()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        LandingTabBarController.shared.presentButtons([.signButton, .shareButton])
    
        tableView.estimatedRowHeight = ContainerSignatureCell.height
        tableView.rowHeight = UITableViewAutomaticDimension
        
        if containerPath != nil {
            showLoading(show: true)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        guard let containerPath = containerPath else {
            return
        }
        
        openContainer()
    }
    
    func openContainer() {
            MoppLibContainerActions.sharedInstance().getContainerWithPath(containerPath, success: { [weak self] container in
            guard let container = container else {
                return
            }
            
            guard let strongSelf = self else { return }
            
            let containsInvalidSignature = (container.signatures as! [MoppLibSignature]).contains(where: { !$0.isValid })
            if containsInvalidSignature {
                strongSelf.sections = ContainerViewController.sectionsWithError
            } else {
                strongSelf.sections = ContainerViewController.sectionsDefault
            }
            
            strongSelf.container = container
            strongSelf.reloadData()
            strongSelf.showLoading(show: false)
            
        }, failure: { [weak self] error in
            self?.showLoading(show: false)
            let nserror = error! as NSError
            var message = nserror.domain
            if (nserror.code == moppLibErrorGeneral.rawValue) {
                message = L(LocKey.errorAlertTitleGeneral)
            }
            self?.errorAlert(message: message, dismissCallback: { _ in
                _ = self?.navigationController?.popViewController(animated: true)
            });
        })
    }
    
    override func showLoading(show: Bool, forFrame: CGRect? = nil) {
        super.showLoading(show: show, forFrame: tableView.frame)
        tableView.isHidden = show
    }
    
    override func willEnterForeground() {
        refreshLoadingAnimation()
    }

    func startSigningWithMobileID() {
        let mobileIdEditViewController = UIStoryboard.landing.instantiateViewController(with: MobileIDEditViewController.self)
            mobileIdEditViewController.modalPresentationStyle = .overFullScreen
            mobileIdEditViewController.delegate = self
        present(mobileIdEditViewController, animated: false, completion: nil)
    }
}

extension ContainerViewController {
    func setupNavigationItemForPushedViewController() {
        setupNavigationItemForPushedViewController(title: L(LocKey.containerTitle))
    }
}

extension ContainerViewController {
    var errorHidden: Bool {
        get { return !sections.contains(.error) }
        set {
            sections = newValue ?
                ContainerViewController.sectionsDefault :
                ContainerViewController.sectionsWithError
            reloadData()
        }
    }
}

extension ContainerViewController : LandingTabBarControllerTabButtonsDelegate {
    func landingTabBarControllerTabButtonTapped(tabButtonId: LandingTabBarController.TabButtonId) {
        if tabButtonId == .signButton {
            startSigningWithMobileID()
        }
    }
}

extension ContainerViewController : UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let container = container else {
            return 0
        }
        
        switch sections[section] {
        case .signatures:
            return container.signatures.count
        case .files:
            return container.dataFiles.count
        case .error, .missingSignatures, .header, .search, .timestamp, .importFiles:
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = indexPath.row
        switch sections[indexPath.section] {
        case .error:
            let cell = tableView.dequeueReusableCell(withType: ContainerErrorCell.self, for: indexPath)!
            return cell
        case .signatures:
            let cell = tableView.dequeueReusableCell(withType: ContainerSignatureCell.self, for: indexPath)!
            cell.delegate = self
            let signature = container.signatures[row] as! MoppLibSignature
            cell.populate(
                with: signature,
                kind: .signature,
                showBottomBorder: row < container.signatures.count - 1,
                signatureIndex: row)
            return cell
        case .missingSignatures:
            let cell = tableView.dequeueReusableCell(withType: ContainerNoSignaturesCell.self, for: indexPath)!
            return cell
        case .timestamp:
            let cell = tableView.dequeueReusableCell(withType: ContainerSignatureCell.self, for: indexPath)!
                //cell.populate(name: mockTimestamp[row], kind: .timestamp, colorTheme: .neutral, showBottomBorder: row < mockTimestamp.count - 1)
            return cell
        case .files:
            let cell = tableView.dequeueReusableCell(withType: ContainerFileCell.self, for: indexPath)!
                cell.delegate = self
                cell.populate(
                    name: (container.dataFiles as! [MoppLibDataFile])[row].fileName,
                    showBottomBorder: row < container.dataFiles.count - 1,
                    showRemoveButton: container.dataFiles.count > 1,
                    dataFileIndex: row)
            return cell
        case .importFiles:
            return tableView.dequeueReusableCell(withType: ContainerImportFilesCell.self, for: indexPath)!
        case .header:
            let cell = tableView.dequeueReusableCell(withType: ContainerHeaderCell.self, for: indexPath)!
                cell.populate(name: container.fileName)
            return cell
        case .search:
            let cell = tableView.dequeueReusableCell(withType: ContainerSearchCell.self, for: indexPath)!
            return cell
        }
    }
}

extension ContainerViewController : ContainerSignatureDelegate {
    func containerSignatureRemove(signatureIndex: Int) {
            guard let signature = container.signatures[signatureIndex] as? MoppLibSignature else {
                return
            }
        
            confirmDeleteAlert(
                message: L(.signatureRemoveConfirmMessage),
                confirmCallback: { [weak self] (alertAction) in
                
                MoppLibContainerActions.sharedInstance().remove(
                    signature,
                    fromContainerWithPath: self?.container.filePath,
                    success: { [weak self] container in
                        self?.container.signatures.remove(at: signatureIndex)
                        self?.reloadData()
                    },
                    failure: { [weak self] error in
                        self?.reloadData()
                        self?.errorAlert(message: error?.localizedDescription)
                    })
            })
    }
}

extension ContainerViewController : ContainerFileDelegate {
    func removeDataFile(dataFileIndex: Int) {    
        confirmDeleteAlert(
            message: L(.datafileRemoveConfirmMessage),
            confirmCallback: { [weak self] (alertAction) in
            MoppLibContainerActions.sharedInstance().removeDataFileFromContainer(
                withPath: self?.containerPath,
                at: UInt(dataFileIndex),
                success: { [weak self] container in
                    self?.container.dataFiles.remove(at: dataFileIndex)
                    self?.reloadData()
                },
                failure: { [weak self] error in
                    self?.reloadData()
                    self?.errorAlert(message: error?.localizedDescription)
                })
        })
    }
}

extension ContainerViewController : UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch sections[indexPath.section] {
        case .error:
            break
        case .signatures:
            let signatureDetailsViewController = UIStoryboard.container.instantiateViewController(with: SignatureDetailsViewController.self)
            navigationController?.pushViewController(signatureDetailsViewController, animated: true)
            break
        case .missingSignatures:
            break
        case .timestamp:
            break;
        case .files:
            let dataFile = container.dataFiles[indexPath.row] as! MoppLibDataFile
            let destinationPath = MoppFileManager.shared.tempFilePath(withFileName: dataFile.fileName)
            MoppLibContainerActions.sharedInstance().container(
                container.filePath,
                saveDataFile: dataFile.fileName,
                to: destinationPath,
                success: { [weak self] in
                    let (_, ext) = dataFile.fileName.filenameComponents()
                    if ext.isContainerExtension {
                        let containerViewController = UIStoryboard.container.instantiateInitialViewController(of: ContainerViewController.self)
                            containerViewController.containerPath = destinationPath
                            self?.navigationController?.pushViewController(containerViewController, animated: true)
                    } else {
                        let dataFilePreviewViewController = UIStoryboard.container.instantiateViewController(with: DataFilePreviewViewController.self)
                            dataFilePreviewViewController.previewFilePath = destinationPath
                        self?.navigationController?.pushViewController(dataFilePreviewViewController, animated: true)
                    }
                    
                }, failure: { [weak self] error in
                    self?.errorAlert(message: error?.localizedDescription)
                })
            
            break
        case .header:
            break
        case .search:
            break
        case .importFiles:
            break
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection _section: Int) -> UIView? {
        let section = sections[_section]
        if let title = sectionHeaderTitle[section] {
            if let header = MoppApp.instance.nibs[.containerElements]?.instantiate(withOwner: self, type: ContainerTableViewHeaderView.self) {
                header.delegate = self
                header.populate(withTitle: title, section: section)
                return header
            }
        }
        return nil
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection _section: Int) -> CGFloat {
        let section = sections[_section]
        if sectionHeaderTitle[section] != nil {
            return ContainerTableViewHeaderView.height
        }
        return 0
    }
    
    func reloadData() {
        guard let container = container else {
            return
        }

        if container.signatures.isEmpty {
            LandingTabBarController.shared.presentButtons([.signButton])
            setupNavigationItemForPushedViewController(title: L(.containerSignTitle))
        } else {
            LandingTabBarController.shared.presentButtons([.signButton, .shareButton])
            setupNavigationItemForPushedViewController(title: L(.containerValidateTitle))
        }

        if container.signatures.isEmpty {
            sections = ContainerViewController.sectionsNoSignatures
            if let signaturesIndex = sections.index(where: { $0 == .signatures }) {
                if !sections.contains(.missingSignatures) {
                    sections.insert(.missingSignatures, at: signaturesIndex + 1)
                }
            }
        } else {
            sections = ContainerViewController.sectionsDefault
        }
        
        tableView.reloadData()
    }
}

extension ContainerViewController : ContainerTableViewHeaderViewDelegate {
    func containerTableViewHeaderViewAddFiles(forSection section: ContainerViewController.Section) {
        if section == .signatures {
            startSigningWithMobileID()
        }
    }
    
    func decideLanguageBasedOnPreferredLanguages() -> String {
        var language: String = String()
        let prefLanguages = NSLocale.preferredLanguages
        for i in 0..<prefLanguages.count {
            if prefLanguages[i].hasPrefix("et-") {
                language = "EST"
                break
            }
            else if prefLanguages[i].hasPrefix("lt-") {
                language = "LIT"
                break
            }
            else if prefLanguages[i].hasPrefix("ru-") {
                language = "RUS"
                break
            }
        }
        if language.isEmpty {
            language = "ENG"
        }
        
        return language
    }

}

extension ContainerViewController : MobileIDEditViewControllerDelegate {   
    func mobileIDEditViewControllerDidDismiss(cancelled: Bool, phoneNumber: String?, idCode: String?) {
        if cancelled { return }
        
        guard let phoneNumber = phoneNumber else { return }
        guard let idCode = idCode else { return }
        
        let mobileIDChallengeview = UIStoryboard.landing.instantiateViewController(with: MobileIDChallengeViewController.self)
        mobileIDChallengeview.modalPresentationStyle = .overFullScreen
        present(mobileIDChallengeview, animated: false)

        Session.shared.createMobileSignature(
            withContainer: container.filePath,
            idCode: idCode,
            language: decideLanguageBasedOnPreferredLanguages(),
            phoneNumber: phoneNumber)
    }
}
