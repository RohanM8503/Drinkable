//
//  DrinkDetailView.swift
//  Drinkable
//
//  Created by Rohan Malhotra on 7/9/24.
//

import SwiftUI

struct DrinkDetailView: View {
    var drinkName: String
    var recipe: String
    var ingredients: [String]

    var body: some View {
        VStack {
            Text(drinkName)
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top, 40)
                .padding(.bottom, 20)

            Text("Ingredients:")
                .font(.headline)
                .padding(.bottom, 5)

            ForEach(ingredients, id: \.self) { ingredient in
                Text(ingredient)
                    .font(.body)
                    .padding(.bottom, 2)
            }

            Text("Instructions:")
                .font(.headline)
                .padding(.top, 20)
                .padding(.bottom, 5)

            Text(recipe)
                .font(.body)
                .padding()

            Spacer()
        }
        .padding()
        .background(Color.cream.ignoresSafeArea())
        .navigationTitle(drinkName)
    }
}

