//
//  RewardsView.swift
//  Motivini
//
//  Created by James Di Cesare on 2025-08-25.
//


import SwiftUI
import PhotosUI

struct RewardsView: View {
    @EnvironmentObject var app: AppModel
    @State private var title: String = ""
    @State private var points: String = ""
    @State private var selectedItem: PhotosPickerItem?
    @State private var pickedImage: UIImage?

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if let childId = app.selectedChildId, let child = app.members.first(where: {$0.id == childId}) {
                    GlassCard {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("\(child.name)’s Balance")
                                .font(.headline)
                            Text("$\(app.balance(for: childId))")
                                .font(.system(size: 36, weight: .black, design: .rounded))
                            Text("Redeem to purchase something and attach a photo to remember it.")
                                .font(.footnote).foregroundStyle(.secondary)
                        }
                    }

                    GlassCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Redeem Points").font(.headline)
                            TextField("What did you buy? (e.g., LEGO Minifigure)", text: $title)
                                .textFieldStyle(.roundedBorder)
                            TextField("Points to spend (e.g., 10)", text: $points)
                                .keyboardType(.numberPad)
                                .textFieldStyle(.roundedBorder)

                            PhotosPicker(selection: $selectedItem, matching: .images) {
                                Label(pickedImage == nil ? "Add Photo (optional)" : "Change Photo", systemImage: "photo")
                            }
                            .onChange(of: selectedItem) { _, newItem in
                                Task {
                                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                                       let ui = UIImage(data: data) {
                                        pickedImage = ui
                                    }
                                }
                            }

                            if let img = pickedImage {
                                Image(uiImage: img)
                                    .resizable().scaledToFit()
                                    .frame(height: 160)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                            }

                            Button {
                                guard let pts = Int(points), pts > 0 else { return }
                                app.redeem(childId: childId, title: title.isEmpty ? "Item" : title, points: pts, image: pickedImage)
                                title = ""; points = ""; pickedImage = nil; selectedItem = nil
                            } label: {
                                Label("Redeem", systemImage: "gift.fill")
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.purple)
                        }
                    }

                    GlassCard {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Redemption History")
                                .font(.headline)
                            let redemptions = app.redemptions(for: childId)
                            if redemptions.isEmpty {
                                Text("No redemptions yet.")
                                    .foregroundStyle(.secondary)
                            } else {
                                ForEach(redemptions) { r in
                                    HStack(alignment: .top, spacing: 12) {
                                        if let name = r.photoFilename {
                                            let url = DataStore.shared.imageURL(for: name)
                                            if let ui = UIImage(contentsOfFile: url.path) {
                                                Image(uiImage: ui)
                                                    .resizable().scaledToFill()
                                                    .frame(width: 56, height: 56)
                                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                            }
                                        } else {
                                            RoundedRectangle(cornerRadius: 10)
                                                .fill(.gray.opacity(0.15))
                                                .frame(width: 56, height: 56)
                                                .overlay(Image(systemName: "photo").foregroundStyle(.secondary))
                                        }
                                        VStack(alignment: .leading) {
                                            Text(r.title).font(.headline)
                                            Text("-\(r.pointsSpent) pts  •  " + r.date.formatted(date: .abbreviated, time: .shortened))
                                                .font(.caption).foregroundStyle(.secondary)
                                        }
                                        Spacer()
                                    }
                                    Divider().opacity(0.15)
                                }
                            }
                        }
                    }
                } else {
                    Text("Select a child in Settings.")
                        .padding()
                }
            }
            .padding(16)
        }
        .navigationTitle("Rewards")
    }
}
