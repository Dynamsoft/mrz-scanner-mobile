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
        return CGSize(width: size.width + textInsets.left + textInsets.right,
                      height: size.height + textInsets.top + textInsets.bottom)
    }
}

// MARK: - SegmentPickerView
class SegmentPickerView: UIView {

    private var options = ["ID", "Both", "Passport"]
    private var buttons: [UIButton] = []
    private let stackView = UIStackView()
    private let indicator = UIView()

    var onChanged: ((String) -> Void)?

    var isEnabled: Bool = true {
        didSet {
            guard isEnabled != oldValue else { return }
            isUserInteractionEnabled = isEnabled
            refreshButtons()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// The selected option always sits at index 1 (centre), so selecting rotates the strip.
    func setSelectedOption(_ target: String) {
        guard options.contains(target) else { return }
        while options[1] != target { options.append(options.removeFirst()) }
        refreshButtons()
    }

    private func setupUI() {
        indicator.backgroundColor = .white
        indicator.layer.cornerRadius = 1
        indicator.translatesAutoresizingMaskIntoConstraints = false
        addSubview(indicator)

        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.alignment = .center
        stackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stackView)

        NSLayoutConstraint.activate([
            indicator.topAnchor.constraint(equalTo: topAnchor, constant: 7),
            indicator.centerXAnchor.constraint(equalTo: centerXAnchor),
            indicator.widthAnchor.constraint(equalToConstant: 40),
            indicator.heightAnchor.constraint(equalToConstant: 2),

            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 24),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -24),
            stackView.centerYAnchor.constraint(equalTo: centerYAnchor),
            stackView.heightAnchor.constraint(equalToConstant: 32)
        ])

        // Built once and restyled thereafter; a tap rotates the titles, not the views.
        buttons = options.indices.map { index in
            let btn = UIButton(type: .system)
            btn.setTitleColor(.white, for: .normal)
            btn.tag = index
            btn.addTarget(self, action: #selector(handleTap(_:)), for: .touchUpInside)
            stackView.addArrangedSubview(btn)
            return btn
        }
        refreshButtons()
    }

    /// The only place a tab is styled; dimming runs through `alpha` alone so nothing multiplies.
    private func refreshButtons() {
        for (index, button) in buttons.enumerated() {
            let isSelected = (index == 1)
            button.setTitle(options[index], for: .normal)
            button.titleLabel?.font = isSelected ? .boldSystemFont(ofSize: 14) : .systemFont(ofSize: 14)
            button.alpha = isSelected ? 1.0 : (isEnabled ? 0.8 : 0.5)
        }
    }

    @objc private func handleTap(_ sender: UIButton) {
        guard sender.tag != 1 else { return }
        UIView.transition(with: stackView, duration: 0.25, options: .transitionCrossDissolve,
                          animations: {
            // Tapping the left option rotates the strip right, the right option rotates left.
            if sender.tag == 0 {
                self.options.insert(self.options.removeLast(), at: 0)
            } else {
                self.options.append(self.options.removeFirst())
            }
            self.refreshButtons()
        }, completion: { _ in
            self.onChanged?(self.options[1])
        })
    }
}
