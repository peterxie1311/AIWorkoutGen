//
//  KeryboardAwareVC.swift
//  Workout
//
//  Created by Peter Xie on 23/1/2026.
//
import UIKit

class KeyboardAwareViewController: UIViewController {

    weak var activeField: UIView?
    weak var scrollView: UIScrollView?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupKeyboardObservers()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func register(scrollView: UIScrollView) {
        self.scrollView = scrollView
    }

    private func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }

    @objc private func keyboardWillShow(_ notification: Notification) {
        guard
            let scrollView = scrollView,
            let info = notification.userInfo,
            let frame = info[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect
        else { return }

        let height = frame.height - view.safeAreaInsets.bottom

        scrollView.contentInset.bottom = height + 12
        scrollView.verticalScrollIndicatorInsets.bottom = height + 12

        if let field = activeField {
            let rect = field.convert(field.bounds, to: scrollView)
            scrollView.scrollRectToVisible(rect.insetBy(dx: 0, dy: -16), animated: true)
        }
    }

    @objc private func keyboardWillHide(_ notification: Notification) {
        scrollView?.contentInset.bottom = 0
        scrollView?.verticalScrollIndicatorInsets.bottom = 0
    }
}
