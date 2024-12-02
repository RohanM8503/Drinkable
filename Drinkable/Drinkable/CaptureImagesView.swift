//
//  CaptureImagesView.swift
//  Drinkable
//
//  Created by Rohan Malhotra on 7/9/24.
//

import SwiftUI

struct CaptureImagesView: View {
    @State private var showFridgeCamera = false
    @State private var showBarCamera = false
    @State private var fridgeImage: UIImage? = UIImage(named: "placeholder")
    @State private var barImage: UIImage? = UIImage(named: "placeholder")
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var recognizedItems: [String] = []
    @State private var cocktailIngredients: [String] = []
    @State private var isLoading = false
    
    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 20) {
                VStack {
                    Button(action: {
                        if UIImagePickerController.isSourceTypeAvailable(.camera) {
                            showFridgeCamera = true
                        } else {
                            alertMessage = "Camera not available"
                            showAlert = true
                        }
                    }) {
                        Text("Take Picture of Fridge")
                            .fontWeight(.medium)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.lightGrey)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .sheet(isPresented: $showFridgeCamera) {
                        ImagePicker(sourceType: .camera, selectedImage: $fridgeImage, completion: processFridgeImage)
                    }
                    if fridgeImage != UIImage(named: "placeholder") {
                        Image(uiImage: fridgeImage!)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 150, height: 150)
                            .cornerRadius(10)
                            .shadow(radius: 5)
                            .padding(.top, 10)
                        Button(action: {
                            fridgeImage = UIImage(named: "placeholder")
                        }) {
                            Text("Remove Fridge Image")
                                .fontWeight(.medium)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.red)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                                .padding(.top, 10)
                        }
                    }
                }
                
                VStack {
                    Button(action: {
                        if UIImagePickerController.isSourceTypeAvailable(.camera) {
                            showBarCamera = true
                        } else {
                            alertMessage = "Camera not available"
                            showAlert = true
                        }
                    }) {
                        Text("Take Picture of Bar")
                            .fontWeight(.medium)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.babyBlue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .sheet(isPresented: $showBarCamera) {
                        ImagePicker(sourceType: .camera, selectedImage: $barImage, completion: processBarImage)
                    }
                    if barImage != UIImage(named: "placeholder") {
                        Image(uiImage: barImage!)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 150, height: 150)
                            .cornerRadius(10)
                            .shadow(radius: 5)
                            .padding(.top, 10)
                        Button(action: {
                            barImage = UIImage(named: "placeholder")
                        }) {
                            Text("Remove Bar Image")
                                .fontWeight(.medium)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.red)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                                .padding(.top, 10)
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            
            Spacer()
            
            if isLoading {
                ProgressView("Loading...")
            } else {
                NavigationLink(destination: IngredientsView(recognizedItems: recognizedItems)) {
                    Text("Next")
                        .font(.headline)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding(.bottom, 20)
                        .disabled(isLoading || recognizedItems.isEmpty)
                }
            }
            
            Image("bar")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity, maxHeight: 400)
                .padding(.bottom, 10)
        }
        .padding()
        .background(Color.cream.ignoresSafeArea())
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
        .navigationTitle("Capture Ingredients")
        .onAppear {
            fetchCocktailIngredients { ingredients in
                self.cocktailIngredients = ingredients
            }
        }
    }
    
    func processFridgeImage(_ image: UIImage?) {
            guard let image = image else { return }
            isLoading = true
            sendImageToGoogleVision(image: image) { recognizedItems in
                DispatchQueue.main.async {
                    self.sendRecognizedItemsToBackend(recognizedItems: recognizedItems, cocktailIngredients: cocktailIngredients)
                    print("Recognized Items from Fridge: \(recognizedItems)")
                }
            }
        }

    func processBarImage(_ image: UIImage?) {
        guard let image = image else { return }
        isLoading = true
        sendImageToAlcoholAPI(image: image) { recognizedItems in
            DispatchQueue.main.async {
                self.sendRecognizedItemsToBackend(recognizedItems: recognizedItems, cocktailIngredients: cocktailIngredients)
                print("Recognized Items from Bar: \(recognizedItems)")
            }
        }
    }

    func sendImageToAlcoholAPI(image: UIImage, completion: @escaping ([String]) -> Void) {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else { return }

        let url = URL(string: "https://alcohol-label-recognition.p.rapidapi.com/v1/results")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("afa4cdf2f6msh633d88ded36a950p126ea0jsne06fad7138f5", forHTTPHeaderField: "X-RapidAPI-Key")
        request.addValue("alcohol-label-recognition.p.rapidapi.com", forHTTPHeaderField: "X-RapidAPI-Host")

        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"image\"; filename=\"image.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = body

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print("Error: \(error?.localizedDescription ?? "Unknown error")")
                completion([])
                return
            }

            if let jsonString = String(data: data, encoding: .utf8) {
                print("Full response from Alcohol API: \(jsonString)")
            }

            do {
                if let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let results = jsonResponse["results"] as? [[String: Any]],
                   let firstResult = results.first,
                   let entities = firstResult["entities"] as? [[String: Any]] {

                    var recognizedItems: [String] = []

                    for entity in entities {
                        if let array = entity["array"] as? [[String: Any]] {
                            for item in array {
                                if let drink = item["drink"] as? String {
                                    recognizedItems.append(drink)
                                }
                            }
                        }
                    }

                    print("Raw recognized items from Alcohol API: \(recognizedItems)")
                    completion(recognizedItems)
                } else {
                    completion([])
                }
            } catch {
                print("Error parsing response: \(error.localizedDescription)")
                completion([])
            }
        }

        task.resume()
    }


    func sendImageToGoogleVision(image: UIImage, completion: @escaping ([String]) -> Void) {
        guard let base64Image = imageToBase64(image: image) else { return }

        let url = URL(string: "https://vision.googleapis.com/v1/images:annotate?key=AIzaSyCRNEdblbGWgAz_u0ss-MTkRzpzPg91SFA")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let requestBody: [String: Any] = [
            "requests": [
                [
                    "image": ["content": base64Image],
                    "features": [["type": "LABEL_DETECTION", "maxResults": 10]]
                ]
            ]
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: requestBody, options: [])

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print("Error: \(error?.localizedDescription ?? "Unknown error")")
                completion([])
                return
            }

            do {
                if let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let responses = jsonResponse["responses"] as? [[String: Any]],
                   let labels = responses.first?["labelAnnotations"] as? [[String: Any]] {

                    let recognizedItems = labels.compactMap { $0["description"] as? String }
                    print("Raw recognized items from Google Vision: \(recognizedItems)")
                    completion(recognizedItems)
                } else {
                    completion([])
                }
            } catch {
                print("Error parsing response: \(error.localizedDescription)")
                completion([])
            }
        }

        task.resume()
    }

    struct IngredientsResponse: Codable {
        let drinks: [Ingredient]
    }

    struct Ingredient: Codable {
        let strIngredient1: String
    }

    func fetchCocktailIngredients(completion: @escaping ([String]) -> Void) {
        let url = URL(string: "https://www.thecocktaildb.com/api/json/v1/1/list.php?i=list")!
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                print("Failed to fetch data: \(error?.localizedDescription ?? "Unknown error")")
                completion([])
                return
            }
            
            do {
                let decoder = JSONDecoder()
                let response = try decoder.decode(IngredientsResponse.self, from: data)
                let ingredients = response.drinks.map { $0.strIngredient1 }
                print("Cocktail Ingredients: \(ingredients)")
                completion(Array(Set(ingredients))) // Remove duplicates
            } catch {
                print("Error decoding response: \(error)")
                completion([])
            }
        }.resume()
    }
    
    func imageToBase64(image: UIImage) -> String? {
        guard let imageData = image.pngData() else { return nil }
        return imageData.base64EncodedString(options: .endLineWithCarriageReturn)
    }
    
    func sendRecognizedItemsToBackend(recognizedItems: [String], cocktailIngredients: [String]) {
        guard let url = URL(string: "http://172.20.10.2:4000/map-ingredients") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody: [String: Any] = [
            "ingredients": recognizedItems,
            "cocktailIngredients": cocktailIngredients
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: requestBody, options: [])

        print("Sending recognized items to backend: \(recognizedItems)")
        print("Cocktail ingredients: \(cocktailIngredients)")
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print("Error: \(error?.localizedDescription ?? "Unknown error")")
                self.isLoading = false
                return
            }
            
            do {
                if let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let mappedIngredientsArray = jsonResponse["mappedIngredients"] as? [String] {
                    DispatchQueue.main.async {
                        self.recognizedItems = Array(Set(mappedIngredientsArray)) // Remove duplicates
                        print("Mapped Ingredients: \(self.recognizedItems)")
                        self.isLoading = false
                    }
                } else {
                    print("Unexpected response format: \(String(data: data, encoding: .utf8) ?? "Unknown format")")
                    self.isLoading = false
                }
            } catch {
                print("Error parsing response: \(error.localizedDescription)")
                self.isLoading = false
            }
        }
        
        task.resume()
    }
}

extension Data {
    mutating func append(_ string: String, using encoding: String.Encoding = .utf8) {
        if let data = string.data(using: encoding) {
            append(data)
        }
    }
}
