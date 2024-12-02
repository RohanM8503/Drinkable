//
//  IngredientsView.swift
//  Drinkable
//
//  Created by Rohan Malhotra on 7/9/24.
//

import SwiftUI

struct IngredientsView: View {
    @State private var recognizedItems: [String]
    @State private var newItem: String = ""
    @State private var isEditing = false

    init(recognizedItems: [String]) {
        _recognizedItems = State(initialValue: recognizedItems)
    }

    var body: some View {
        VStack {
            Text("Ingredients")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top, 40)
                .padding(.bottom, 20)

            List {
                ForEach(recognizedItems.indices, id: \.self) { index in
                    HStack {
                        if isEditing {
                            TextField("Ingredient", text: $recognizedItems[index])
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        } else {
                            Text(recognizedItems[index])
                        }
                    }
                }
                .onDelete(perform: deleteItems)
                .onMove(perform: moveItems)

                HStack {
                    TextField("Add new ingredient", text: $newItem)
                    Button(action: addItem) {
                        Image(systemName: "plus")
                    }
                }
            }
            .padding()
            .toolbar {
                EditButton()
            }

            NavigationLink(destination: DrinksView(recognizedItems: recognizedItems)) {
                Text("Find Possible Drinks")
                    .font(.headline)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .padding(.bottom, 20)
            }
        }
        .padding()
        .background(Color.cream.ignoresSafeArea())
        .navigationTitle("Ingredients")
        .onAppear {
            isEditing = false
        }
    }

    private func deleteItems(at offsets: IndexSet) {
        recognizedItems.remove(atOffsets: offsets)
    }

    private func moveItems(from source: IndexSet, to destination: Int) {
        recognizedItems.move(fromOffsets: source, toOffset: destination)
    }

    private func addItem() {
        guard !newItem.isEmpty else { return }
        recognizedItems.append(newItem)
        newItem = ""
    }
}
