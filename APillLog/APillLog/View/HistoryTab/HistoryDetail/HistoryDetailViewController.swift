//
//  HistoryDetailViewController.swift
//  APillLog
//
//  Created by 이지원 on 2022/07/30.
//

import Foundation
import UIKit
import FSCalendar

class HistoryDetailViewController: UIViewController {
    
    // IBOutlet
    @IBOutlet weak var pillDosageTableHight: NSLayoutConstraint!
    @IBOutlet var tableView: UITableView!
    @IBOutlet weak var fsCalendar: FSCalendar!
    @IBOutlet weak var datesRangeLabel: UILabel!
    @IBOutlet weak var fsCalendarHeaderLabel: UILabel!
    @IBOutlet weak var fsCalendarStackView: UIView!
    @IBOutlet weak var fsCalendarHeader: UILabel!
    
    // fsCalendar variable
    private let gregorian = Calendar(identifier: .gregorian)
    private let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy년 MM월"
        return formatter
    }()
    let dayOfWeek = ["SUN", "MON", "TUE", "WED", "THR", "FRI", "SAT"]
    private var startDate: Date?
    private var endDate: Date?
    private var datesRange: [Date?]?
    private var currentPage: Date?
    
    // pill infomation variable
    private var result = [(String, Int, Int)]()
    
    // MARK: - LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        result = CoreDataManager.shared.fetchPillInformationLastWeek()
        setDelegate()
        setStyle()
        setFsCalendar()
        
    }
    
    // MARK: - private functions
    private func setDelegate() {
        tableView.delegate = self
        tableView.dataSource = self
        
        fsCalendar.delegate = self
        fsCalendar.dataSource = self
    }
    
    private func setStyle() {
        
        // HistoryDetailView style
        let nib = UINib(nibName: "HistoryDetailProgressViewCell", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: "HistoryDetailProgressViewCell")
        tableView.isScrollEnabled = false
        pillDosageTableHight.constant = CGFloat(25 + (result.count == 0 ? 1 : result.count) * 72)
        self.navigationController?.navigationBar.tintColor = .AColor.accent
        self.navigationItem.title = "한 눈에 보기"
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapRecognizer(_:)))
        datesRangeLabel.isUserInteractionEnabled = true
        datesRangeLabel.addGestureRecognizer(tapRecognizer)
        
        // fsCalendar style
        fsCalendarStackView.isHidden = true
        fsCalendarHeader.font = UIFont.AFont.calenderText
        let scopeGuesture = UIPanGestureRecognizer(target: fsCalendar, action: #selector(fsCalendar.handleScopeGesture(_:)))
        fsCalendar.addGestureRecognizer(scopeGuesture)
        
    }
    
    
    private func setFsCalendar() {
        // fsCalendar properties
        fsCalendar.allowsMultipleSelection = true
        fsCalendar.appearance.todayColor = UIColor.AColor.accent.withAlphaComponent(0.5)
        fsCalendar.appearance.weekdayFont = UIFont.AFont.calendarWeekDayFont
        fsCalendar.scrollEnabled = false
        fsCalendar.headerHeight = 0
        
        dayOfWeek.indices.forEach { index in
            fsCalendar.calendarWeekdayView.weekdayLabels[index].text = dayOfWeek[index]
        }
        
        fsCalendar.today = nil
        fsCalendar.register(DIYCalendarCell.self, forCellReuseIdentifier: "cell")
        fsCalendar.swipeToChooseGesture.isEnabled = true
        setCalendar()
    }
    
    @objc private func tapRecognizer(_ sender: UITapGestureRecognizer) {
        fsCalendarStackView.isHidden.toggle()
    }
    
    @IBAction func tapPrevButton(_ sender: Any) {
        scrollCurrentPage(isPrev: true)
        setCalendar()
    }
    
    @IBAction func tapNextButton(_ sender: Any) {
        scrollCurrentPage(isPrev: false)
        setCalendar()
    }
    
    private func scrollCurrentPage(isPrev: Bool) {
        let current = Calendar.current
        var dateComponents = DateComponents()
        dateComponents.month = isPrev ? -1 : 1
        
        self.currentPage = current.date(byAdding: dateComponents, to: self.currentPage ?? Date())
        self.fsCalendar.setCurrentPage(self.currentPage ?? Date(), animated: true)
    }
    
    private func setCalendar() {
        fsCalendar.scope = .month
        fsCalendarHeader.text = formatter.string(from: fsCalendar.currentPage)
    }
    
}

// MARK: - TableView delegate
extension HistoryDetailViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return result.isEmpty ? 1 : result.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "HistoryDetailProgressViewCell", for: indexPath) as! HistoryDetailProgressViewCell
        
        if result.count == 0 {
            cell.pillName.text = "아직 복용한 약이 없어요"
            cell.pillDosage.isHidden = true
            cell.pillRatio.isHidden = true
            cell.pillName.textColor = UIColor.AColor.gray
            
        } else {
            cell.pillName.text = result[indexPath.row].0
            cell.pillDosage.progress = Float(result[indexPath.row].1) / Float(result[indexPath.row].2)
            cell.pillRatio.text = result[indexPath.row].1 == 0 ? "" : String("\(result[indexPath.row].1) / \(result[indexPath.row].2)" )
        }
        
        return cell
    }
    
}

