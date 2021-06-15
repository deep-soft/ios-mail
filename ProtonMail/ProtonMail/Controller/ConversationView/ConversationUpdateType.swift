enum ConversationUpdateType {
    case willUpdate
    case didUpdate
    case insert(message: Message, row: Int)
    case update(message: Message, row: Int)
    case move(fromRow: Int, toRow: Int)
    case delete(message: Message)
}
