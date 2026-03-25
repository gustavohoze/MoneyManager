//
//  MoneyGuardsWidgetBundle.swift
//  MoneyGuardsWidget
import WidgetKit
import SwiftUI

@main
struct MoneyGuardsWidgetBundle: WidgetBundle {
    var body: some Widget {
        FastCaptureWidget()
        if #available(iOS 18.0, *) {
            FastCaptureControl()
        }
    }
}
