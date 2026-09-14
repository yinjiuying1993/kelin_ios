import Foundation

enum MemoryCitationRules {
    static func visible(
        _ refs: [MessageSourceRef],
        hiddenMemoryIDs: Set<UUID>
    ) -> [MessageSourceRef] {
        refs.filter { reference in
            guard reference.kind == "memory", let memoryID = reference.memoryID else {
                return true
            }
            return !hiddenMemoryIDs.contains(memoryID)
        }
    }

    static func strippingHidden(
        from messages: [ChatMessage],
        hiddenMemoryIDs: Set<UUID>
    ) -> [ChatMessage] {
        messages.map { message in
            message.with(sourceRefs: visible(message.sourceRefs, hiddenMemoryIDs: hiddenMemoryIDs))
        }
    }
}
