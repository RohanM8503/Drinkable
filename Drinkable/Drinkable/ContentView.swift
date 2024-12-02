//
//  ContentView.swift
//  Drinkable
//
//  Created by Rohan Malhotra on 7/9/24.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationView {
            VStack {
                Spacer()
                
                Text("Welcome to Drinkable...")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.babyBlue)
                    .padding(.bottom, 50)
                
                NavigationLink(destination: CaptureImagesView()) {
                    Text("Start")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.babyBlue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding(.horizontal, 20)
                }
                
                Spacer()
            }
            .background(Color.cream.ignoresSafeArea())
        }
    }
}

#Preview {
    ContentView()
}
