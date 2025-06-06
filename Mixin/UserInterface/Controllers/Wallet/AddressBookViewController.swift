import UIKit
import MixinServices

final class AddressBookViewController: UIViewController {
    
    @IBOutlet weak var searchBoxView: SearchBoxView!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var newAddressButton: UIButton!
    @IBOutlet weak var moreActionButton: UIButton!
    
    var onSelect: ((Address) -> Void)?
    
    private let token: any ValuableToken & OnChainToken
    
    private var addresses: [Address] = []
    private var searchResult: [Address] = []
    
    private var isSearching: Bool {
        !(searchBoxView.textField.text ?? "").isEmpty
    }
    
    init(token: any ValuableToken & OnChainToken) {
        self.token = token
        let nib = R.nib.addressBookView
        super.init(nibName: nib.name, bundle: nib.bundle)
    }
    
    required init?(coder: NSCoder) {
        fatalError("Storyboard not supported")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = R.string.localizable.address()
        
        // UIButton with image and title failed to calculate intrinsicContentSize if bold text is turned on in iOS Display Settings
        // Set lineBreakMode to byClipping as a workaround. Tested on iOS 15.1
        newAddressButton.titleLabel?.lineBreakMode = .byClipping
        
        searchBoxView.textField.addTarget(self, action: #selector(searchAction(_:)), for: .editingChanged)
        updateCancelButton()
        tableView.register(R.nib.addressCell)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.tableFooterView = UIView()
        moreActionButton.showsMenuAsPrimaryAction = true
        moreActionButton.menu = UIMenu(children: [
            UIAction(
                title: R.string.localizable.delete_address(),
                image: R.image.conversation.ic_action_delete(),
                attributes: .destructive,
                handler: { [weak self] _ in
                    guard let self else {
                        return
                    }
                    self.tableView.setEditing(true, animated: true)
                    self.updateCancelButton()
                }
            )
        ])
        reloadLocalAddresses()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(reloadLocalAddresses),
            name: AddressDAO.addressDidChangeNotification,
            object: nil
        )
        AddressAPI.addresses(chainID: token.chainID) { (result) in
            guard case let .success(addresses) = result else {
                return
            }
            DispatchQueue.global().async {
                AddressDAO.shared.insertOrUpdateAddress(addresses: addresses)
            }
        }
    }
    
    @IBAction func newAddressAction() {
        presentingViewController?.dismiss(animated: true) { [token] in
            let input: AddressInfoInputViewController = .newAddress(token: token)
            UIApplication.homeNavigationController?.pushViewController(input, animated: true)
        }
    }
    
    @objc private func searchAction(_ sender: Any) {
        let keyword = (searchBoxView.textField.text ?? "").lowercased()
        if keyword.isEmpty {
            searchResult = []
        } else {
            searchResult = addresses.filter { address in
                address.label.lowercased().contains(keyword)
                || address.destination.lowercased().contains(keyword)
            }
        }
        tableView.reloadData()
    }
    
    @objc private func close(_ sender: Any) {
        presentingViewController?.dismiss(animated: true)
    }
    
    @objc private func endEditing(_ sender: Any) {
        tableView.setEditing(false, animated: true)
        updateCancelButton()
    }
    
}

extension AddressBookViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        isSearching ? searchResult.count : addresses.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell{
        let cell = tableView.dequeueReusableCell(withIdentifier: R.reuseIdentifier.address, for: indexPath)!
        if isSearching {
            cell.render(address: searchResult[indexPath.row])
        } else {
            cell.render(address: addresses[indexPath.row])
        }
        return cell
    }
    
}

extension AddressBookViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let address = isSearching ? searchResult[indexPath.row] : addresses[indexPath.row]
        onSelect?(address)
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        !isSearching
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        UISwipeActionsConfiguration(actions: [deleteAction(forRowAt: indexPath)])
    }
    
}

extension AddressBookViewController {
    
    @objc private func reloadLocalAddresses() {
        let chainId = token.chainID
        DispatchQueue.global().async { [weak self] in
            let addresses = AddressDAO.shared.getAddresses(chainId: chainId)
            DispatchQueue.main.async {
                guard let weakSelf = self else {
                    return
                }
                weakSelf.addresses = addresses
                weakSelf.newAddressButton.isHidden = !addresses.isEmpty
                weakSelf.tableView.reloadData()
            }
        }
    }
    
    private func deleteAction(forRowAt indexPath: IndexPath) -> UIContextualAction {
        UIContextualAction(style: .destructive, title: R.string.localizable.delete()) { [weak self] (action, _, completionHandler: (Bool) -> Void) in
            guard let self = self else {
                return
            }
            if self.searchBoxView.textField.isFirstResponder {
                self.searchBoxView.textField.resignFirstResponder()
            }
            let address = self.addresses[indexPath.row]
            let preview = EditAddressPreviewViewController(
                token: token,
                label: address.label,
                destination: address.destination,
                tag: address.tag,
                action: .delete(id: address.addressId)
            )
            self.present(preview, animated: true)
            completionHandler(true)
        }
    }
    
    private func updateCancelButton() {
        cancelButton.removeTarget(self, action: nil, for: .touchUpInside)
        if tableView.isEditing {
            cancelButton.configuration?.title = R.string.localizable.done()
            cancelButton.addTarget(self, action: #selector(endEditing(_:)), for: .touchUpInside)
        } else {
            cancelButton.configuration?.title = R.string.localizable.cancel()
            cancelButton.addTarget(self, action: #selector(close(_:)), for: .touchUpInside)
        }
    }
    
}
