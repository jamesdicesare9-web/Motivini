//
//  SeriesListView.swift
//  Motivini
//
//  Created by James Di Cesare on 2025-08-25.
//


import SwiftUI
import SwiftData

struct SeriesListView: View {
    @Environment(\.modelContext) private var context

    @Query(
        filter: #Predicate<Member> { $0.roleRaw == "child" },
        sort: [SortDescriptor(\Member.name)]
    ) private var children: [Member]

    @Query(sort: [SortDescriptor(\Category.name)])
    private var categories: [Category]

    @State private var selectedChildIdx = 0

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 12) {
                Picker("Child", selection: $selectedChildIdx) {
                    ForEach(children.indices, id: \.self) { i in
                        Text("\(children[i].avatarEmoji) \(children[i].name)").tag(i)
                    }
                }
                .pickerStyle(.segmented)

                List {
                    ForEach(categories) { cat in
                        HStack {
                            Text("\(cat.icon) \(cat.name)")
                            Spacer()
                            Button {
                                log(for: cat)
                            } label: {
                                Label("Log", systemImage: "plus.circle.fill")
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                }
            }
            .padding(.horizontal)
            .navigationTitle("Log Activity")
        }
    }

    private func log(for category: Category) {
        guard children.indices.contains(selectedChildIdx) else { return }
        let child = children[selectedChildIdx]
        let entry = Completion(member: child, category: category)
        context.insert(entry)
        try? context.save()
    }
}
