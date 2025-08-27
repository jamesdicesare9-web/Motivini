import SwiftUI

struct FamilyPickerView: View {
    @EnvironmentObject var app: AppViewModel
    @State private var newFamilyName = ""

    var body: some View {
        VStack(spacing: 16) {
            Text("Choose a Family")
                .font(.title2).bold()

            if let acc = app.currentAccount {
                // Existing families
                List(acc.families, id: \.self) { summary in
                    Button(action: {
                        Task { await app.switchFamily(to: summary) }
                    }) {
                        HStack {
                            Text(summary.name)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .frame(maxHeight: 280)

                Divider()

                // Create a new family
                HStack {
                    TextField("New family name", text: $newFamilyName)
                        .textFieldStyle(.roundedBorder)

                    Button(action: {
                        Task { await addFamily() }
                    }) {
                        Text("Add")
                    }
                    .disabled(newFamilyName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            } else {
                Text("No account signed in")
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
    }

    private func addFamily() async {
        guard let acc = app.currentAccount else { return }
        let fam = await FamilyStore.shared.createFamily(name: newFamilyName, owner: acc)
        _ = try? await AuthService.shared.attachFamily(fam, to: acc)
        await app.switchFamily(to: FamilySummary(id: fam.id, name: fam.name))
        newFamilyName = ""
    }
}
