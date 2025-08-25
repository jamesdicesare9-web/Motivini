import SwiftUI
import SwiftData
import PhotosUI

struct RewardsView: View {
    @Environment(\.modelContext) private var context

    @Query(
        filter: #Predicate<Member> { $0.roleRaw == "child" },
        sort: [SortDescriptor(\Member.name)]
    ) private var children: [Member]

    @State private var selectedChildIdx = 0
    @State private var itemName = ""
    @State private var costText = ""
    @State private var photoItem: PhotosPickerItem?
    @State private var photoData: Data?

    var body: some View {
        NavigationStack {
            Form {
                Section("Child") {
                    Picker("Who", selection: $selectedChildIdx) {
                        ForEach(children.indices, id: \.self) { i in
                            Text("\(children[i].avatarEmoji) \(children[i].name) – \(children[i].points) pts")
                                .tag(i)
                        }
                    }
                }

                Section("Redeem") {
                    TextField("Item (e.g., Lego set)", text: $itemName)
                    TextField("Cost in points", text: $costText)
                        .keyboardType(.numberPad)

                    PhotosPicker(selection: $photoItem, matching: .images) {
                        Label("Add Photo", systemImage: "photo")
                    }

                    if let data = photoData, let ui = UIImage(data: data) {
                        Image(uiImage: ui)
                            .resizable().scaledToFit()
                            .frame(maxHeight: 160)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    Button("Redeem") { redeem() }
                        .disabled(!canRedeem)
                }

                Section("History") {
                    if children.indices.contains(selectedChildIdx) {
                        let m = children[selectedChildIdx]
                        ForEach(m.purchases.sorted { $0.date > $1.date }) { p in
                            HStack {
                                Image.fromPurchase(p)
                                    .resizable().scaledToFill()
                                    .frame(width: 44, height: 44)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                VStack(alignment: .leading) {
                                    Text(p.itemName).font(.headline)
                                    Text(p.date.formatted(date: .numeric, time: .omitted))
                                        .font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text("-\(p.pointsSpent) pts").foregroundStyle(.red)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Rewards")
            .onChange(of: photoItem) { _, new in
                Task {
                    if let data = try? await new?.loadTransferable(type: Data.self) {
                        photoData = data
                    }
                }
            }
        }
    }

    private var canRedeem: Bool {
        guard children.indices.contains(selectedChildIdx),
              let cost = Int(costText), cost > 0 else { return false }
        return children[selectedChildIdx].points >= cost && !itemName.isEmpty
    }

    private func redeem() {
        guard canRedeem else { return }
        let m = children[selectedChildIdx]
        let cost = Int(costText) ?? 0
        m.points -= cost
        let p = Purchase(itemName: itemName, pointsSpent: cost, photoData: photoData, member: m)
        context.insert(p)
        try? context.save()
        // reset
        itemName = ""; costText = ""; photoItem = nil; photoData = nil
    }
}
