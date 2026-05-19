//
//  MedicationsView.swift
//  146MedRemind
//

import SwiftUI

private enum MedicationEditorRoute: Identifiable {
    case add
    case edit(Medication)

    var id: String {
        switch self {
        case .add:
            return "add"
        case .edit(let m):
            return "edit-\(m.id.uuidString)"
        }
    }
}

struct MedicationsView: View {
    @ObservedObject var viewModel: MedRemindViewModel
    @State private var selectedMedication: Medication?
    @State private var editorRoute: MedicationEditorRoute?

    private var activeCount: Int {
        viewModel.medications.filter { $0.isActive && !$0.isArchived }.count
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                MedScreenBackdrop(style: .medications)
                    .ignoresSafeArea()

                VStack(alignment: .leading, spacing: 0) {
                    medicationsHeader

                    if viewModel.medications.isEmpty {
                        medicationsEmptyState
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        List {
                            Section {
                                ForEach(viewModel.activeMedications) { medication in
                                    MedicationCard(
                                        medication: medication,
                                        takenTodayCount: viewModel.takenToday(for: medication.id),
                                        nextDoseDate: viewModel.nextDose(for: medication.id)
                                    )
                                    .listRowInsets(EdgeInsets(top: 10, leading: 18, bottom: 10, trailing: 18))
                                    .listRowSeparator(.hidden)
                                    .listRowBackground(Color.clear)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        selectedMedication = medication
                                    }
                                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                        Button {
                                            editorRoute = .edit(medication)
                                        } label: {
                                            Label("Edit", systemImage: "pencil")
                                        }
                                        .tint(.medPending)

                                        Button {
                                            viewModel.archiveMedication(medication)
                                        } label: {
                                            Label("Archive", systemImage: "archivebox")
                                        }
                                        .tint(.orange)

                                        Button {
                                            viewModel.toggleActive(medication)
                                        } label: {
                                            Label(medication.isActive ? "Deactivate" : "Activate", systemImage: "power")
                                        }
                                        .tint(.medPending)

                                        Button(role: .destructive) {
                                            viewModel.deleteMedication(medication)
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                                }
                            }

                            if !viewModel.archivedMedications.isEmpty {
                                Section {
                                    ForEach(viewModel.archivedMedications) { medication in
                                        MedicationCard(
                                            medication: medication,
                                            takenTodayCount: viewModel.takenToday(for: medication.id),
                                            nextDoseDate: viewModel.nextDose(for: medication.id)
                                        )
                                        .listRowInsets(EdgeInsets(top: 10, leading: 18, bottom: 10, trailing: 18))
                                        .listRowSeparator(.hidden)
                                        .listRowBackground(Color.clear)
                                        .contentShape(Rectangle())
                                        .onTapGesture {
                                            selectedMedication = medication
                                        }
                                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                            Button {
                                                viewModel.unarchiveMedication(medication)
                                            } label: {
                                                Label("Restore", systemImage: "arrow.uturn.backward")
                                            }
                                            .tint(.medTaken)

                                            Button(role: .destructive) {
                                                viewModel.deleteMedication(medication)
                                            } label: {
                                                Label("Delete", systemImage: "trash")
                                            }
                                        }
                                    }
                                } header: {
                                    Text("Archived")
                                        .foregroundColor(.medSecondaryLabel)
                                        .font(.subheadline.weight(.semibold))
                                }
                            }
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                        .scrollIndicators(.hidden)
                    }
                }

                addMedicationFAB
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
            .sheet(item: $selectedMedication) { med in
                MedicationDetailSheet(
                    medication: med,
                    viewModel: viewModel,
                    onDismiss: { selectedMedication = nil },
                    onEdit: {
                        selectedMedication = nil
                        DispatchQueue.main.async {
                            editorRoute = .edit(med)
                        }
                    }
                )
            }
            .sheet(item: $editorRoute) { route in
                switch route {
                case .add:
                    AddMedicationView(viewModel: viewModel)
                case .edit(let medication):
                    AddMedicationView(viewModel: viewModel, medicationToEdit: medication)
                }
            }
        }
    }

    private var medicationsHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("My medications")
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.white, Color.medPending.opacity(0.95)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )

            Text("Manage doses and refill reminders")
                .font(.subheadline)
                .foregroundColor(.medTertiaryLabel)

            HStack(spacing: 10) {
                headerPill(
                    title: "Active",
                    value: "\(activeCount)",
                    icon: "bolt.fill",
                    tint: Color.medTaken
                )
                headerPill(
                    title: "Total",
                    value: "\(viewModel.medications.count)",
                    icon: "pills.fill",
                    tint: Color.medPending
                )
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 8)
    }

    private func headerPill(title: String, value: String, icon: String, tint: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption.weight(.semibold))
                .foregroundColor(tint)
            VStack(alignment: .leading, spacing: 1) {
                Text(title.uppercased())
                    .font(.caption2.weight(.semibold))
                    .foregroundColor(.medTertiaryLabel)
                Text(value)
                    .font(.subheadline.weight(.bold).monospacedDigit())
                    .foregroundColor(.white)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(tint.opacity(0.35), lineWidth: 1)
                )
        )
        .shadow(color: Color.black.opacity(0.35), radius: 10, x: 0, y: 5)
        .shadow(color: tint.opacity(0.2), radius: 12, x: 0, y: 4)
    }

    private var medicationsEmptyState: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Color.medPending.opacity(0.15))
                    .frame(width: 100, height: 100)
                Image(systemName: "pills.circle")
                    .font(.system(size: 44))
                    .foregroundStyle(
                        LinearGradient(colors: [.medPending, .medPending.opacity(0.6)], startPoint: .top, endPoint: .bottom)
                    )
            }
            Text("No medications yet")
                .font(.title3.weight(.semibold))
                .foregroundColor(.white)
            Text("Tap + to add your first entry.")
                .font(.subheadline)
                .foregroundColor(.medSecondaryLabel)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .padding(.bottom, 80)
    }

    private var addMedicationFAB: some View {
        Button {
            editorRoute = .add
        } label: {
            Image(systemName: "plus")
                .font(.title2.weight(.bold))
                .foregroundColor(.white)
                .frame(width: 58, height: 58)
                .background(
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.medPending, Color.medPending.opacity(0.75)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.25), lineWidth: 1)
                )
                .medFloatingButtonShadow(accent: .medPending)
        }
        .padding(24)
        .accessibilityLabel("Add medication")
    }
}

