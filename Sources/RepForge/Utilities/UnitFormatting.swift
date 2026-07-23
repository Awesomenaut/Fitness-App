import Foundation
import SwiftUI

enum WeightUnit: String, CaseIterable {
    case pounds = "lb"
    case kilograms = "kg"

    func fromPounds(_ lb: Double) -> Double {
        switch self {
        case .pounds: return lb
        case .kilograms: return lb * 0.453592
        }
    }

    func toPounds(_ value: Double) -> Double {
        switch self {
        case .pounds: return value
        case .kilograms: return value / 0.453592
        }
    }
}

/// App-wide preferred display unit, persisted in UserDefaults.
final class UnitSettings: ObservableObject {
    static let shared = UnitSettings()

    @Published var rawUnit: String {
        didSet { UserDefaults.standard.set(rawUnit, forKey: "preferredWeightUnit") }
    }

    private init() {
        rawUnit = UserDefaults.standard.string(forKey: "preferredWeightUnit") ?? WeightUnit.pounds.rawValue
    }

    var unit: WeightUnit {
        WeightUnit(rawValue: rawUnit) ?? .pounds
    }

    func display(_ lb: Double) -> String {
        let value = unit.fromPounds(lb)
        return String(format: "%.1f %@", value, unit.rawValue)
            .replacingOccurrences(of: ".0 ", with: " ")
    }
}
