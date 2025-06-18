import SwiftUI
import ComposableArchitecture

struct ColorPickerView: View {
    let selectedColor: EventColor
    let onColorSelected: (EventColor) -> Void
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(EventColor.allCases, id: \.self) { color in
                    Circle()
                        .fill(color.color)
                        .frame(width: 30, height: 30)
                        .overlay(
                            Circle()
                                .stroke(Color.primary, lineWidth: selectedColor == color ? 2 : 0)
                        )
                        .onTapGesture {
                            onColorSelected(color)
                        }
                }
            }
            .padding(.horizontal)
        }
    }
}

struct EditEventView: View {
    let event: Event
    let onSave: (Event) -> Void
    let onCancel: () -> Void
    let store: StoreOf<EventDetailFeature>
    
    @State private var title: String
    @State private var description: String
    @State private var date: Date
    @State private var duration: TimeInterval
    @State private var selectedColor: EventColor
    @State private var currency: String
    @State private var requiresDeposit: Bool
    @State private var isDepositPaid: Bool
    @State private var depositPrice: String
    
    init(event: Event, onSave: @escaping (Event) -> Void, onCancel: @escaping () -> Void, store: StoreOf<EventDetailFeature>) {
        self.event = event
        self.onSave = onSave
        self.onCancel = onCancel
        self.store = store
        _title = State(initialValue: event.title)
        _description = State(initialValue: event.description ?? "")
        _date = State(initialValue: event.date)
        _duration = State(initialValue: event.duration)
        _selectedColor = State(initialValue: event.color)
        _currency = State(initialValue: event.currency ?? "CZK")
        _requiresDeposit = State(initialValue: event.requiresDeposit ?? false)
        _isDepositPaid = State(initialValue: event.isDepositPaid ?? false)
        _depositPrice = State(initialValue: event.depositPrice?.description ?? "")
    }
    
    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            Form {
                Section {
                    TextField(String(localized: "event.title"), text: $title)
                    TextField(String(localized: "event.description"), text: $description)
                }
                
                Section {
                    ColorPickerView(
                        selectedColor: selectedColor,
                        onColorSelected: { selectedColor = $0 }
                    )
                }
                
                Section {
                    UserSearchView(store: store)
                }
                
                Section {
                    DatePicker(String(localized: "event.date"), selection: $date)
                    DurationSliderView(
                        duration: $duration,
                        maxDuration: viewStore.currentUser?.privateUser?.lengthOfTheWorkingDay ?? 24.0
                    )
                }
                
                
                Section(header: Text("Záloha")) {
                    Toggle("Požadovaná záloha", isOn: $requiresDeposit)
                    
                    if requiresDeposit {
                        HStack {
                            TextField("Výška zálohy", text: $depositPrice)
                                .keyboardType(.decimalPad)
                            Text(currency)
                        }
                        
                        Toggle("Záloha zaplatená", isOn: $isDepositPaid)
                    }
                }
            }
            .navigationTitle(String(localized: "event.edit"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(String(localized: "event.cancel"), role: .cancel) {
                        onCancel()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(String(localized: "event.save")) {
                        let updatedEvent = Event(
                            id: event.id,
                            title: title,
                            description: description,
                            date: date,
                            duration: duration,
                            attendeeIds: event.attendeeIds,
                            attendees: event.attendees,
                            color: selectedColor,
                            requiresDeposit: requiresDeposit,
                            isDepositPaid: isDepositPaid,
                            depositPrice: requiresDeposit ? Decimal(string: depositPrice) : nil,
                            currency: requiresDeposit ? currency : "CZK"
                        )
                        onSave(updatedEvent)
                    }
                }
            }
        }
    }
}
