//
// Copyright (c) Vatsal Manot
//

import Swift
import SwiftUI

#if os(iOS) || os(tvOS) || targetEnvironment(macCatalyst)

public class UIHostingTableViewCell<ItemType: Identifiable, Content: View>: UITableViewCell {
    struct State: Hashable {
        let isFocused: Bool
        let isHighlighted: Bool
        let isSelected: Bool
    }
    
    var tableViewController: UITableViewController!
    var indexPath: IndexPath?
    
    var item: ItemType!
    var makeContent: ((ItemType) -> Content)!
    
    var state: State {
        .init(
            isFocused: isFocused,
            isHighlighted: isHighlighted,
            isSelected: isSelected
        )
    }
    
    var contentHostingController: UIHostingController<RootView>!
    
    override public func awakeFromNib() {
        super.awakeFromNib()
        
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            contentView.leftAnchor.constraint(equalTo: leftAnchor),
            contentView.rightAnchor.constraint(equalTo: rightAnchor),
            contentView.topAnchor.constraint(equalTo: topAnchor),
            contentView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func reload(with animation: UITableView.RowAnimation) {
        guard let indexPath = indexPath else {
            return
        }
        
        tableViewController.tableView.reloadRows(at: [indexPath], with: animation)
    }
}

extension UIHostingTableViewCell {
    func update() {
        if contentHostingController == nil {
            backgroundColor = .clear
            backgroundView = .init()
            contentView.backgroundColor = .clear
            contentView.bounds.origin = .zero
            layoutMargins = .zero
            selectedBackgroundView = .init()
            
            contentHostingController = UIHostingController(rootView: RootView(base: self))
            contentHostingController.view.backgroundColor = .clear
            contentHostingController.view.translatesAutoresizingMaskIntoConstraints = false
            
            contentHostingController.willMove(toParent: tableViewController)
            tableViewController.addChild(contentHostingController)
            contentView.addSubview(contentHostingController.view)
            contentHostingController.didMove(toParent: tableViewController)
            
            NSLayoutConstraint.activate([
                contentHostingController.view.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
                contentHostingController.view.topAnchor.constraint(equalTo: contentView.topAnchor),
                contentHostingController.view.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
                contentHostingController.view.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
            ])
        } else {
            contentHostingController.rootView = RootView(base: self)
            contentHostingController.view.invalidateIntrinsicContentSize()
        }
    }
    
    func reset() {
        contentHostingController.willMove(toParent: nil)
        contentHostingController.view.removeFromSuperview()
        contentHostingController.removeFromParent()
        contentHostingController = nil
        
        update()
    }
}

// MARK: - Auxiliary Implementation -

extension UIHostingTableViewCell {
    struct RootView: View {
        private struct _ListRowManager: ListRowManager {
            weak var uiTableViewCell: UIHostingTableViewCell<ItemType, Content>?
            
            func _animate(_ action: () -> ()) {
                uiTableViewCell?.tableViewController.tableView.beginUpdates()
                action()
                uiTableViewCell?.tableViewController.tableView.endUpdates()
            }
            
            func _reload() {
                uiTableViewCell?.reload(with: .none)
            }
        }
        
        private let id: AnyHashable
        private let content: Content
        private let state: State
        
        private let listRowManager: _ListRowManager
        
        init(base: UIHostingTableViewCell<ItemType, Content>) {
            self.id = base.item.id
            self.content = base.makeContent(base.item)
            self.state = base.state
            
            self.listRowManager = .init(uiTableViewCell: base)
        }
        
        var body: some View {
            content
                .environment(\.listRowManager, listRowManager)
                .environment(\.isCellFocused, state.isFocused)
                .environment(\.isCellHighlighted, state.isHighlighted)
                .environment(\.isCellSelected, state.isSelected)
                .id(id)
        }
    }
}

// MARK: - Helpers -

extension String {
    static let hostingTableViewCellIdentifier = "UIHostingTableViewCell"
}

#endif
