import UIKit

final class HistoryChatViewController: UIViewController, UITableViewDataSource, UITextFieldDelegate {
    private let table = UITableView(frame: .zero, style: .plain)
    private let input = UITextField()
    private let send = UIButton(type: .system)
    private let status = UILabel()
    private var messages: [HistoryChatMessage] = []
    private var requestTask: Task<Void, Never>?

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Ask AI"
        navigationItem.largeTitleDisplayMode = .never
        view.backgroundColor = WorkoutTheme.background

        let introduction = WorkoutTheme.section(
            "Chat with your history",
            subtitle: "Try “How much protein did I log this week?” or “How has my bench press changed?” Relevant workout and food records are sent to OpenAI when you ask."
        )
        introduction.setContentCompressionResistancePriority(.required, for: .vertical)

        table.dataSource = self
        table.register(UITableViewCell.self, forCellReuseIdentifier: "Message")
        table.separatorStyle = .none
        table.backgroundColor = .clear
        table.keyboardDismissMode = .interactive
        table.rowHeight = UITableView.automaticDimension
        table.estimatedRowHeight = 100

        input.placeholder = "Ask about training or food"
        input.accessibilityLabel = "Chat message"
        input.font = .preferredFont(forTextStyle: .body)
        input.adjustsFontForContentSizeCategory = true
        input.borderStyle = .roundedRect
        input.returnKeyType = .send
        input.delegate = self
        input.addTarget(self, action: #selector(updateSendState), for: .editingChanged)
        input.setContentHuggingPriority(.defaultLow, for: .horizontal)

        var button = UIButton.Configuration.filled()
        button.image = UIImage(systemName: "arrow.up")
        button.baseBackgroundColor = WorkoutTheme.accent
        button.baseForegroundColor = WorkoutTheme.onAccent
        button.cornerStyle = .medium
        send.configuration = button
        send.accessibilityLabel = "Send message"
        send.addTarget(self, action: #selector(sendMessage), for: .touchUpInside)

        status.font = .preferredFont(forTextStyle: .footnote)
        status.adjustsFontForContentSizeCategory = true
        status.textColor = .secondaryLabel
        status.numberOfLines = 0
        status.isHidden = true

        let composer = UIStackView(arrangedSubviews: [input, send])
        composer.spacing = 8
        let stack = UIStackView(arrangedSubviews: [introduction, table, status, composer])
        stack.axis = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            stack.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor, constant: -10),
            composer.heightAnchor.constraint(greaterThanOrEqualToConstant: 44),
            send.widthAnchor.constraint(greaterThanOrEqualToConstant: 44)
        ])
        updateSendState()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if isMovingFromParent || navigationController?.isBeingDismissed == true {
            requestTask?.cancel()
        }
    }

    @objc private func updateSendState() {
        send.isEnabled = requestTask == nil && !draft.isEmpty
    }

    private var draft: String {
        (input.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    @objc private func sendMessage() {
        let question = draft
        guard requestTask == nil, !question.isEmpty else { return }
        guard question.count <= 2_000 else {
            showStatus("Keep your question under 2,000 characters.")
            return
        }
        input.text = nil
        input.resignFirstResponder()
        messages.append(HistoryChatMessage(role: .user, text: question))
        refreshMessages()
        showStatus("Looking up your history…")
        send.configuration?.showsActivityIndicator = true
        let conversation = messages
        requestTask = Task { @MainActor [weak self] in
            do {
                let answer = try await workoutAIservice.shared.chatAboutHistory(conversation)
                try Task.checkCancellation()
                self?.messages.append(HistoryChatMessage(role: .assistant, text: answer))
                self?.showStatus(nil)
                UIAccessibility.post(notification: .announcement, argument: "AI reply received.")
            } catch {
                self?.messages.removeLast()
                if self?.draft.isEmpty == true { self?.input.text = question }
                let hasServerMessage = (error as? APIResponseError)?.serverMessage != nil
                self?.showStatus(Task.isCancelled || hasServerMessage ? nil : error.localizedDescription)
            }
            self?.requestTask = nil
            self?.send.configuration?.showsActivityIndicator = false
            self?.refreshMessages()
            self?.updateSendState()
        }
        updateSendState()
    }

    private func showStatus(_ text: String?) {
        status.text = text
        status.isHidden = text == nil
    }

    private func refreshMessages() {
        table.reloadData()
        if !messages.isEmpty {
            table.scrollToRow(at: IndexPath(row: messages.count - 1, section: 0), at: .bottom, animated: true)
        }
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        sendMessage()
        return false
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        messages.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let message = messages[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "Message", for: indexPath)
        var content = cell.defaultContentConfiguration()
        content.text = message.role == .user ? "You" : "AI"
        content.textProperties.font = .preferredFont(forTextStyle: .headline)
        content.textProperties.color = WorkoutTheme.accent
        content.secondaryText = message.text
        content.secondaryTextProperties.font = .preferredFont(forTextStyle: .body)
        content.secondaryTextProperties.numberOfLines = 0
        cell.contentConfiguration = content
        cell.selectionStyle = .none
        cell.backgroundColor = .clear
        return cell
    }
}