private struct MedicationDetailSheet: View {
    let medication: Medication
    @ObservedObject var viewModel: MedRemindViewModel
    var onDismiss: () -> Void
    var onEdit: () -> Void

    @State private var showLogRefill = false
    @State private var refillAmount = 30
    @State private var refillNotesDraft = ""

    private var liveMedication: Medication {
        viewModel.medications.first(where: { $0.id == medication.id }) ?? medication
    }

    private var schedule: Schedule? {
        viewModel.schedules.first { $0.medicationId == medication.id }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                MedScreenBackdrop(style: .sheet)
                    .ignoresSafeArea()

                ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    MedicationCard(
                        medication: liveMedication,
                        takenTodayCount: viewModel.takenToday(for: medication.id),
                        nextDoseDate: viewModel.nextDose(for: medication.id)
                    )

                    if let stock = liveMedication.stockCount {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Inventory")
                                .font(.headline)
                                .foregroundColor(.medPending)
                            HStack {
                                Text("Tablets on hand")
                                    .foregroundColor(.white.opacity(0.8))
                                Spacer()
                                Text("\(stock)")
                                    .font(.title3.weight(.bold))
                                    .foregroundColor(.medTaken)
                            }
                            Text("Alert at or below: \(liveMedication.lowStockThreshold)")
                                .font(.caption)
                                .foregroundColor(.medSecondaryLabel)
                            Button {
                                refillAmount = 30
                                refillNotesDraft = ""
                                showLogRefill = true
                            } label: {
                                Label("Log refill", systemImage: "plus.circle.fill")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.medPending)
                            .foregroundColor(Color.medBackground)
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .medElevatedCard(cornerRadius: 16, accent: .medPending, intensity: 0.92)
                    }

                    if !viewModel.refillsSorted(for: medication.id).isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Refill history")
                                .font(.headline)
                                .foregroundColor(.medPending)
                            ForEach(viewModel.refillsSorted(for: medication.id).prefix(8)) { refill in
                                HStack {
                                    Text(formattedShortDate(refill.date))
                                        .foregroundColor(.medSecondaryLabel)
                                        .font(.caption)
                                    Text("+\(refill.quantity)")
                                        .foregroundColor(.medTaken)
                                        .font(.subheadline.weight(.semibold))
                                    Spacer()
                                }
                                .padding(.vertical, 4)
                            }
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .medElevatedCard(cornerRadius: 16, accent: .medTaken, intensity: 0.88)
                    }

