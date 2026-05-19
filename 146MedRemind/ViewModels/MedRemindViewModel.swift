//
//  MedRemindViewModel.swift
//  146MedRemind
//

import Combine
import Foundation
import UserNotifications

@MainActor
final class MedRemindViewModel: ObservableObject {
    @Published var medications: [Medication] = []
    @Published var schedules: [Schedule] = []
    @Published var doses: [Dose] = []
    @Published var refills: [Refill] = []
    @Published var selectedDate = Date()

    private func medication(for id: UUID) -> Medication? {
        medications.first { $0.id == id }
    }

    private func isArchived(_ medicationId: UUID) -> Bool {
        medication(for: medicationId)?.isArchived == true
    }

    var todayDoses: [Dose] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        return doses.filter { dose in
            guard dose.scheduledTime >= today && dose.scheduledTime < tomorrow else { return false }
            return !isArchived(dose.medicationId)
        }
        .sorted { $0.scheduledTime < $1.scheduledTime }
    }

    var todayTotal: Int { todayDoses.count }
    var todayTaken: Int { todayDoses.filter { $0.status == .taken }.count }
    var todayPending: Int { todayDoses.filter { $0.status == .pending }.count }
    var todayMissed: Int { todayDoses.filter { $0.status == .missed }.count }
    var todayProgress: Double { todayTotal > 0 ? Double(todayTaken) / Double(todayTotal) : 0 }

    var totalDoses: Int { doses.count }
    var totalTaken: Int { doses.filter { $0.status == .taken }.count }
    var totalMissed: Int { doses.filter { $0.status == .missed }.count }
    var totalSkipped: Int { doses.filter { $0.isSkipped }.count }

    var adherenceRate: Double {
        let taken = Double(totalTaken)
        let total = Double(totalDoses - totalSkipped)
        return total > 0 ? (taken / total) * 100 : 0
    }

    /// Last 7 days including today: label + adherence percent for chart.
    struct WeeklyDayStat: Identifiable {
        let id: String
        let weekdayShort: String
        let adherencePercent: Double
        let taken: Int
        let scheduled: Int
    }

    var weeklyDayStats: [WeeklyDayStat] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US")
        df.dateFormat = "EEE"
        return (0..<7).compactMap { offset -> WeeklyDayStat? in
            guard let day = cal.date(byAdding: .day, value: -6 + offset, to: today) else { return nil }
            let start = cal.startOfDay(for: day)
            let end = cal.date(byAdding: .day, value: 1, to: start)!
            let dayDoses = doses.filter { $0.scheduledTime >= start && $0.scheduledTime < end && !$0.isSkipped }
            let total = dayDoses.count
            let taken = dayDoses.filter { $0.status == .taken }.count
            let pct = total > 0 ? Double(taken) / Double(total) * 100 : 0
            let key = ISO8601DateFormatter().string(from: start)
            return WeeklyDayStat(
                id: key,
                weekdayShort: df.string(from: start),
                adherencePercent: pct,
                taken: taken,
                scheduled: total
            )
        }
    }

    /// Consecutive days (looking back from today) with at least one dose marked taken.
    var currentStreakDays: Int {
        let cal = Calendar.current
        var day = cal.startOfDay(for: Date())
        if takenOnDate(day) == 0 {
            guard let prev = cal.date(byAdding: .day, value: -1, to: day) else { return 0 }
            day = prev
        }
        if takenOnDate(day) == 0 { return 0 }
        var streak = 0
        while takenOnDate(day) > 0 {
            streak += 1
            guard let prev = cal.date(byAdding: .day, value: -1, to: day) else { break }
            day = prev
        }
        return streak
    }

    /// Best run of consecutive calendar days with ≥1 taken dose (scans last 400 days).
    var bestStreakDays: Int {
        let cal = Calendar.current
        let end = cal.startOfDay(for: Date())
        guard let start = cal.date(byAdding: .day, value: -400, to: end) else { return 0 }
        var best = 0
        var run = 0
        var d = start
        while d <= end {
            if takenOnDate(d) > 0 {
                run += 1
                best = max(best, run)
            } else {
                run = 0
            }
            guard let next = cal.date(byAdding: .day, value: 1, to: d) else { break }
            d = next
        }
        return best
    }

    struct MonthlyAdherenceData: Identifiable {
        let id: String
        let monthLabel: String
        let adherence: Double
    }

    var monthlyAdherence: [MonthlyAdherenceData] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: doses) { dose -> Date in
            let components = calendar.dateComponents([.year, .month], from: dose.scheduledTime)
            return calendar.date(from: components) ?? dose.scheduledTime
        }
        let keyFormatter = DateFormatter()
        keyFormatter.dateFormat = "yyyy-MM"
        keyFormatter.locale = Locale(identifier: "en_US_POSIX")
        let labelFormatter = DateFormatter()
        labelFormatter.dateFormat = "MMM"
        labelFormatter.locale = Locale(identifier: "en_US")
        return grouped.compactMap { date, doses -> MonthlyAdherenceData? in
            let total = doses.filter { !$0.isSkipped }.count
            let taken = doses.filter { $0.status == .taken }.count
            let adherence = total > 0 ? Double(taken) / Double(total) * 100 : 0
            let key = keyFormatter.string(from: date)
            let label = labelFormatter.string(from: date)
            return MonthlyAdherenceData(id: key, monthLabel: label, adherence: adherence)
        }
        .sorted { $0.id < $1.id }
    }

    struct MedicationStat: Identifiable {
        let id: UUID
        let name: String
        let totalCount: Int
        let takenCount: Int
        var adherence: Double { totalCount > 0 ? Double(takenCount) / Double(totalCount) * 100 : 0 }
    }

    var medicationStats: [MedicationStat] {
        medications.filter { !$0.isArchived }.map { med in
            let medDoses = doses.filter { $0.medicationId == med.id && !$0.isSkipped }
            return MedicationStat(
                id: med.id,
                name: med.name,
                totalCount: medDoses.count,
                takenCount: medDoses.filter { $0.status == .taken }.count
            )
        }
        .filter { $0.totalCount > 0 }
        .sorted { $0.adherence > $1.adherence }
    }

    var activeMedications: [Medication] {
        medications.filter { !$0.isArchived }
    }

    /// Earliest future dose not yet taken or skipped (non-archived medications).
    var nextUpcomingDose: Dose? {
        doses
            .filter { dose in
                !isArchived(dose.medicationId)
                    && dose.takenTime == nil
                    && !dose.isSkipped
                    && dose.scheduledTime > Date()
            }
            .sorted { $0.scheduledTime < $1.scheduledTime }
            .first
    }

    var lowStockMedicationsCount: Int {
        activeMedications.filter { med in
            guard let stock = med.stockCount, med.refillReminder else { return false }
            return stock <= med.lowStockThreshold
        }.count
    }

    var archivedMedications: [Medication] {
        medications.filter(\.isArchived)
    }

    // MARK: - CRUD

    func addMedication(
        name: String,
        dosage: Double,
        unit: DosageUnit,
        instructions: String?,
        times: [Date],
        frequency: FrequencyType,
        daysOfWeek: [DayOfWeek]?,
        startDate: Date,
        endDate: Date?,
        trackInventory: Bool,
        stockCount: Int,
        lowStockThreshold: Int,
        refillReminder: Bool,
        notes: String?
    ) {
        let instructionsTrimmed = instructions?.trimmingCharacters(in: .whitespacesAndNewlines)
        let notesTrimmed = notes?.trimmingCharacters(in: .whitespacesAndNewlines)
        let stock: Int? = trackInventory ? max(0, stockCount) : nil
        let threshold = max(1, min(lowStockThreshold, stock ?? 999))
        let med = Medication(
            id: UUID(),
            name: name,
            dosage: dosage,
            unit: unit,
            instructions: instructionsTrimmed.flatMap { $0.isEmpty ? nil : $0 },
            notes: notesTrimmed.flatMap { $0.isEmpty ? nil : $0 },
            isActive: true,
            refillDate: refillDateFromStockIfNeeded(stock: stock, startDate: startDate),
            refillReminder: refillReminder,
            createdAt: Date(),
            stockCount: stock,
            lowStockThreshold: threshold,
            isArchived: false
        )
        medications.append(med)

        let schedule = Schedule(
            id: UUID(),
            medicationId: med.id,
            medicationName: med.name,
            times: times,
            frequency: frequency,
            daysOfWeek: daysOfWeek,
            startDate: startDate,
            endDate: endDate,
            isActive: true
        )
        schedules.append(schedule)
        generateDoses(for: schedule)
        scheduleNotifications(for: schedule)
        saveToUserDefaults()
    }

    func updateMedication(
        id: UUID,
        name: String,
        dosage: Double,
        unit: DosageUnit,
        instructions: String?,
        times: [Date],
        frequency: FrequencyType,
        daysOfWeek: [DayOfWeek]?,
        startDate: Date,
        endDate: Date?,
        trackInventory: Bool,
        stockCount: Int,
        lowStockThreshold: Int,
        refillReminder: Bool,
        notes: String?
    ) {
        guard let mi = medications.firstIndex(where: { $0.id == id }) else { return }
        let instructionsTrimmed = instructions?.trimmingCharacters(in: .whitespacesAndNewlines)
        let notesTrimmed = notes?.trimmingCharacters(in: .whitespacesAndNewlines)
        let wasActive = medications[mi].isActive
        let createdAt = medications[mi].createdAt
        let wasArchived = medications[mi].isArchived
        let stock: Int? = trackInventory ? max(0, stockCount) : nil
        let threshold = max(1, min(lowStockThreshold, stock ?? 999))

        medications[mi] = Medication(
            id: id,
            name: name,
            dosage: dosage,
            unit: unit,
            instructions: instructionsTrimmed.flatMap { $0.isEmpty ? nil : $0 },
            notes: notesTrimmed.flatMap { $0.isEmpty ? nil : $0 },
            isActive: wasActive,
            refillDate: refillDateFromStockIfNeeded(stock: stock, startDate: startDate),
            refillReminder: refillReminder,
            createdAt: createdAt,
            stockCount: stock,
            lowStockThreshold: threshold,
            isArchived: wasArchived
        )

        if let si = schedules.firstIndex(where: { $0.medicationId == id }) {
            schedules[si].medicationName = name
            schedules[si].times = times
            schedules[si].frequency = frequency
            schedules[si].daysOfWeek = daysOfWeek
            schedules[si].startDate = startDate
            schedules[si].endDate = endDate
            let updated = schedules[si]
            rebalanceDosesAfterScheduleChange(medicationId: id, schedule: updated)
            if wasActive, !wasArchived {
                scheduleNotifications(for: updated)
            } else {
                removePendingNotifications(prefix: notificationPrefix(for: id))
            }
        } else {
            let newSchedule = Schedule(
                id: UUID(),
                medicationId: id,
                medicationName: name,
                times: times,
                frequency: frequency,
                daysOfWeek: daysOfWeek,
                startDate: startDate,
                endDate: endDate,
                isActive: true
            )
            schedules.append(newSchedule)
            generateDoses(for: newSchedule)
            if wasActive, !wasArchived {
                scheduleNotifications(for: newSchedule)
            }
        }
        saveToUserDefaults()
    }

    func archiveMedication(_ medication: Medication) {
        guard let i = medications.firstIndex(where: { $0.id == medication.id }) else { return }
        medications[i].isArchived = true
        medications[i].isActive = false
        removePendingNotifications(prefix: notificationPrefix(for: medication.id))
        saveToUserDefaults()
    }

    func unarchiveMedication(_ medication: Medication) {
        guard let i = medications.firstIndex(where: { $0.id == medication.id }) else { return }
        medications[i].isArchived = false
        medications[i].isActive = true
        if let sch = schedules.first(where: { $0.medicationId == medication.id }) {
            scheduleNotifications(for: sch)
        }
        saveToUserDefaults()
    }

    func logRefill(medicationId: UUID, quantity: Int, notes: String?) {
        guard let med = medication(for: medicationId), quantity > 0 else { return }
        let entry = Refill(
            id: UUID(),
            medicationId: medicationId,
            medicationName: med.name,
            date: Date(),
            quantity: quantity,
            notes: notes.flatMap { $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : $0 }
        )
        refills.append(entry)
        if let i = medications.firstIndex(where: { $0.id == medicationId }) {
            let current = medications[i].stockCount ?? 0
            medications[i].stockCount = current + quantity
            medications[i].refillDate = refillDateFromStockIfNeeded(stock: medications[i].stockCount, startDate: Date())
        }
        removeLowStockNotification(for: medicationId)
        saveToUserDefaults()
    }

    func refillsSorted(for medicationId: UUID) -> [Refill] {
        refills.filter { $0.medicationId == medicationId }.sorted { $0.date > $1.date }
    }

    /// Snooze from UI: schedule a one-off notification.
    func snoozeReminder(medicationId: UUID, minutes: Int) {
        guard let name = medication(for: medicationId)?.name else { return }
        let delay = TimeInterval(minutes * 60)
        MedNotificationSetup.scheduleSnoozeNotification(
            medicationId: medicationId,
            medicationName: name,
            delaySeconds: delay
        )
    }

    /// Drops pending/missed doses (no history), then fills the horizon again from the schedule.
    private func rebalanceDosesAfterScheduleChange(medicationId: UUID, schedule: Schedule) {
        doses.removeAll { dose in
            dose.medicationId == medicationId && dose.takenTime == nil && !dose.isSkipped
        }
        generateDoses(for: schedule)
        for i in doses.indices where doses[i].medicationId == medicationId {
            doses[i].medicationName = schedule.medicationName
        }
        syncDosageFromMedication(for: medicationId)
    }

    private func refillDateFromStockIfNeeded(stock: Int?, startDate: Date) -> Date? {
        guard let s = stock, s > 0 else { return nil }
        return Calendar.current.date(byAdding: .day, value: min(s, 365), to: Calendar.current.startOfDay(for: startDate))
    }

    func generateDoses(for schedule: Schedule) {
        guard medication(for: schedule.medicationId)?.isArchived != true else { return }
        let calendar = Calendar.current
        let scheduleStart = calendar.startOfDay(for: schedule.startDate)
        let defaultEnd = calendar.date(byAdding: .month, value: 3, to: calendar.startOfDay(for: Date()))!
        let rangeEnd = schedule.endDate.map { calendar.startOfDay(for: $0) } ?? defaultEnd
        var currentDate = scheduleStart
        while currentDate <= rangeEnd {
            if shouldTakeOnDate(currentDate, schedule: schedule) {
                for time in schedule.times {
                    let timeComponents = calendar.dateComponents([.hour, .minute], from: time)
                    var dateComponents = calendar.dateComponents([.year, .month, .day], from: currentDate)
                    dateComponents.hour = timeComponents.hour
                    dateComponents.minute = timeComponents.minute
                    guard let scheduledTime = calendar.date(from: dateComponents) else { continue }
                    let duplicate = doses.contains {
                        $0.medicationId == schedule.medicationId && abs($0.scheduledTime.timeIntervalSince(scheduledTime)) < 60
                    }
                    if !duplicate {
                        let dose = Dose(
                            id: UUID(),
                            medicationId: schedule.medicationId,
                            medicationName: schedule.medicationName,
                            scheduledTime: scheduledTime,
                            takenTime: nil,
                            dosage: 0,
                            unit: .mg,
                            notes: nil,
                            isSkipped: false,
                            skipReason: nil
                        )
                        doses.append(dose)
                    }
                }
            }
            guard let next = calendar.date(byAdding: .day, value: 1, to: currentDate) else { break }
            currentDate = next
        }
        syncDosageFromMedication(for: schedule.medicationId)
    }

    private func syncDosageFromMedication(for medicationId: UUID) {
        guard let med = medications.first(where: { $0.id == medicationId }) else { return }
        for i in doses.indices where doses[i].medicationId == medicationId {
            doses[i].dosage = med.dosage
            doses[i].unit = med.unit
        }
    }

    private func shouldTakeOnDate(_ date: Date, schedule: Schedule) -> Bool {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date)
        switch schedule.frequency {
        case .daily, .custom:
            return true
        case .weekly:
            guard let days = schedule.daysOfWeek, !days.isEmpty else { return false }
            return days.contains { $0.rawValue == weekday }
        case .once:
            return calendar.isDate(date, inSameDayAs: schedule.startDate)
        }
    }

    func takeDose(_ dose: Dose) {
        if let index = doses.firstIndex(where: { $0.id == dose.id }) {
            guard doses[index].takenTime == nil else { return }
            doses[index].takenTime = Date()
            decrementStockIfNeeded(for: dose.medicationId)
            saveToUserDefaults()
        }
    }

    func skipDose(_ dose: Dose, reason: SkipReason?) {
        if let index = doses.firstIndex(where: { $0.id == dose.id }) {
            guard !doses[index].isSkipped else { return }
            doses[index].isSkipped = true
            doses[index].skipReason = reason
            saveToUserDefaults()
        }
    }

    private func decrementStockIfNeeded(for medicationId: UUID) {
        guard let i = medications.firstIndex(where: { $0.id == medicationId }) else { return }
        guard var stock = medications[i].stockCount else { return }
        stock = max(0, stock - 1)
        medications[i].stockCount = stock
        medications[i].refillDate = refillDateFromStockIfNeeded(stock: stock, startDate: Date())
        let threshold = medications[i].lowStockThreshold
        if medications[i].refillReminder {
            if stock <= threshold {
                scheduleLowStockNotification(for: medications[i])
            } else {
                removeLowStockNotification(for: medicationId)
            }
        }
    }

    private func lowStockNotificationId(for medicationId: UUID) -> String {
        "lowstock-\(medicationId.uuidString)"
    }

    private func scheduleLowStockNotification(for med: Medication) {
        let id = lowStockNotificationId(for: med.id)
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
        let content = UNMutableNotificationContent()
        content.title = "Low supply"
        content.body = "\(med.name): \(med.stockCount ?? 0) left. Consider a refill."
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2, repeats: false)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    private func removeLowStockNotification(for medicationId: UUID) {
        let id = lowStockNotificationId(for: medicationId)
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
    }

    func deleteMedication(_ medication: Medication) {
        medications.removeAll { $0.id == medication.id }
        schedules.removeAll { $0.medicationId == medication.id }
        doses.removeAll { $0.medicationId == medication.id }
        refills.removeAll { $0.medicationId == medication.id }
        removePendingNotifications(prefix: notificationPrefix(for: medication.id))
        removeLowStockNotification(for: medication.id)
        saveToUserDefaults()
    }

    func toggleActive(_ medication: Medication) {
        guard let index = medications.firstIndex(where: { $0.id == medication.id }) else { return }
        guard !medications[index].isArchived else { return }
        medications[index].isActive.toggle()
        if medications[index].isActive {
            if let schedule = schedules.first(where: { $0.medicationId == medication.id }) {
                scheduleNotifications(for: schedule)
            }
        } else {
            removePendingNotifications(prefix: notificationPrefix(for: medication.id))
        }
        saveToUserDefaults()
    }

    func takenToday(for medicationId: UUID) -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        return doses.filter { dose in
            guard let taken = dose.takenTime else { return false }
            return dose.medicationId == medicationId && taken >= today && taken < tomorrow
        }.count
    }

    func nextDose(for medicationId: UUID) -> Date? {
        guard !isArchived(medicationId) else { return nil }
        return doses
            .filter { $0.medicationId == medicationId && $0.status == .pending && $0.scheduledTime > Date() }
            .sorted { $0.scheduledTime < $1.scheduledTime }
            .first?
            .scheduledTime
    }

    func takenOnDate(_ date: Date) -> Int {
        let dayStart = Calendar.current.startOfDay(for: date)
        let dayEnd = Calendar.current.date(byAdding: .day, value: 1, to: dayStart)!
        return doses.filter { dose in
            guard let taken = dose.takenTime else { return false }
            return taken >= dayStart && taken < dayEnd
        }.count
    }

    func totalOnDate(_ date: Date) -> Int {
        let dayStart = Calendar.current.startOfDay(for: date)
        let dayEnd = Calendar.current.date(byAdding: .day, value: 1, to: dayStart)!
        return doses.filter { $0.scheduledTime >= dayStart && $0.scheduledTime < dayEnd }.count
    }

    func dosesOnDate(_ date: Date, filter: HistoryDoseFilter = .all) -> [Dose] {
        let dayStart = Calendar.current.startOfDay(for: date)
        let dayEnd = Calendar.current.date(byAdding: .day, value: 1, to: dayStart)!
        let list = doses.filter { $0.scheduledTime >= dayStart && $0.scheduledTime < dayEnd }
            .sorted { $0.scheduledTime < $1.scheduledTime }
        switch filter {
        case .all: return list
        case .taken: return list.filter { $0.status == .taken }
        case .missed: return list.filter { $0.status == .missed }
        case .skipped: return list.filter { $0.status == .skipped }
        }
    }

    // MARK: - Notifications

    private func notificationPrefix(for medicationId: UUID) -> String {
        "med-\(medicationId.uuidString)"
    }

    private func removePendingNotifications(prefix: String) {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let ids = requests.filter { $0.identifier.hasPrefix(prefix) }.map(\.identifier)
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
        }
    }

    func scheduleNotifications(for schedule: Schedule) {
        let center = UNUserNotificationCenter.current()
        let prefix = notificationPrefix(for: schedule.medicationId)
        guard let med = medications.first(where: { $0.id == schedule.medicationId }), med.isActive, !med.isArchived else {
            removePendingNotifications(prefix: prefix)
            return
        }

        let requests = buildNotificationRequests(for: schedule, prefix: prefix)
        center.getPendingNotificationRequests { pending in
            let toRemove = pending.filter { $0.identifier.hasPrefix(prefix) }.map(\.identifier)
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: toRemove)
            for request in requests {
                UNUserNotificationCenter.current().add(request)
            }
        }
    }

    private func buildNotificationRequests(for schedule: Schedule, prefix: String) -> [UNNotificationRequest] {
        let calendar = Calendar.current
        let now = Date()
        let scheduleStart = calendar.startOfDay(for: schedule.startDate)
        let defaultEnd = calendar.date(byAdding: .month, value: 1, to: now)!
        let rangeEnd = schedule.endDate.map { calendar.startOfDay(for: $0) } ?? defaultEnd
        var currentDate = scheduleStart
        var result: [UNNotificationRequest] = []
        while currentDate <= rangeEnd {
            if shouldTakeOnDate(currentDate, schedule: schedule) {
                for time in schedule.times {
                    let timeComponents = calendar.dateComponents([.hour, .minute], from: time)
                    var dateComponents = calendar.dateComponents([.year, .month, .day], from: currentDate)
                    dateComponents.hour = timeComponents.hour
                    dateComponents.minute = timeComponents.minute
                    guard let scheduledTime = calendar.date(from: dateComponents), scheduledTime > now else { continue }
                    let content = UNMutableNotificationContent()
                    content.title = "Dose reminder"
                    content.body = "Time to take \(schedule.medicationName)"
                    content.sound = .default
                    content.categoryIdentifier = MedNotificationSetup.doseReminderCategoryId
                    content.userInfo = [
                        MedNotificationSetup.userInfoMedicationIdKey: schedule.medicationId.uuidString,
                        MedNotificationSetup.userInfoMedicationNameKey: schedule.medicationName
                    ]
                    let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
                    let identifier = "\(prefix)-\(Int(scheduledTime.timeIntervalSince1970))"
                    result.append(UNNotificationRequest(identifier: identifier, content: content, trigger: trigger))
                }
            }
            guard let next = calendar.date(byAdding: .day, value: 1, to: currentDate) else { break }
            currentDate = next
        }
        return result
    }

    // MARK: - Persistence

    private let medicationsKey = "medremind_medications"
    private let schedulesKey = "medremind_schedules"
    private let dosesKey = "medremind_doses"
    private let refillsKey = "medremind_refills"

    func saveToUserDefaults() {
        if let encoded = try? JSONEncoder().encode(medications) {
            UserDefaults.standard.set(encoded, forKey: medicationsKey)
        }
        if let encoded = try? JSONEncoder().encode(schedules) {
            UserDefaults.standard.set(encoded, forKey: schedulesKey)
        }
        if let encoded = try? JSONEncoder().encode(doses) {
            UserDefaults.standard.set(encoded, forKey: dosesKey)
        }
        if let encoded = try? JSONEncoder().encode(refills) {
            UserDefaults.standard.set(encoded, forKey: refillsKey)
        }
    }

    func loadFromUserDefaults() {
        if let data = UserDefaults.standard.data(forKey: medicationsKey),
           let decoded = try? JSONDecoder().decode([Medication].self, from: data) {
            medications = decoded
        }
        if let data = UserDefaults.standard.data(forKey: schedulesKey),
           let decoded = try? JSONDecoder().decode([Schedule].self, from: data) {
            schedules = decoded
        }
        if let data = UserDefaults.standard.data(forKey: dosesKey),
           let decoded = try? JSONDecoder().decode([Dose].self, from: data) {
            doses = decoded
        }
        if let data = UserDefaults.standard.data(forKey: refillsKey),
           let decoded = try? JSONDecoder().decode([Refill].self, from: data) {
            refills = decoded
        }
        if medications.isEmpty {
            loadDemoData()
            saveToUserDefaults()
        }
        for schedule in schedules {
            guard let med = medications.first(where: { $0.id == schedule.medicationId }), med.isActive, !med.isArchived else { continue }
            scheduleNotifications(for: schedule)
        }
    }

    private func loadDemoData() {
        let calendar = Calendar.current
        let now = Date()
        let med1 = Medication(
            id: UUID(),
            name: "Vitamin D3",
            dosage: 2000,
            unit: .mg,
            instructions: "After breakfast",
            notes: "Immune support",
            isActive: true,
            refillDate: Date().addingTimeInterval(86400 * 30),
            refillReminder: true,
            createdAt: Date(),
            stockCount: 60,
            lowStockThreshold: 10,
            isArchived: false
        )
        let med2 = Medication(
            id: UUID(),
            name: "Magnesium",
            dosage: 400,
            unit: .mg,
            instructions: "Before bed",
            notes: "Sleep",
            isActive: true,
            refillDate: Date().addingTimeInterval(86400 * 15),
            refillReminder: true,
            createdAt: Date(),
            stockCount: 45,
            lowStockThreshold: 7,
            isArchived: false
        )
        medications = [med1, med2]

        let time1 = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: now)!
        let time2 = calendar.date(bySettingHour: 21, minute: 0, second: 0, of: now)!
        let schedule1 = Schedule(
            id: UUID(),
            medicationId: med1.id,
            medicationName: med1.name,
            times: [time1],
            frequency: .daily,
            daysOfWeek: nil,
            startDate: now,
            endDate: nil,
            isActive: true
        )
        let schedule2 = Schedule(
            id: UUID(),
            medicationId: med2.id,
            medicationName: med2.name,
            times: [time2],
            frequency: .daily,
            daysOfWeek: nil,
            startDate: now,
            endDate: nil,
            isActive: true
        )
        schedules = [schedule1, schedule2]

        let today = calendar.startOfDay(for: now)
        let dose1 = Dose(
            id: UUID(),
            medicationId: med1.id,
            medicationName: med1.name,
            scheduledTime: calendar.date(bySettingHour: 9, minute: 0, second: 0, of: today)!,
            takenTime: calendar.date(bySettingHour: 9, minute: 15, second: 0, of: today)!,
            dosage: med1.dosage,
            unit: med1.unit,
            notes: nil,
            isSkipped: false,
            skipReason: nil
        )
        let dose2 = Dose(
            id: UUID(),
            medicationId: med2.id,
            medicationName: med2.name,
            scheduledTime: calendar.date(bySettingHour: 21, minute: 0, second: 0, of: today)!,
            takenTime: nil,
            dosage: med2.dosage,
            unit: med2.unit,
            notes: nil,
            isSkipped: false,
            skipReason: nil
        )
        doses = [dose1, dose2]
    }
}
