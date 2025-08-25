import SwiftUI

/// Wrap parent-only screens in ParentGate { ... }
struct ParentGate<Content: View>: View {
    @AppStorage("isParentUnlocked") private var isUnlocked = false
    @AppStorage("parentPIN") private var pin: String = "1234"
    @State private var entry: String = ""
    @State private var error: String?

    let content: () -> Content

    var body: some View {
        Group {
            if isUnlocked {
                content()
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button {
                                isUnlocked = false
                            } label: { Label("Lock", systemImage: "lock.fill") }
                        }
                    }
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "lock.fill").font(.largeTitle)
                    Text("Parent PIN Required").font(.title2).bold()

                    SecureField("Enter 4-digit PIN", text: $entry)
                        .textContentType(.oneTimeCode)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 160)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))

                    if let error { Text(error).foregroundStyle(.red).font(.footnote) }

                    Button {
                        if entry == pin {
                            isUnlocked = true
                            entry = ""; error = nil
                            Haptics.success()
                        } else {
                            error = "Incorrect PIN"
                            Haptics.error()
                        }
                    } label: { Label("Unlock", systemImage: "key.fill") }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
                .navigationTitle("Locked")
            }
        }
    }
}
