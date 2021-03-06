// Copyright 2020 David Sansome
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import Foundation

@objc
class LevelTimeRemainingItem: NSObject, TKMModelItem {
  let services: TKMServices
  let currentLevelAssignments: [TKMAssignment]

  @objc init(services: TKMServices, currentLevelAssignments: [TKMAssignment]) {
    self.services = services
    self.currentLevelAssignments = currentLevelAssignments
  }

  func createCell() -> TKMModelCell! {
    return LevelTimeRemainingCell(style: .value1,
                                  reuseIdentifier: String(describing: LevelTimeRemainingCell.self))
  }
}

class LevelTimeRemainingCell: TKMModelCell {
  private var services: TKMServices?

  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    selectionStyle = .none
    detailTextLabel?.textColor = TKMStyle.Color.label
  }

  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func update(with baseItem: TKMModelItem!) {
    let item = baseItem as! LevelTimeRemainingItem

    var radicalDates = [Date]()
    var guruDates = [Date]()
    var levels = [Int32]()

    for assignment in item.currentLevelAssignments {
      if assignment.subjectType != .radical {
        continue
      }
      guard let subject = item.services.dataLoader.load(subjectID: Int(assignment.subjectId)),
        let guruDate = assignment.guruDate(for: subject) else {
        continue
      }
      radicalDates.append(guruDate)
    }
    radicalDates.sort()
    let lastRadicalGuruTime = max(radicalDates.last?.timeIntervalSinceNow ?? 0, 0)

    for assignment in item.currentLevelAssignments {
      if assignment.subjectType != .kanji {
        continue
      }
      levels.append(assignment.level)
      if !assignment.hasAvailableAt {
        // This kanji is locked, but it might not be essential for level-up
        guruDates.append(Date.distantFuture)
        continue
      }
      guard let subject = item.services.dataLoader.load(subjectID: Int(assignment.subjectId)),
        let guruDate = assignment.guruDate(for: subject) else {
        continue
      }
      guruDates.append(guruDate)
    }

    // Sort the list of dates and remove the most distant 10%.
    guruDates = Array(guruDates.sorted().dropLast(Int(Double(guruDates.count) * 0.1)))
    levels = Array(levels.sorted(by: >).dropLast(Int(Double(levels.count) * 0.1)))

    if let lastGuruDate = guruDates.last, let wkLevel = levels.last {
      if lastGuruDate == Date.distantFuture {
        // There is still a locked kanji needed for level-up, so we don't know how long
        // the user will take to level up. Use their average level time, minus the time
        // they've spent at this level so far, as an estimate.
        var average = item.services.localCachingClient!.getAverageRemainingLevelTime()
        // But ensure it can't be less than the time it would take to get a fresh item
        // to Guru, if they've spent longer at the current level than the average.
        average = max(average, TKMMinimumTimeUntilGuruSeconds(wkLevel, 1) + lastRadicalGuruTime)
        setRemaining(Date(timeIntervalSinceNow: average), isEstimate: true)
      } else {
        setRemaining(lastGuruDate, isEstimate: false)
      }
    }
  }

  private func setRemaining(_ finish: Date, isEstimate: Bool) {
    if isEstimate {
      textLabel!.text = "Time remaining (estimated)"
    } else {
      textLabel!.text = "Time remaining"
    }

    if finish < Date() {
      detailTextLabel!.text = "Now"
    } else {
      detailTextLabel!.text = intervalString(finish)
    }
  }

  private func intervalString(_ date: Date) -> String {
    let formatter = DateComponentsFormatter()
    formatter.unitsStyle = DateComponentsFormatter.UnitsStyle.abbreviated

    let componentsBitMask: Set = [Calendar.Component.day, Calendar.Component.hour, Calendar.Component.minute]
    var components = Calendar.current.dateComponents(componentsBitMask, from: Date(), to: date)

    // Only show minutes after there are no hours left.
    if let hour = components.hour, hour > 0 {
      components.minute = 0
    }

    return formatter.string(from: components)!
  }
}
