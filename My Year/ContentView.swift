//
//  ContentView.swift
//  My Year
//
//  Created by Mykhaylo Tymofyeyev  on 13/01/25.
//

import SwiftUI

struct ContentView: View {
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
                        Text("Yearlit").font(.headline).foregroundColor(Color("text-primary"))
                    }
                }
                .background(Color("surface-muted"))
        }
        .onAppear {
            NSLog("ContentView appeared")
        }
    }
}

#Preview {
    ContentView()
}