                    if !liveMedication.isArchived {
                        Button(role: .destructive) {
                            viewModel.archiveMedication(liveMedication)
                            onDismiss()
                        } label: {
                            Text("End course & archive")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                    } else {
                        Button {
                            viewModel.unarchiveMedication(liveMedication)
                            onDismiss()
                        } label: {
                            Text("Restore to list")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.medTaken)
                        .foregroundColor(.medBackground)
                    }

                    if let instructions = liveMedication.instructions, !instructions.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Instructions")
                                .font(.headline)
                                .foregroundColor(.medPending)
                            Text(instructions)
                                .foregroundColor(.white)
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .medElevatedCard(cornerRadius: 16, accent: .medPending, intensity: 0.88)
                    }

                    if let notes = liveMedication.notes, !notes.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Notes")
                                .font(.headline)
                                .foregroundColor(.medPending)
                            Text(notes)
                                .foregroundColor(.white)
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .medElevatedCard(cornerRadius: 16, accent: .medPending, intensity: 0.88)
                    }

                    if let sch = schedule {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Schedule")
                                .font(.headline)
                                .foregroundColor(.medPending)
                            Text("Frequency: \(sch.frequency.rawValue)")
                                .foregroundColor(.white)
                            Text("Times: \(sch.times.map { formattedTime($0) }.joined(separator: ", "))")
                                .foregroundColor(.medSecondaryLabel)
                                .font(.caption)
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .medElevatedCard(cornerRadius: 16, accent: .medPending, intensity: 0.88)
                    }
                }
                .padding()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle("Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        onDismiss()
                    }
                    .foregroundColor(.medPending)
                }
                ToolbarItem(placement: .confirmationAction) {
                    if !liveMedication.isArchived {
                        Button("Edit") {
                            onEdit()
                        }
                        .fontWeight(.semibold)
                        .foregroundColor(.medPending)
                    }
                }
            }
            .sheet(isPresented: $showLogRefill) {
                NavigationStack {
                    Form {
                        Section("Amount") {
                            Stepper("Tablets: \(refillAmount)", value: $refillAmount, in: 1...999)
                        }
                        Section("Notes (optional)") {
                            TextField("Pharmacy, batch…", text: $refillNotesDraft)
                        }
                    }
                    .navigationTitle("Log refill")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") { showLogRefill = false }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Save") {
                                let notes = refillNotesDraft.trimmingCharacters(in: .whitespacesAndNewlines)
                                viewModel.logRefill(
                                    medicationId: medication.id,
                                    quantity: refillAmount,
                                    notes: notes.isEmpty ? nil : notes
                                )
                                showLogRefill = false
                            }
                        }
                    }
                }
                .presentationDetents([.medium])
            }
        }
        .presentationDetents([.medium, .large])
    }
}
