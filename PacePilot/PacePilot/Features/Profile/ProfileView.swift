import SwiftUI
import Combine
import UIKit

// MARK: - Coach Chat Sheet

@MainActor
final class CoachChatViewModel: ObservableObject {
    @Published var sessionState: VoiceSessionState = .idle
    @Published var agentSpeaking = false

    private let voice = VoiceSessionService.shared

    init() {
        voice.$sessionState.assign(to: &$sessionState)
        voice.$agentSpeaking.assign(to: &$agentSpeaking)
    }

    func start() async { await voice.startSession(type: .general) }
    func end() async { await voice.endSession() }
}

struct CoachChatSheet: View {
    @StateObject private var vm = CoachChatViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                VStack(spacing: 32) {
                    Spacer()
                    WaveformView(isActive: vm.agentSpeaking)
                        .frame(height: 60)
                        .padding(.horizontal, 32)
                    statusText
                    actionButton
                    Spacer()
                }
            }
            .navigationTitle("Talk to Coach")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        Task {
                            await vm.end()
                            dismiss()
                        }
                    }
                    .foregroundColor(.accentColor)
                }
            }
        }
    }

    @ViewBuilder
    var statusText: some View {
        switch vm.sessionState {
        case .idle:
            Text("Tap to talk to your coach").foregroundColor(.gray)
        case .connecting:
            Text("Connecting...").foregroundColor(.accentColor)
        case .active:
            Text(vm.agentSpeaking ? "Coach is speaking..." : "Listening...").foregroundColor(.accentColor)
        case .disconnecting:
            Text("Ending session...").foregroundColor(.gray)
        case .error(let msg):
            Text("Error: \(msg)").foregroundColor(.red).font(.caption)
        }
    }

    @ViewBuilder
    var actionButton: some View {
        switch vm.sessionState {
        case .idle, .error:
            Button(action: { Task { await vm.start() } }) {
                Circle()
                    .fill(Color.accentColor)
                    .frame(width: 72, height: 72)
                    .overlay(Image(systemName: "mic.fill").font(.title2).foregroundColor(.black))
            }
        case .active:
            Button(action: { Task { await vm.end() } }) {
                Circle()
                    .fill(Color.red)
                    .frame(width: 72, height: 72)
                    .overlay(Image(systemName: "stop.fill").font(.title2).foregroundColor(.white))
            }
        default:
            ProgressView().tint(.accentColor)
        }
    }
}

// MARK: - Profile View

struct ProfileView: View {
    @StateObject private var vm = ProfileViewModel()
    @State private var showCoachSheet = false
    @State private var showReplanSheet = false

    // Form state
    @State private var displayName = ""
    @State private var weeklyMileageGoalStr = ""
    @State private var targetRaceDistance = ""
    @State private var hasRaceDate = false
    @State private var targetRaceDate = Date()
    @State private var restingHrStr = ""
    @State private var maxHrStr = ""
    @State private var preferredDays: Set<Int> = []
    @State private var city = ""

    private let dayNames = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

