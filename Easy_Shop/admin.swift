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
import PhotosUI

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
    @State private var selectedImageData: Data? = nil
    @State private var showImagePicker = false
    
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
                    
                    Button(action: {
                        showImagePicker = true
                    }) {
                        Text(selectedImageData == nil ? "Select Image" : "Change Image")
                            .font(.title3)
                            .foregroundColor(.blue)
                            .padding(.vertical, 10)
                    }
                    
                    if let imageData = selectedImageData, let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 200)
                            .cornerRadius(10)
                    }

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
                            .padding(.horizontal, 13.0)
                            .background(isEditing ? Color.orange : Color.green)
                            .cornerRadius(10)
                    }
                    .disabled(newProduct.name.isEmpty || newProduct.price <= 0 || selectedImageData == nil)
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
                            Text(product.name + "\nPrice: \(String(product.price)) $")
                                .padding(.horizontal, 35.0)
                                .background(Color.pink.opacity(0.1))
                                .cornerRadius(5.0)

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
                    Button(action: logout) {
                        Text("Logout")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding(.horizontal, 13.0)
                            .background(Color.purple)
                            .cornerRadius(10)
                    }
                    .padding()
                    
                    NavigationLink(destination: ProductGridView()) {
                        Text("Products")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding(.horizontal, 13.0)
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                    .padding()
                }

                NavigationLink(destination: SignupPage(), isActive: $isLoggedOut) {
                    EmptyView()
                }
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(data: $selectedImageData)
            }
            .onAppear {
                loadProducts()
            }
        }
    }

    // Functions

    func addProduct() {
        guard let imageData = selectedImageData else {
            errorMessage = "Please select an image."
            return
        }

        let storageRef = storage.reference().child("iOS_project/\(UUID().uuidString).jpg")
        storageRef.putData(imageData, metadata: nil) { metadata, error in
            if let error = error {
                errorMessage = "Image upload failed: \(error.localizedDescription)"
                return
            }

            storageRef.downloadURL { url, error in
                if let error = error {
                    errorMessage = "Failed to get image URL: \(error.localizedDescription)"
                    return
                }

                guard let imageUrl = url?.absoluteString else { return }
                newProduct.image = imageUrl
                saveProductData()
            }
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
                errorMessage = "Product added successfully!"
                newProduct = Product(id: UUID().uuidString, name: "", description: "", price: 0, image: "")
                selectedImageData = nil // Clear selected image
                loadProducts()
            }
        }
    }

//----------
    
    func updateProduct() {
        if let imageData = selectedImageData {
            // Delete old image from storage if it exists
            if !newProduct.image.isEmpty {
                let oldImageRef = storage.reference(forURL: newProduct.image)
                oldImageRef.delete { error in
                    if let error = error {
                        print("Error deleting old image: \(error.localizedDescription)")
                    } else {
                        print("Old image deleted successfully.")
                    }
                }
            }

            // Upload the new image
            let storageRef = storage.reference().child("iOS_project/\(UUID().uuidString).jpg")
            storageRef.putData(imageData, metadata: nil) { metadata, error in
                if let error = error {
                    errorMessage = "Image upload failed: \(error.localizedDescription)"
                    return
                }

                storageRef.downloadURL { url, error in
                    if let error = error {
                        errorMessage = "Failed to get image URL: \(error.localizedDescription)"
                        return
                    }

                    guard let newImageUrl = url?.absoluteString else { return }
                    newProduct.image = newImageUrl

                    // Update product data with the new image URL
                    performProductUpdate()
                }
            }
        } else {
            // No new image selected, proceed to update other details
            performProductUpdate()
        }
    }

    func performProductUpdate() {
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
                errorMessage = "Product updated successfully!"
                isEditing = false
                newProduct = Product(id: UUID().uuidString, name: "", description: "", price: 0, image: "")
                selectedImageData = nil
                loadProducts()
            }
        }
    }






    func editProduct(_ product: Product) {
        // Assign the selected product to `newProduct` for editing
        newProduct = Product(
            id: product.id,
            name: product.name,
            description: product.description,
            price: product.price,
            image: product.image
        )
        isEditing = true
        errorMessage = "" // Clear any previous error messages

        // Load the existing image into selectedImageData for preview
        if !product.image.isEmpty, let url = URL(string: product.image) {
            DispatchQueue.global().async {
                if let data = try? Data(contentsOf: url) {
                    DispatchQueue.main.async {
                        selectedImageData = data
                    }
                }
            }
        }
    }

    
//    -------


    func deleteProduct(_ product: Product) {
        if !product.image.isEmpty {
            let storageRef = storage.reference(forURL: product.image)
            storageRef.delete { error in
                if let error = error {
                    errorMessage = "Error deleting product image: \(error.localizedDescription)"
                } else {
                    db.collection("products").document(product.id).delete { error in
                        if let error = error {
                            errorMessage = "Error deleting product: \(error.localizedDescription)"
                        } else {
                            errorMessage = "Product deleted successfully!"
                            loadProducts()
                        }
                    }
                }
            }
        } else {
            db.collection("products").document(product.id).delete { error in
                if let error = error {
                    errorMessage = "Error deleting product: \(error.localizedDescription)"
                } else {
                    errorMessage = "Product deleted successfully!"
                    loadProducts()
                }
            }
        }
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

// Image Picker for selecting images from the device
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var data: Data?

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            guard let provider = results.first?.itemProvider, provider.canLoadObject(ofClass: UIImage.self) else { return }

            provider.loadObject(ofClass: UIImage.self) { image, _ in
                if let uiImage = image as? UIImage, let data = uiImage.jpegData(compressionQuality: 0.8) {
                    DispatchQueue.main.async {
                        self.parent.data = data
                    }
                }
            }
        }
    }
}