// MARK: - FSCalendar delegate
extension HistoryDetailViewController: FSCalendarDelegate, FSCalendarDataSource, FSCalendarDelegateAppearance {
 
    
    // MARK: fsCalendar delegate
    func calendar(_ calendar: FSCalendar, cellFor date: Date, at position: FSCalendarMonthPosition) -> FSCalendarCell {
        let cell = calendar.dequeueReusableCell(withIdentifier: "cell", for: date, at: position)
        return cell
    }
    
    func calendar(_ calendar: FSCalendar, willDisplay cell: FSCalendarCell, for date: Date, at position: FSCalendarMonthPosition) {
        self.configure(cell: cell, for: date, at: position)
    }
    
    func calendar(_ calendar: FSCalendar, boundingRectWillChange bounds: CGRect, animated: Bool) {
        self.fsCalendar.frame.size.height = bounds.height
    }
    
    func calendar(_ calendar: FSCalendar, shouldSelect date: Date, at monthPosition: FSCalendarMonthPosition)   -> Bool {
        return monthPosition == .current
    }
    
    func calendar(_ calendar: FSCalendar, shouldDeselect date: Date, at monthPosition: FSCalendarMonthPosition) -> Bool {
        return monthPosition == .current
    }
    
    func calendar(_ calendar: FSCalendar, didSelect date: Date, at monthPosition: FSCalendarMonthPosition) {
        
        if startDate == nil {
            startDate = date
            datesRange = [startDate!]
            self.configureVisibleCells()
            return
        }
        if startDate != nil && endDate == nil {
            if date <= startDate! {
                fsCalendar.deselect(startDate!)
                startDate = date
                datesRange = [startDate!]
                self.configureVisibleCells()
                return
            }
            
            let range = datesRange(from: startDate!, to: date)
            endDate = range.last
            range.forEach { date in
                fsCalendar.select(date)
            }
            
            datesRange = range
            self.configureVisibleCells()
            return
        }
        
        if startDate != nil && endDate != nil {
            fsCalendar.selectedDates.forEach { date in
                fsCalendar.deselect(date)
            }
            startDate = nil
            endDate = nil
            datesRange = []
        }
        
        self.configureVisibleCells()
    }
    
    func calendar(_ calendar: FSCalendar, didDeselect date: Date) {
        
        if startDate != nil && endDate != nil {
            fsCalendar.selectedDates.forEach { date in
                fsCalendar.deselect(date)
            }
            
            startDate = nil
            endDate = nil
            datesRange = []
        }
        
        self.configureVisibleCells()
    }
    
    func calendar(_ calendar: FSCalendar, appearance: FSCalendarAppearance, eventDefaultColorsFor date: Date) -> [UIColor]? {
        if self.gregorian.isDateInToday(date) {
            return [UIColor.orange]
        }
        return [appearance.eventDefaultColor]
    }
    
    private func configureVisibleCells() {
        fsCalendar.visibleCells().forEach { cell in
            let date = fsCalendar.date(for: cell)
            let position = fsCalendar.monthPosition(for: cell)
            self.configure(cell: cell, for: date!, at: position)
        }
    }
    
    private func configure(cell: FSCalendarCell, for date: Date, at position: FSCalendarMonthPosition) {
        let diyCell = cell as! DIYCalendarCell
        diyCell.circleImageView.isHighlighted = !self.gregorian.isDateInToday(date)
        if position == .current {
            var selectionType = SelectionType.none
            
            if fsCalendar.selectedDates.contains(date) {
                let previousDate = self.gregorian.date(byAdding: .day, value: -1, to: date)!
                let nextDate = self.gregorian.date(byAdding: .day, value: 1, to: date)!
                if fsCalendar.selectedDates.contains(date) {
                    if fsCalendar.selectedDates.contains(previousDate) && fsCalendar.selectedDates.contains(nextDate) {
                        selectionType = .range
                    } else if fsCalendar.selectedDates.contains(previousDate) && fsCalendar.selectedDates.contains(date) {
                        selectionType = .end
                    } else if fsCalendar.selectedDates.contains(nextDate) {
                        selectionType = .start
                    } else {
                        selectionType = .single
                    }
                }
            } else {
                selectionType = .none
            }
            
            if selectionType == .none {
                diyCell.selectionLayer.isHidden = true
                return
            }
            diyCell.selectionLayer.isHidden = false
            diyCell.selectionType = selectionType
        } else {
            diyCell.circleImageView.isHidden = true
            diyCell.selectionLayer.isHidden = true
        }
    }
    
    private func datesRange(from: Date, to: Date) -> [Date] {
        if from > to { return [Date]() }
        var tempDate = from
        var array = [tempDate]
        while tempDate < to {
            tempDate = Calendar.current.date(byAdding: .day, value: 1, to: tempDate)!
            array.append(tempDate)
        }
        return array
    }
    
    internal func maximumDate(for calendar: FSCalendar) -> Date {
        Date()
    }
}

