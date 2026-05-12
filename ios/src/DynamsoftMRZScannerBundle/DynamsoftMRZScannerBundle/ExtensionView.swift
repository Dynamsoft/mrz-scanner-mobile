//
//  ExtensionView.swift
//  DynamsoftMRZScannerBundle
//
//  Copyright © Dynamsoft Corporation.  All rights reserved.
//

import UIKit

class PaddingLabel: UILabel {

    var textInsets: UIEdgeInsets = .zero {
        didSet {
            invalidateIntrinsicContentSize()
            setNeedsDisplay()
        }
    }

    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: textInsets))
    }

    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(
            width: size.width + textInsets.left + textInsets.right,
            height: size.height + textInsets.top + textInsets.bottom
        )
    }
}

// MARK: - SegmentPickerView
class SegmentPickerView: UIView {
    
    private var options = ["ID", "Both", "Passport"]
    
    var onChanged: ((String) -> Void)?
    
    private let stackView = UIStackView()
    private let indicator = UIView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setSelectedOption(_ target: String) {
        guard options.contains(target) else { return }
        
        while options[1] != target {
            let first = options.removeFirst()
            options.append(first)
        }
        refreshButtons()
    }
    
    private func setupUI() {
        
        indicator.backgroundColor = .white
        indicator.layer.cornerRadius = 1
        addSubview(indicator)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.alignment = .center
        addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            indicator.topAnchor.constraint(equalTo: self.topAnchor, constant: 7),
            indicator.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            indicator.widthAnchor.constraint(equalToConstant: 40),
            indicator.heightAnchor.constraint(equalToConstant: 2),
            
            stackView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 24),
            stackView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -24),
            stackView.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            stackView.heightAnchor.constraint(equalToConstant: 32)
        ])
        
        refreshButtons()
    }
    
    private func refreshButtons() {
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        for (index, title) in options.enumerated() {
            let btn = UIButton(type: .system)
            btn.setTitle(title, for: .normal)
            
            if index == 1 {
                btn.setTitleColor(.white, for: .normal)
                btn.titleLabel?.font = .boldSystemFont(ofSize: 14)
            } else {
                btn.setTitleColor(.white.withAlphaComponent(0.8), for: .normal)
                btn.titleLabel?.font = .systemFont(ofSize: 14)
            }
            
            btn.tag = index
            btn.addTarget(self, action: #selector(handleTap(_:)), for: .touchUpInside)
            stackView.addArrangedSubview(btn)
        }
    }
    
    @objc private func handleTap(_ sender: UIButton) {
        let tappedIndex = sender.tag
        
        if tappedIndex == 1 { return }
        
        UIView.transition(with: self.stackView, duration: 0.25, options: .transitionCrossDissolve, animations: {
            if tappedIndex == 0 {
                let last = self.options.removeLast()
                self.options.insert(last, at: 0)
            } else {
                let first = self.options.removeFirst()
                self.options.append(first)
            }
            self.refreshButtons()
        }) { _ in
            self.onChanged?(self.options[1])
        }
    }
    
    var isEnabled: Bool = true {
        didSet {
            self.isUserInteractionEnabled = isEnabled
            
            let targetAlpha: CGFloat = isEnabled ? 0.8 : 0.5
            
            stackView.arrangedSubviews.forEach { button in
                if button.tag != 1 {
                    button.alpha = targetAlpha
                }
            }
        }
    }
}

