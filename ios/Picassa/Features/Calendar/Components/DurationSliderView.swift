import SwiftUI

struct DurationSliderView: View {
    @Binding var duration: TimeInterval
    let maxDuration: Double?  // Pridaný parameter pre maximálnu dĺžku
    @State private var sliderValue: Double = 0
    
    init(duration: Binding<TimeInterval>, maxDuration: Double? = nil) {
        self._duration = duration
        self.maxDuration = maxDuration
    }
    
    private var sliderMaxValue: Double {
        maxDuration ?? 24.0  // Použijeme maxDuration ak existuje, inak 24h
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Slider(value: Binding(
                    get: { sliderValue },
                    set: { newValue in
                        sliderValue = newValue
                        duration = newValue * 3600
                    }
                ), in: 0...sliderMaxValue, step: 0.5)
            }
            
            Text("\(Int(sliderValue))h \(sliderValue.truncatingRemainder(dividingBy: 1) == 0 ? "00" : "30")m")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .onAppear {
            sliderValue = duration / 3600
        }
    }
}