    var body: some View {
        NavigationStack {
            Form {
                personalSection
                trainingGoalSection
                scheduleSection
                heartRateSection
                notificationsSection
                coachSection
                connectionsSection
                accountSection
            }
            .navigationTitle("Profile")
            .task {
                await vm.load()
                populateForm()
            }
            .sheet(isPresented: $showCoachSheet) {
                CoachChatSheet()
            }
            .sheet(isPresented: $showReplanSheet) {
                ReplanSheet()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { Task { await saveChanges() } }) {
                        if vm.isSaving {
                            ProgressView().scaleEffect(0.8)
                        } else {
                            Text("Save").bold()
                        }
                    }
                    .disabled(vm.isSaving)
                    .foregroundColor(.accentColor)
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .stravaConnected)) { _ in
                Task { await vm.load() }
            }
            .alert("Save failed", isPresented: .constant(vm.saveError != nil), actions: {
                Button("OK") {}
            }, message: {
                Text(vm.saveError ?? "")
            })
        }
    }

    // MARK: Sections

    var personalSection: some View {
        Section("Personal") {
            if let user = vm.user {
                LabeledContent("Email", value: user.email)
                LabeledContent("Community Tier", value: user.communityTier.rawValue.capitalized)
            }
            HStack {
                Text("Name")
                Spacer()
                TextField("Your name", text: $displayName)
                    .multilineTextAlignment(.trailing)
                    .foregroundColor(.secondary)
            }
            CitySearchField(city: $city)
        }
    }

    var trainingGoalSection: some View {
        Section("Training Goal") {
            Picker("Race Distance", selection: $targetRaceDistance) {
                Text("None").tag("")
                Text("5K").tag("5k")
                Text("10K").tag("10k")
                Text("Half Marathon").tag("half_marathon")
                Text("Marathon").tag("marathon")
                Text("Ultra").tag("ultra")
            }
            Toggle("Race Date", isOn: $hasRaceDate)
            if hasRaceDate {
                DatePicker("", selection: $targetRaceDate, in: Date()..., displayedComponents: .date)
                    .datePickerStyle(.compact)
            }
            HStack {
                Text("Weekly Goal")
                Spacer()
                TextField("km", text: $weeklyMileageGoalStr)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 60)
                    .foregroundColor(.secondary)
                Text("km").foregroundColor(.secondary)
            }
        }
    }

    var scheduleSection: some View {
        Section("Preferred Running Days") {
            HStack(spacing: 6) {
                ForEach(0..<7, id: \.self) { day in
                    let isSelected = preferredDays.contains(day)
                    Button(dayNames[day]) {
                        if isSelected { preferredDays.remove(day) }
                        else { preferredDays.insert(day) }
                    }
                    .font(.caption.bold())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(isSelected ? Color.accentColor : Color(.systemGray5))
                    .foregroundColor(isSelected ? .black : .primary)
                    .cornerRadius(8)
                }
            }
            .buttonStyle(.plain)
        }
    }

    var heartRateSection: some View {
        Section("Heart Rate") {
            HStack {
                Text("Resting HR")
                Spacer()
                TextField("bpm", text: $restingHrStr)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 60)
                    .foregroundColor(.secondary)
                Text("bpm").foregroundColor(.secondary)
            }
            HStack {
                Text("Max HR")
                Spacer()
                TextField("bpm", text: $maxHrStr)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 60)
                    .foregroundColor(.secondary)
                Text("bpm").foregroundColor(.secondary)
            }
        }
    }

    var notificationsSection: some View {
        Section {
            NavigationLink {
                NotificationPreferencesView()
            } label: {
                Label("Notifications", systemImage: "bell.fill")
            }
        }
    }

    var coachSection: some View {
        Section {
            Button(action: { showCoachSheet = true }) {
                Label("Talk to Coach", systemImage: "mic.fill")
                    .foregroundColor(.accentColor)
            }
            Button(action: { showReplanSheet = true }) {
                Label("Regenerate Training Plan", systemImage: "arrow.clockwise")
                    .foregroundColor(.accentColor)
            }
            Text("Ask your coach to update your training plan, change your goals, or answer questions.")
                .font(.caption)
                .foregroundColor(.secondary)
        } header: {
            Text("Coach")
        }
    }

    var connectionsSection: some View {
        Section("Connected Services") {
            if vm.user?.stravaConnected == true {
                Label("Strava Connected", systemImage: "checkmark.circle.fill")
                    .foregroundColor(.green)
            } else {
                Button(action: { Task { await vm.connectStrava() } }) {
                    Label("Connect Strava", systemImage: "link")
                }
            }
        }
    }

    var accountSection: some View {
        Section {
            Button("Sign Out", role: .destructive) { vm.signOut() }
        }
    }

    // MARK: Helpers

    private func populateForm() {
        guard let user = vm.user else { return }
        displayName = user.displayName
        weeklyMileageGoalStr = user.weeklyMileageGoal.map { String(format: "%.0f", $0) } ?? ""
        targetRaceDistance = user.targetRaceDistance?.lowercased() ?? ""
        if let date = user.targetRaceDate {
            hasRaceDate = true
            targetRaceDate = date
        }
        restingHrStr = user.restingHr.map { String($0) } ?? ""
        maxHrStr = user.maxHr.map { String($0) } ?? ""
        preferredDays = Set(user.preferredDays)
        city = user.city ?? ""
    }

    private func saveChanges() async {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        let request = ProfileUpdateRequest(
            displayName: displayName.isEmpty ? nil : displayName,
            weeklyMileageGoal: Double(weeklyMileageGoalStr),
            targetRaceDistance: targetRaceDistance.isEmpty ? nil : targetRaceDistance,
            targetRaceDate: hasRaceDate ? targetRaceDate : nil,
            restingHr: Int(restingHrStr),
            maxHr: Int(maxHrStr),
            preferredDays: Array(preferredDays).sorted(),
            city: city.isEmpty ? nil : city
        )
        await vm.save(request)
    }
}

#if DEBUG
#Preview("Profile") {
    ProfileView()
        .preferredColorScheme(.dark)
}

#Preview("Coach Chat") {
    CoachChatSheet()
        .preferredColorScheme(.dark)
}
#endif
