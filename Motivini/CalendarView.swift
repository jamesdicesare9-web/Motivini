//
//  CalendarView.swift
//  Motivini
//
//  Created by James Di Cesare on 2025-08-26.
//


import SwiftUI

struct CalendarView: View {
@State private var monthAnchor = Date()
@State private var selectedDate: Date? = Date()

var body: some View {
VStack(spacing: 12) {
header
MonthGrid(anchor: $monthAnchor, selected: $selectedDate)
Divider()
ActivityLogForSelectedDate(selectedDate: selectedDate)
}
.padding()
}

private var header: some View {
HStack {
Button { monthAnchor = Calendar.current.date(byAdding: .month, value: -1, to: monthAnchor) ?? monthAnchor } label: { Image(systemName: "chevron.left") }
Spacer()
Text(monthAnchor, format: .dateTime.month(.wide).year()).font(.title2).bold()
Spacer()
Button { monthAnchor = Calendar.current.date(byAdding: .month, value: 1, to: monthAnchor) ?? monthAnchor } label: { Image(systemName: "chevron.right") }
}
}
}

struct ActivityLogForSelectedDate: View {
@EnvironmentObject var app: AppViewModel
let selectedDate: Date?

var body: some View {
VStack(alignment: .leading, spacing: 8) {
Text("Activity Log").font(.headline)
if let date = selectedDate, let fam = app.selectedFamily {
let entries = fam.activityLog.filter { Calendar.current.isDate($0.date, inSameDayAs: date) }
if entries.isEmpty { Text("No activity yet.").foregroundStyle(.secondary) }
else {
ForEach(entries) { e in
HStack {
if let member = fam.members.first(where: { $0.id == e.memberId }) { Text(member.avatar).font(.title3) }
VStack(alignment: .leading) {
Text(e.description)
Text(e.date, style: .time).font(.caption).foregroundStyle(.secondary)
}
Spacer()
}
.padding(8)
.background(Color(uiColor: .secondarySystemBackground))
.cornerRadius(10)
}
}
} else {
Text("Select a date to see entries.").foregroundStyle(.secondary)
}
}
}
}