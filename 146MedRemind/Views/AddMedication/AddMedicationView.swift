//
//  AddMedicationView.swift
//  146MedRemind
//

import SwiftUI

struct AddMedicationView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: MedRemindViewModel
    /// When set, the form loads this medication and saving calls `updateMedication`.
    var medicationToEdit: Medication? = nil

    @State private var didHydrateEditForm = false
    @State private var medicationName = ""
    @State private var dosage: Double = 1
    @State private var unit: DosageUnit = .mg
    @State private var instructions = ""
    @State private var frequency: FrequencyType = .daily
    @State private var selectedDays: Set<DayOfWeek> = []
    @State private var times: [Date] = []
    @State private var startDate = Date()
    @State private var hasEndDate = false
    @State private var endDate = Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date()
    @State private var refillQuantity = 30
    @State private var trackInventory = true
    @State private var lowStockThreshold = 7
    @State private var refillReminder = false
    @State private var notes = ""
    @State private var showTimePicker = false
    @State private var timeDraft = Date()

    var body: some View {
        NavigationStack {
            ZStack {
                MedScreenBackdrop(style: .sheet)
                    .ignoresSafeArea()

                ScrollView {
                VStack(spacing: 22) {
                    MedFormSection(title: "Medication") {
                        TextField("Name", text: $medicationName)
                            .foregroundColor(.white)
                            .tint(.medPending)

                        HStack {
                            TextField("Dosage", value: $dosage, format: .number)
                                .keyboardType(.decimalPad)
                                .foregroundColor(.white)
                                .tint(.medPending)

                            Picker("", selection: $unit) {
                                ForEach(DosageUnit.allCases, id: \.self) { u in
                                    Text(u.rawValue).tag(u)
                                }
                            }
                            .pickerStyle(.menu)
                            .frame(width: 88)
                            .tint(.medPending)
                        }

                        TextField("Instructions (optional)", text: $instructions)
                            .foregroundColor(.white)
                            .tint(.medPending)
                    }

                    MedFormSection(title: "Schedule") {
                        Picker("Frequency", selection: $frequency) {
                            ForEach(FrequencyType.allCases, id: \.self) { freq in
                                Text(freq.rawValue).tag(freq)
                            }
                        }
                        .tint(.medPending)

                        if frequency == .weekly {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(DayOfWeek.allCases, id: \.self) { day in
                                        DayChip(day: day, isSelected: selectedDays.contains(day))
                                            .onTapGesture {
                                                if selectedDays.contains(day) {
                                                    selectedDays.remove(day)
                                                } else {
                                                    selectedDays.insert(day)
                                                }
                                            }
                                    }
                                }
                            }
                        }

                        HStack {
                            Text("Dose times")
                                .foregroundColor(.white)
                            Spacer()
                            Button("Add time") {
                                timeDraft = Date()
                                showTimePicker = true
                            }
                            .foregroundColor(.medPending)
                        }

                        ForEach(times.indices, id: \.self) { index in
                            HStack {
                                Text(formattedTime(times[index]))
                                    .foregroundColor(.white)

                                Spacer()

                                Button {
                                    times.remove(at: index)
                                } label: {
                                    Image(systemName: "trash")
                                        .foregroundColor(.red)
                                }
                            }
                        }

                        DatePicker("Start date", selection: $startDate, displayedComponents: .date)
                            .tint(.medPending)
                            .foregroundColor(.white)

                        Toggle("End date", isOn: $hasEndDate)
                            .tint(.medPending)

                        if hasEndDate {
                            DatePicker("End on", selection: $endDate, displayedComponents: .date)
                                .tint(.medPending)
                                .foregroundColor(.white)
                        }
                    }

                    MedFormSection(title: "Supply") {
                        Toggle("Track tablets on hand", isOn: $trackInventory)
                            .tint(.medPending)

                        if trackInventory {
                            HStack {
                                Text("Quantity on hand")
                                    .foregroundColor(.white)
                                Spacer()
                                Stepper("\(refillQuantity)", value: $refillQuantity, in: 0...999)
                                    .foregroundColor(.medPending)
                            }

                            HStack {
                                Text("Low stock alert at")
                                    .foregroundColor(.white)
                                Spacer()
                                Stepper("\(lowStockThreshold)", value: $lowStockThreshold, in: 1...max(1, refillQuantity))
                                    .foregroundColor(.medPending)
                            }
                        }

                        Toggle("Refill reminder", isOn: $refillReminder)
                            .tint(.medPending)
                    }

                    MedFormSection(title: "Notes") {
                        TextEditor(text: $notes)
                            .frame(height: 88)
                            .foregroundColor(.white)
                            .tint(.medPending)
                            .scrollContentBackground(.hidden)
                            .background(Color.medPending.opacity(0.08))
                            .cornerRadius(8)
                    }
                }
                .padding()
                .padding(.bottom, 24)
                }
            }
            .foregroundColor(.white)
            .navigationTitle(medicationToEdit == nil ? "New medication" : "Edit medication")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.medBackground, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .onAppear {
                hydrateFromMedicationIfEditing()
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.medPending)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(medicationToEdit == nil ? "Save" : "Update") {
                        save()
                    }
                    .fontWeight(.semibold)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.medPending)
                    .foregroundColor(Color.medBackground)
                    .cornerRadius(8)
                }
            }
            .sheet(isPresented: $showTimePicker) {
                NavigationStack {
                    ZStack {
                        MedScreenBackdrop(style: .sheet)
                            .ignoresSafeArea()
                        DatePicker("", selection: $timeDraft, displayedComponents: .hourAndMinute)
                            .datePickerStyle(.wheel)
                            .labelsHidden()
                            .padding()
                            .colorScheme(.dark)
                            .tint(.medPending)
                    }
                    .navigationTitle("Time")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbarBackground(Color.medBackground, for: .navigationBar)
                    .toolbarColorScheme(.dark, for: .navigationBar)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") { showTimePicker = false }
                                .foregroundColor(.medPending)
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Add") {
                                times.append(timeDraft)
                                showTimePicker = false
                            }
                            .fontWeight(.semibold)
                            .foregroundColor(.medPending)
                        }
                    }
                }
                .presentationDetents([.medium])
            }
        }
        .id(medicationToEdit?.id.uuidString ?? "new-medication")
    }

    private func hydrateFromMedicationIfEditing() {
        guard !didHydrateEditForm, let med = medicationToEdit else { return }
        didHydrateEditForm = true

        medicationName = med.name
        dosage = med.dosage
        unit = med.unit
        instructions = med.instructions ?? ""
        notes = med.notes ?? ""
        refillReminder = med.refillReminder
        if let stock = med.stockCount {
            trackInventory = true
            refillQuantity = stock
            lowStockThreshold = min(max(1, med.lowStockThreshold), max(1, stock))
        } else {
            trackInventory = false
            refillQuantity = estimatedRefillQuantity(from: med)
            lowStockThreshold = max(1, med.lowStockThreshold)
        }

        guard let sch = viewModel.schedules.first(where: { $0.medicationId == med.id }) else {
            startDate = Date()
            hasEndDate = false
            endDate = Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date()
            frequency = .daily
            selectedDays = []
            times = []
            return
        }

        frequency = sch.frequency
        selectedDays = Set(sch.daysOfWeek ?? [])
        times = sch.times
        startDate = sch.startDate
        if let ed = sch.endDate {
            hasEndDate = true
            endDate = ed
        } else {
            hasEndDate = false
            endDate = Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date()
        }
    }

    private func estimatedRefillQuantity(from med: Medication) -> Int {
        guard let rd = med.refillDate else { return 0 }
        let cal = Calendar.current
        let start = cal.startOfDay(for: Date())
        let end = cal.startOfDay(for: rd)
        guard let days = cal.dateComponents([.day], from: start, to: end).day else { return 0 }
        if days < 0 { return 0 }
        return min(999, days)
    }

    private func save() {
        let name = medicationName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty, !times.isEmpty else { return }
        if frequency == .weekly && selectedDays.isEmpty { return }

        let days: [DayOfWeek]? = frequency == .weekly ? Array(selectedDays).sorted { $0.rawValue < $1.rawValue } : nil
        let end: Date? = hasEndDate ? endDate : nil

        if let existing = medicationToEdit {
            viewModel.updateMedication(
                id: existing.id,
                name: name,
                dosage: dosage,
                unit: unit,
                instructions: instructions.isEmpty ? nil : instructions,
                times: times,
                frequency: frequency,
                daysOfWeek: days,
                startDate: startDate,
                endDate: end,
                trackInventory: trackInventory,
                stockCount: refillQuantity,
                lowStockThreshold: lowStockThreshold,
                refillReminder: refillReminder,
                notes: notes.isEmpty ? nil : notes
            )
        } else {
            viewModel.addMedication(
                name: name,
                dosage: dosage,
                unit: unit,
                instructions: instructions.isEmpty ? nil : instructions,
                times: times,
                frequency: frequency,
                daysOfWeek: days,
                startDate: startDate,
                endDate: end,
                trackInventory: trackInventory,
                stockCount: refillQuantity,
                lowStockThreshold: lowStockThreshold,
                refillReminder: refillReminder,
                notes: notes.isEmpty ? nil : notes
            )
        }
        dismiss()
    }
}

// MARK: - Dark section card (replaces Form / UITableView white grouping)

private struct MedFormSection<Content: View>: View {
    let title: String
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.medPending)

            VStack(alignment: .leading, spacing: 14) {
                content()
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .medElevatedCard(cornerRadius: 16, accent: .medPending, intensity: 0.92)
        }
    }
}
