import UIKit
import SwipeCellKit
protocol CustomTableViewCellDelegate: AnyObject {
    func deleteReminder(at indexPath: IndexPath)
}

final class CustomTableViewCell: UITableViewCell, SwipeTableViewCellDelegate {

    
    weak var delegate: CustomTableViewCellDelegate?

    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> [SwipeAction]? {
        guard orientation == .right else { return nil }

        let deleteAction = SwipeAction(style: .destructive, title: "Delete") { action, indexPath in
            // Handle the delete action here
            self.delegate?.deleteReminder(at: indexPath)
        }

        deleteAction.image = UIImage(named: "Trash")

        return [deleteAction]
    }


    
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private let containerView = UIStackView()
    private let cellView = CustomTableCellView()
    private let detailView = CustomTableDetailView()
    
    func setUI(with index: Int) {
        cellView.setUI(with: "", date: "date")
        detailView.setUI(with: "",
                         stringTwo: "")
    }
    
    func commonInit() {
        selectionStyle = .none
        detailView.isHidden = true

        
        containerView.axis = .vertical

        contentView.addSubview(containerView)
        containerView.addArrangedSubview(cellView)
        containerView.addArrangedSubview(detailView)
        
        containerView.translatesAutoresizingMaskIntoConstraints = false
        cellView.translatesAutoresizingMaskIntoConstraints = false
        detailView.translatesAutoresizingMaskIntoConstraints = false
        
        containerView.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor).isActive = true
        containerView.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor).isActive = true
        containerView.topAnchor.constraint(equalTo: self.contentView.topAnchor).isActive = true
        containerView.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor).isActive = true
        

    }
}

extension CustomTableViewCell {
    var isDetailViewHidden: Bool {
        return detailView.isHidden
    }

    func showDetailView() {
        detailView.isHidden = false
    }

    func hideDetailView() {
        detailView.isHidden = true
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        if isDetailViewHidden, selected {
            showDetailView()
        } else {
            hideDetailView()
        }
    }
}
