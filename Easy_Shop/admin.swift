//
//  admin.swift
//  Easy_Shop
//
//  Created by Dibyo Sarkar on 8/1/25.
//

import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

// Preview Updates
struct ContentView_Preview: PreviewProvider {
    static var previews: some View {
        AdminPage()
    }
}

struct AdminPage: View {
    @State private var products: [Product] = []
    @State private var newProduct = Product(id: UUID().uuidString, name: "", description: "", price: 0, image: "")
    @State private var isEditing = false
    @State private var errorMessage = ""
    @State private var isLoggedOut = false
    let db = Firestore.firestore()
    let storage = Storage.storage()

    var body: some View {
        NavigationView {
            VStack {
                Text("Admin Panel")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.horizontal, 10.0)
                    .background(Color.green)
                    .cornerRadius(10)

                // Form to Add/Edit Product
                Form {
                    TextField("Product Name", text: $newProduct.name)
                    TextField("Description", text: $newProduct.description)
                    TextField("Price", value: $newProduct.price, format: .number)
                        .keyboardType(.decimalPad)
                    TextField("Image Name (Optional)", text: $newProduct.image)

                    Button(action: {
                        if isEditing {
                            updateProduct()
                        } else {
                            addProduct()
                        }
                    }) {
                        Text(isEditing ? "Update Product" : "Add Product")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding()
                            .background(isEditing ? Color.orange : Color.green)
                            .cornerRadius(10)
                    }
                    .disabled(newProduct.name.isEmpty || newProduct.price <= 0)
                }

                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                }

                // Product List with Edit/Delete Buttons
                List {
                    ForEach(products) { product in
                        HStack {
                            Text(product.name)
                            Spacer()
                            Button(action: {
                                editProduct(product)
                            }) {
                                Text("Edit")
                                    .padding(8)
                                    .background(Color.blue.opacity(0.1))
                                    .cornerRadius(8)
                            }
                            .buttonStyle(BorderlessButtonStyle())
                            
                            Button(action: {
                                deleteProduct(product)
                            }) {
                                Text("Delete")
                                    .padding(8)
                                    .background(Color.red.opacity(0.1))
                                    .cornerRadius(8)
                            }
                            .buttonStyle(BorderlessButtonStyle())
                        }
                        .padding(.vertical, 5)
                    }
                }

                // Logout and Products Button
                HStack {
                    // Logout Button
                    Button(action: logout) {
                        Text("Logout")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.purple)
                            .cornerRadius(10)
                    }
                    .padding()
                    
                    NavigationLink(destination: ProductGridView()) {
                        Text("Products")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                    .padding()
                }

                NavigationLink(destination: SignupPage(), isActive: $isLoggedOut) {
                    EmptyView()
                }
            }
            .onAppear {
                loadProducts()
            }
        }
    }

    // Functions
    func addProduct() {
        guard !newProduct.name.isEmpty, newProduct.price > 0 else {
            errorMessage = "Invalid product details."
            return
        }

        if !newProduct.image.isEmpty {
            let storageRef = storage.reference().child("images/\(newProduct.image)")
            storageRef.putData(Data(), metadata: nil) { _, error in
                if let error = error {
                    errorMessage = "Image upload failed: \(error.localizedDescription)"
                    saveProductData()
                    return
                }
                saveProductData()
            }
        } else {
            saveProductData()
        }
    }

    func saveProductData() {
        let productData: [String: Any] = [
            "id": newProduct.id,
            "name": newProduct.name,
            "description": newProduct.description,
            "price": newProduct.price,
            "image": newProduct.image
        ]

        db.collection("products").document(newProduct.id).setData(productData) { error in
            if let error = error {
                errorMessage = "Error adding product: \(error.localizedDescription)"
            } else {
                errorMessage = ""
                newProduct = Product(id: UUID().uuidString, name: "", description: "", price: 0, image: "")
                loadProducts()
            }
        }
    }

    func updateProduct() {
        let productData: [String: Any] = [
            "name": newProduct.name,
            "description": newProduct.description,
            "price": newProduct.price,
            "image": newProduct.image
        ]

        db.collection("products").document(newProduct.id).updateData(productData) { error in
            if let error = error {
                errorMessage = "Error updating product: \(error.localizedDescription)"
            } else {
                errorMessage = ""
                isEditing = false
                newProduct = Product(id: UUID().uuidString, name: "", description: "", price: 0, image: "")
                loadProducts()
            }
        }
    }

    func deleteProduct(_ product: Product) {
        db.collection("products").document(product.id).delete { error in
            if let error = error {
                errorMessage = "Error deleting product: \(error.localizedDescription)"
            } else {
                loadProducts()
            }
        }
    }

    func editProduct(_ product: Product) {
        newProduct = product
        isEditing = true
    }

    func loadProducts() {
        db.collection("products").getDocuments { snapshot, error in
            if let error = error {
                errorMessage = "Error loading products: \(error.localizedDescription)"
            } else {
                products = snapshot?.documents.compactMap { doc -> Product? in
                    let data = doc.data()
                    return Product(
                        id: doc.documentID,
                        name: data["name"] as? String ?? "",
                        description: data["description"] as? String ?? "",
                        price: data["price"] as? Double ?? 0,
                        image: data["image"] as? String ?? ""
                    )
                } ?? []
            }
        }
    }

    func logout() {
        do {
            try Auth.auth().signOut()
            isLoggedOut = true
        } catch {
            errorMessage = "Error logging out: \(error.localizedDescription)"
        }
    }
}
