//
//  DrinksView.swift
//  Drinkable
//
//  Created by Rohan Malhotra on 7/9/24.
//

import SwiftUI

struct DrinksView: View {
    @State private var recognizedItems: [String]
    @State private var possibleDrinks: [String] = []
    @State private var recipes: [String: Cocktail] = [:]
    @State private var isLoading = false
    
    init(recognizedItems: [String]) {
        _recognizedItems = State(initialValue: recognizedItems)
    }
    
    var body: some View {
        VStack {
            Text("Possible Drinks")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top, 40)
                .padding(.bottom, 20)
            
            if isLoading {
                ProgressView("Loading...")
            } else {
                List(possibleDrinks, id: \.self) { drink in
                    NavigationLink(destination: DrinkDetailView(drinkName: drink, recipe: recipes[drink]?.instructions ?? "", ingredients: recipes[drink]?.ingredients ?? [])) {
                        Text(drink)
                    }
                }
                .padding()
            }
            
            Spacer()
        }
        .padding()
        .background(Color.cream.ignoresSafeArea())
        .navigationTitle("Possible Drinks")
        .onAppear(perform: fetchPossibleDrinks)
    }
    
    struct CocktailsResponse: Decodable {
        let cocktails: [String: Cocktail]
    }
    
    struct Cocktail: Decodable {
        let ingredients: [String]
        let instructions: String
    }
    
    private func fetchPossibleDrinks() {
        guard let url = URL(string: "http://192.168.4.57:4000/generate-cocktails") else {
            print("Invalid URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let requestBody: [String: Any] = ["mappedIngredients": recognizedItems]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: requestBody, options: [])
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print("Failed to fetch data: \(error?.localizedDescription ?? "Unknown error")")
                DispatchQueue.main.async {
                    self.isLoading = false
                }
                return
            }
            
            do {
                // Add a check to ensure the response data is a valid JSON
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("Raw JSON response: \(jsonString)")
                }
                
                let response = try JSONDecoder().decode(CocktailsResponse.self, from: data)
                DispatchQueue.main.async {
                    self.possibleDrinks = Array(response.cocktails.keys.prefix(10)) // Limit to 10 drinks
                    self.recipes = response.cocktails
                    self.isLoading = false
                    print("Possible drinks: \(self.possibleDrinks)")
                }
            } catch {
                print("Failed to decode response: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.isLoading = false
                }
            }
        }.resume()
    }
}
