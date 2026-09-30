//
//  DateTool.swift
//  Banter-iOS
//
//  Created by Ali Ziwa on 9/30/26.
//

import Foundation
import FoundationModels

/// Tells the model what day and time it is right now.
///
/// The on-device model was trained at a fixed point in the past and has no clock of its own.
/// Without this, "tonight" or "this weekend" get resolved against the wrong year.
struct DateTool: Tool {
    let name = "getCurrentDate"
    let description = "Returns the current date, time, day of the week and time zone on this device."

    /// No inputs needed, but the framework still wants an arguments type.
    @Generable
    struct Arguments {}

    func call(arguments: Arguments) async throws -> String {
        let now = Date()

        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, d MMMM yyyy 'at' h:mm a"
        let readable = formatter.string(from: now)

        let zone = TimeZone.current
        let iso = now.ISO8601Format()

        return """
            Today is \(readable) (\(zone.identifier)).
            ISO 8601 timestamp: \(iso)
            """
    }
}
