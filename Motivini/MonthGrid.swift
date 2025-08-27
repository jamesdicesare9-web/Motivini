//
//  MonthGrid.swift
//  Motivini
//
//  Created by James Di Cesare on 2025-08-26.
//


import SwiftUI

struct MonthGrid: View {
@Binding var anchor: Date
@Binding var selected: Date?

private var days: [Date] {
let cal = Calendar.current
guard let interval = cal.dateInterval(of: .month, for: anchor) else { return [] }
var start = interval.start
let weekday = cal.component(.weekday, from: start)
start = cal.date(byAdding: .day, value: -(weekday - cal.firstWeekday), to: start) ?? start
return (0..<42).compactMap { cal.date(byAdding: .day, value: $0, to: start) }
}

var body: some View {
let cal = Calendar.current
let month = cal.component(.month, from: anchor)

LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
ForEach(["S","M","T","W","T","F","S"], id: \.self) {
Text($0).font(.caption).foregroundStyle(.secondary)
}
ForEach(days, id: \.self) { day in
let isThisMonth = cal.component(.month, from: day) == month
let isSelected = selected.map { cal.isDate($0, inSameDayAs: day) } ?? false
Button { selected = day } label: {
Text("\(cal.component(.day, from: day))")
.fontWeight(isSelected ? .bold : .regular)
.frame(maxWidth: .infinity, minHeight: 40)
.background(isSelected ? Color.accentColor.opacity(0.2) : .clear)
.clipShape(RoundedRectangle(cornerRadius: 8))
}
.disabled(!isThisMonth)
.foregroundStyle(isThisMonth ? .primary : .secondary)
}
}
}
}