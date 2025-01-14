//
//  ContentView.swift
//  My Year
//
//  Created by Mykhaylo Tymofyeyev  on 13/01/25.
//

import SwiftUI
import RevenueCat

struct ContentView: View {
    @State private var customerInfo: CustomerInfo?

    var body: some View {
        NavigationView {
            YearGrid()
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        NavigationLink(destination: CustomCalendarList()) {
                            Image(systemName: "list.bullet")
                        }
                    }

                    ToolbarItem(placement: .navigationBarLeading) {
                        if customerInfo?.entitlements["premium"]?.isActive ?? false {
                            HStack(spacing: 4) {
                                Text("Yearlit").font(.headline).foregroundColor(Color("text-primary"))
                                Image(systemName: "checkmark.seal.fill")
                                    .font(.caption)
                                    .foregroundColor(Color("mood-excellent"))
                                    .shadow(color: Color("mood-excellent").opacity(0.5), radius: 10)
                            }
                        } else {
                            Text("Yearlit").font(.headline).foregroundColor(Color("text-primary"))
                        }
                    }
                }
                .background(Color("surface-muted"))
        }
        .onAppear {
            Purchases.shared.getCustomerInfo { (customerInfo, error) in
                self.customerInfo = customerInfo
            }
        }
    }
}

#Preview {
    ContentView()
}
