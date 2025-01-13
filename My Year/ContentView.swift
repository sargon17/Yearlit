//
//  ContentView.swift
//  My Year
//
//  Created by Mykhaylo Tymofyeyev  on 13/01/25.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            YearGrid()
        }.background(Color("surface-muted"))
    }
}

#Preview {
    ContentView()
}
