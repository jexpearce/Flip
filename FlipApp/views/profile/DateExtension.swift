//
//  DateExtension.swift
//  FlipApp
//
//  Created by Jex Pearce on 2/24/25.
//

import Foundation

extension Calendar {
    func isDate(_ date: Date, inSameWeekAs weekDate: Date) -> Bool {
        let components1 = self.dateComponents(
            [.yearForWeekOfYear, .weekOfYear], from: date)
        let components2 = self.dateComponents(
            [.yearForWeekOfYear, .weekOfYear], from: weekDate)
        return components1.yearForWeekOfYear == components2.yearForWeekOfYear
            && components1.weekOfYear == components2.weekOfYear
    }
}
