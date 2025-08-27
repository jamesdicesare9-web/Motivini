import SwiftUI

struct FamilyContextKey: EnvironmentKey {
    static let defaultValue: Binding<Family?> = .constant(nil)
}

extension EnvironmentValues {
    var familyBinding: Binding<Family?> {
        get { self[FamilyContextKey.self] }
        set { self[FamilyContextKey.self] = newValue }
    }
}
