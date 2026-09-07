enum Loadable<Value> {
    case idle
    case loading(previous: Value?)
    case loaded(Value)
    case empty
    case failed(AppError, previous: Value?)
}

extension Loadable: Equatable where Value: Equatable {}
extension Loadable: Sendable where Value: Sendable {}

extension Loadable {
    var value: Value? {
        switch self {
        case let .loading(previous), let .failed(_, previous):
            previous
        case let .loaded(value):
            value
        case .idle, .empty:
            nil
        }
    }

    var isLoading: Bool {
        if case .loading = self {
            true
        } else {
            false
        }
    }
}
