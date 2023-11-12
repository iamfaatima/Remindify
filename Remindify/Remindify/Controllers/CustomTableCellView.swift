import UIKit

final class CustomTableCellView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private let title = UILabel()
    private let dateLabel = UILabel() // Add a new UILabel for the date
    
    func setUI(with string: String, date: String) {
        title.text = string
        dateLabel.text = date
    }
    
    func commonInit() {
        addSubview(title)
        addSubview(dateLabel) // Add the date label to the view
        
        title.translatesAutoresizingMaskIntoConstraints = false
        dateLabel.translatesAutoresizingMaskIntoConstraints = false // Set dateLabel's translatesAutoresizingMaskIntoConstraints to false
        
        title.topAnchor.constraint(equalTo: self.topAnchor, constant: 10).isActive = true
        title.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -10).isActive = true
        title.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 10).isActive = true
        title.trailingAnchor.constraint(equalTo: dateLabel.leadingAnchor, constant: -10).isActive = true
        
        dateLabel.topAnchor.constraint(equalTo: self.topAnchor, constant: 10).isActive = true
        dateLabel.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -10).isActive = true
        dateLabel.leadingAnchor.constraint(equalTo: title.trailingAnchor, constant: 10).isActive = true
        dateLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -10).isActive = true
        
        title.font = UIFont.boldSystemFont(ofSize: 16) // You can adjust the font size as needed

    }
}

final class CustomTableDetailView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private let title = UILabel()
    internal let detail = UILabel()
    private let dateLabel = UILabel() // Add a new UILabel for the date

    func setUI(with string: String, stringTwo: String) {
        title.text = "Detail View for Cell \(string)"
        detail.text = "Detail View for Cell \(stringTwo)"
    }
    
    func commonInit() {
                addSubview(title)
                addSubview(detail)
                addSubview(dateLabel)
                
                title.translatesAutoresizingMaskIntoConstraints = false
                detail.translatesAutoresizingMaskIntoConstraints = false
                dateLabel.translatesAutoresizingMaskIntoConstraints = false
                
                detail.topAnchor.constraint(equalTo: self.topAnchor, constant: 10).isActive = true
            detail.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -10).isActive = true
            detail.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 30).isActive = true
            detail.trailingAnchor.constraint(equalTo: title.leadingAnchor, constant: -10).isActive = true
                
            title.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 10).isActive = true
            title.trailingAnchor.constraint(equalTo: dateLabel.leadingAnchor, constant: -10).isActive = true

                
                dateLabel.topAnchor.constraint(equalTo: self.topAnchor, constant: 10).isActive = true
                dateLabel.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -10).isActive = true
                dateLabel.leadingAnchor.constraint(equalTo: title.trailingAnchor, constant: 10).isActive = true
                dateLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -10).isActive = true
            }
}
