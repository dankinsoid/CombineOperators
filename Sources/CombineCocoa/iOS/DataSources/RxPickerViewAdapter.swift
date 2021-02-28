//
//  CombinePickerViewAdapter.swift
//  CombineCocoa
//
//  Created by Sergey Shulga on 12/07/2017.
//  Copyright © 2017 Krunoslav Zaher. All rights reserved.
//

#if os(iOS)

import UIKit
import Combine

@available(iOS 13.0, macOS 10.15, *)
class CombinePickerViewArrayDataSource<T>: NSObject, UIPickerViewDataSource, SectionedViewDataSourceType {
    fileprivate var items: [T] = []
    
    func model(at indexPath: IndexPath) throws -> Any {
        guard items.indices ~= indexPath.row else {
            throw CombineCocoaError.itemsNotYetBound(object: self)
        }
        return items[indexPath.row]
    }

    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        items.count
    }
}

@available(iOS 13.0, macOS 10.15, *)
class CombinePickerViewSequenceDataSource<Sequence: Swift.Sequence>
    : CombinePickerViewArrayDataSource<Sequence.Element>
    , CombinePickerViewDataSourceType {
    typealias Element = Sequence

    func pickerView(_ pickerView: UIPickerView, observed: Sequence) {
         _ = Binder(self) { dataSource, items in
            dataSource.items = items
            pickerView.reloadAllComponents()
        }
        .receive(Array(observed))
    }
}

@available(iOS 13.0, macOS 10.15, *)
final class CombineStringPickerViewAdapter<Sequence: Swift.Sequence>
    : CombinePickerViewSequenceDataSource<Sequence>
    , UIPickerViewDelegate {
    
    typealias TitleForRow = (Int, Sequence.Element) -> String?
    private let titleForRow: TitleForRow
    
    init(titleForRow: @escaping TitleForRow) {
        self.titleForRow = titleForRow
        super.init()
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        titleForRow(row, items[row])
    }
}

@available(iOS 13.0, macOS 10.15, *)
final class CombineAttributedStringPickerViewAdapter<Sequence: Swift.Sequence>: CombinePickerViewSequenceDataSource<Sequence>, UIPickerViewDelegate {
    typealias AttributedTitleForRow = (Int, Sequence.Element) -> NSAttributedString?
    private let attributedTitleForRow: AttributedTitleForRow
    
    init(attributedTitleForRow: @escaping AttributedTitleForRow) {
        self.attributedTitleForRow = attributedTitleForRow
        super.init()
    }
    
    func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
        attributedTitleForRow(row, items[row])
    }
}

@available(iOS 13.0, macOS 10.15, *)
final class CombinePickerViewAdapter<Sequence: Swift.Sequence>: CombinePickerViewSequenceDataSource<Sequence>, UIPickerViewDelegate {
    typealias ViewForRow = (Int, Sequence.Element, UIView?) -> UIView
    private let viewForRow: ViewForRow
    
    init(viewForRow: @escaping ViewForRow) {
        self.viewForRow = viewForRow
        super.init()
    }
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        viewForRow(row, items[row], view)
    }
}

#endif
