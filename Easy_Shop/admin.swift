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
        AdminPage(loggedInUserEmail: .constant(nil))
    }
}

struct AdminPage: View, ImagePickerDelegate {
    @State private var products: [Product] = []
    @State private var newProduct = Product(id: UUID().uuidString, name: "", description: "", price: 0, image: "")
    @State private var isEditing = false
    @State private var errorMessage = ""
    @State private var isLoggedOut = false
    @State private var selectedImageData: Data? = nil
    @State private var showImagePicker = false
    @State private var orders: [Order] = []
    @Binding var loggedInUserEmail: String?
    
    // Required for ImagePickerDelegate
    private let delegateHelper = DelegateHelper()

    let db = Firestore.firestore()
    let storage = Storage.storage()

    // Add this initializer
    init(loggedInUserEmail: Binding<String?>) {
        self._loggedInUserEmail = loggedInUserEmail
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Admin Panel")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(
                        LinearGradient(gradient: Gradient(colors: [Color.blue, Color.purple]),
                                     startPoint: .leading,
                                     endPoint: .trailing)
                    )
                    .foregroundColor(.white)
                    .cornerRadius(15)
                    .shadow(radius: 5)
                    .padding(.top)

                // Navigation Buttons
                VStack(spacing: 15) {
                    NavigationLink(destination: AddProductView(products: $products, errorMessage: $errorMessage, db: db, storage: storage)) {
                        AdminMenuButton(title: "Add New Product", icon: "plus.circle.fill", color: .green)
                    }

                    NavigationLink(destination: ViewProductsView(products: products, editProduct: editProduct, deleteProduct: deleteProduct)) {
                        AdminMenuButton(title: "View Products", icon: "list.bullet", color: .blue)
                    }

                    NavigationLink(destination: ViewOrdersView(orders: orders, deleteOrder: deleteOrder)) {
                        AdminMenuButton(title: "View Orders", icon: "cart.fill", color: .orange)
                    }
                }
                .padding()
                .onAppear {
                    loadProducts()
                    loadOrders()
                }

                Spacer()

                // Logout and Store View buttons
                HStack {
                    NavigationLink(destination: ProductGridView(loggedInUserEmail: $loggedInUserEmail).navigationBarBackButtonHidden(false)) {
                        AdminMenuButton(title: "Store", icon: "bag", color: .blue)
                    }
                    
                    Button(action: logout) {
                        AdminMenuButton(title: "Logout", icon: "arrow.right.square", color: .red)
                    }
                }
                .padding(.bottom)
            }
            .background(
                LinearGradient(gradient: Gradient(colors: [Color(.systemGray6), Color.white]),
                             startPoint: .top,
                             endPoint: .bottom)
                    .ignoresSafeArea()
            )
        }
    }

    func didSelectImage(_ image: UIImage) {
        if let imageData = image.jpegData(compressionQuality: 0.8) {
            self.selectedImageData = imageData
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
            if (!newProduct.image.isEmpty) {
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
        let productData: [String: Any] = [
            "name": product.name,
            "description": product.description,
            "price": product.price
        ]
        
        db.collection("products").document(product.id).updateData(productData) { error in
            if let error = error {
                errorMessage = "Error updating product: \(error.localizedDescription)"
            } else {
                errorMessage = "Product updated successfully!"
                loadProducts()
            }
        }
    }

    
//    -------


    func deleteProduct(_ product: Product) {
        if (!product.image.isEmpty) {
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

    func loadOrders() {
        db.collection("orders").getDocuments { snapshot, error in
            if let error = error {
                errorMessage = "Error loading orders: \(error.localizedDescription)"
            } else {
                orders = snapshot?.documents.compactMap { doc -> Order? in
                    let data = doc.data()
                    return Order(
                        id: doc.documentID,
                        name: data["name"] as? String ?? "", // Add name
                        mobileNumber: data["mobileNumber"] as? String ?? "",
                        address: data["address"] as? String ?? "",
                        email: data["email"] as? String ?? "",
                        paymentMethod: data["paymentMethod"] as? String ?? "", // Add payment method
                        products: (data["products"] as? [[String: Any]])?.compactMap { productData in
                            Product(
                                id: productData["id"] as? String ?? "",
                                name: productData["name"] as? String ?? "",
                                description: "",
                                price: productData["price"] as? Double ?? 0,
                                image: "",
                                quantity: productData["quantity"] as? Int ?? 1
                            )
                        } ?? [],
                        totalPrice: (data["products"] as? [[String: Any]])?.reduce(0) { $0 + (($1["price"] as? Double ?? 0) * Double($1["quantity"] as? Int ?? 1)) } ?? 0
                    )
                } ?? []
            }
        }
    }

    func deleteOrder(_ order: Order) {
        db.collection("orders").document(order.id).delete { error in
            if let error = error {
                errorMessage = "Error deleting order: \(error.localizedDescription)"
            } else {
                errorMessage = "Order deleted successfully!"
                loadOrders()
            }
        }
    }

    func logout() {
        do {
            try Auth.auth().signOut()
            loggedInUserEmail = nil
            isLoggedOut = true
        } catch {
            errorMessage = "Error logging out: \(error.localizedDescription)"
        }
    }
}

// Change the protocol definition to not require a class type
protocol ImagePickerDelegate {
    func didSelectImage(_ image: UIImage)
}

// Update DelegateHelper to use the protocol without AnyObject
class DelegateHelper: NSObject {
    var parent: ImagePickerDelegate?
}

// Image Picker for selecting images from the device
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var data: Data?
    let delegate: DelegateHelper?  // Change to let since we won't modify it

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
                        self.parent.delegate?.parent?.didSelectImage(uiImage)
                    }
                }
            }
        }
    }
}

// Order Model
struct Order: Identifiable {
    var id: String
    var name: String // Add name
    var mobileNumber: String
    var address: String
    var email: String
    var paymentMethod: String // Add payment method
    var products: [Product]
    var totalPrice: Double
}

// Add these supporting views
struct ProductListView: View {
    let products: [Product]
    let editProduct: (Product) -> Void
    let deleteProduct: (Product) -> Void
    
    var body: some View {
        List {
            ForEach(products) { product in
                VStack(alignment: .leading, spacing: 8) {
                    Text(product.name)
                        .font(.headline)
                    Text("Price: $\(String(format: "%.2f", product.price))")
                        .foregroundColor(.green)
                    
                    HStack {
                        Spacer()
                        Button(action: { editProduct(product) }) {
                            Text("Edit")
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.blue.opacity(0.2))
                                .cornerRadius(8)
                        }
                        
                        Button(action: { deleteProduct(product) }) {
                            Text("Delete")
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.red.opacity(0.2))
                                .cornerRadius(8)
                        }
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(10)
                .shadow(radius: 2)
            }
        }
    }
}

struct OrderListView: View {
    let orders: [Order]
    let deleteOrder: (Order) -> Void
    
    var body: some View {
        List {
            ForEach(orders) { order in
                VStack(alignment: .leading, spacing: 8) {
                    Text("Order #\(order.id)")
                        .font(.headline)
                        .foregroundColor(.purple)
                    Group {
                        Text("Customer: \(order.name)")
                        Text("Contact: \(order.mobileNumber)")
                        Text("Address: \(order.address)")
                        Text("Payment: \(order.paymentMethod)")
                    }
                    .font(.subheadline)
                    
                    Divider()
                    
                    ForEach(order.products) { product in
                        HStack {
                            Text(product.name)
                            Spacer()
                            Text("$\(product.price, specifier: "%.2f") x \(product.quantity)")
                        }
                    }
                    
                    Text("Total: $\(order.totalPrice, specifier: "%.2f")")
                        .font(.headline)
                        .foregroundColor(.green)
                        .padding(.top, 5)
                    
                    Button(action: { deleteOrder(order) }) {
                        Text("Delete Order")
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.red)
                            .cornerRadius(8)
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(10)
                .shadow(radius: 2)
            }
        }
    }
}

// Helper Views
struct AdminMenuButton: View {
    let title: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
            Text(title)
        }
        .font(.headline)
        .foregroundColor(.white)
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.gradient)
        .cornerRadius(10)
        .shadow(radius: 3)
    }
}

// Add Product View
struct AddProductView: View, ImagePickerDelegate {
    @Binding var products: [Product]
    @Binding var errorMessage: String
    let db: Firestore
    let storage: Storage
    
    @State private var newProduct = Product(id: UUID().uuidString, name: "", description: "", price: 0, image: "")
    @State private var selectedImageData: Data? = nil
    @State private var showImagePicker = false
    private let delegateHelper = DelegateHelper()
    
    var body: some View {
        Form {
            Section(header: Text("Product Details").foregroundColor(.purple)) {
                TextField("Product Name", text: $newProduct.name)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                TextField("Description", text: $newProduct.description)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                TextField("Price", value: $newProduct.price, format: .number)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Button(action: { showImagePicker = true }) {
                    HStack {
                        Image(systemName: "photo")
                        Text(selectedImageData == nil ? "Select Image" : "Change Image")
                    }
                    .foregroundColor(.blue)
                }
                
                if let imageData = selectedImageData, let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 200)
                        .cornerRadius(10)
                }
                
                Button(action: addProduct) {
                    Text("Add Product")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green.gradient)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .disabled(newProduct.name.isEmpty || newProduct.price <= 0 || selectedImageData == nil)
            }
        }
        .navigationTitle("Add Product")
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(data: $selectedImageData, delegate: delegateHelper)
        }
    }
    
    func didSelectImage(_ image: UIImage) {
        if let imageData = image.jpegData(compressionQuality: 0.8) {
            self.selectedImageData = imageData
        }
    }
    
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
                selectedImageData = nil
            }
        }
    }
}

// Update ViewProductsView to handle edit navigation
struct ViewProductsView: View {
    let products: [Product]
    let editProduct: (Product) -> Void
    let deleteProduct: (Product) -> Void
    @State private var selectedProduct: Product? = nil
    @State private var showingEditSheet = false
    @State private var editedName = ""
    @State private var editedDescription = ""
    @State private var editedPrice = 0.0
    
    var body: some View {
        ScrollView {
            VStack(spacing: 15) {
                if products.isEmpty {
                    Text("No products available")
                        .foregroundColor(.gray)
                        .padding()
                } else {
                    ForEach(products) { product in
                        ProductCardView(
                            product: product,
                            editProduct: { product in
                                selectedProduct = product
                                editedName = product.name
                                editedDescription = product.description
                                editedPrice = product.price
                                showingEditSheet = true
                            },
                            deleteProduct: deleteProduct
                        )
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Products")
        .sheet(isPresented: $showingEditSheet) {
            NavigationView {
                Form {
                    Section(header: Text("Edit Product Details")) {
                        VStack(alignment: .leading) {
                            Text("Product Name")
                                .font(.caption)
                                .foregroundColor(.gray)
                            TextField("Enter product name", text: $editedName)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        
                        VStack(alignment: .leading) {
                            Text("Description")
                                .font(.caption)
                                .foregroundColor(.gray)
                            TextField("Enter product description", text: $editedDescription)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        
                        VStack(alignment: .leading) {
                            Text("Price")
                                .font(.caption)
                                .foregroundColor(.gray)
                            TextField("Enter price", value: $editedPrice, format: .number)
                                .keyboardType(.decimalPad)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                    }
                }
                .navigationTitle("Edit Product")
                .navigationBarItems(
                    leading: Button("Cancel") {
                        showingEditSheet = false
                    },
                    trailing: Button("Save") {
                        if let product = selectedProduct {
                            let updatedProduct = Product(
                                id: product.id,
                                name: editedName,
                                description: editedDescription,
                                price: editedPrice,
                                image: product.image
                            )
                            editProduct(updatedProduct)
                            showingEditSheet = false
                        }
                    }
                    .disabled(editedName.isEmpty || editedDescription.isEmpty || editedPrice <= 0)
                )
            }
        }
    }
}

// Add EditProductView
struct EditProductView: View {
    let product: Product
    let onSave: (Product) -> Void
    
    @Environment(\.presentationMode) var presentationMode
    @State private var editedName: String
    @State private var editedDescription: String
    @State private var editedPrice: String
    @State private var showAlert = false
    
    init(product: Product, onSave: @escaping (Product) -> Void) {
        self.product = product
        self.onSave = onSave
        _editedName = State(initialValue: product.name)
        _editedDescription = State(initialValue: product.description)
        _editedPrice = State(initialValue: String(format: "%.2f", product.price))
    }
    
    var body: some View {
        Form {
            Section(header: Text("Edit Product Details")) {
                TextField("Name", text: $editedName)
                TextField("Description", text: $editedDescription)
                TextField("Price", text: $editedPrice)
                    .keyboardType(.decimalPad)
            }
            
            Section {
                Button("Save Changes") {
                    if let price = Double(editedPrice) {
                        let updatedProduct = Product(
                            id: product.id,
                            name: editedName,
                            description: editedDescription,
                            price: price,
                            image: product.image
                        )
                        onSave(updatedProduct)
                    }
                }
                .disabled(editedName.isEmpty || editedDescription.isEmpty || editedPrice.isEmpty)
                
                Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
                .foregroundColor(.red)
            }
        }
        .navigationTitle("Edit Product")
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("Success"),
                message: Text("Product updated successfully"),
                dismissButton: .default(Text("OK")) {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
}

// Update ProductCardView
struct ProductCardView: View {
    let product: Product
    let editProduct: (Product) -> Void
    let deleteProduct: (Product) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            AsyncImage(url: URL(string: product.image)) { image in
                image
                    .resizable()
                    .scaledToFit()
                    .frame(height: 150)
                    .cornerRadius(10)
            } placeholder: {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 150)
                    .cornerRadius(10)
            }
            
            Text(product.name)
                .font(.headline)
            
            Text(product.description)
                .font(.subheadline)
                .foregroundColor(.gray)
            
            Text("Price: $\(product.price, specifier: "%.2f")")
                .font(.title3)
                .foregroundColor(.green)
            
            HStack {
                Spacer()
                Button("Edit") {
                    editProduct(product)
                }
                .buttonStyle(.bordered)
                .tint(.blue)
                
                Button("Delete") {
                    deleteProduct(product)
                }
                .buttonStyle(.bordered)
                .tint(.red)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(15)
        .shadow(radius: 5)
    }
}

struct ViewOrdersView: View {
    let orders: [Order]
    let deleteOrder: (Order) -> Void
    
    var body: some View {
        ScrollView {
            VStack(spacing: 15) {
                if orders.isEmpty {
                    Text("No orders available")
                        .foregroundColor(.gray)
                        .padding()
                } else {
                    ForEach(orders) { order in
                        OrderCardView(order: order, deleteOrder: deleteOrder)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Orders")
    }
}

struct OrderCardView: View {
    let order: Order
    let deleteOrder: (Order) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Order #\(order.id)")
                .font(.headline)
                .foregroundColor(.purple)
            
            Group {
                Text("Customer: \(order.name)")
                Text("Contact: \(order.mobileNumber)")
                Text("Address: \(order.address)")
                Text("Email: \(order.email)")
                Text("Payment: \(order.paymentMethod)")
            }
            .font(.subheadline)
            
            Divider()
            
            Text("Products:")
                .font(.headline)
            
            ForEach(order.products) { product in
                HStack {
                    Text(product.name)
                    Spacer()
                    Text("$\(product.price, specifier: "%.2f") × \(product.quantity)")
                }
                .font(.subheadline)
            }
            
            Divider()
            
            HStack {
                Text("Total:")
                    .font(.headline)
                Spacer()
                Text("$\(order.totalPrice, specifier: "%.2f")")
                    .font(.title3)
                    .foregroundColor(.green)
            }
            
            Button(action: { deleteOrder(order) }) {
                HStack {
                    Spacer()
                    Image(systemName: "trash")
                    Text("Delete Order")
                    Spacer()
                }
                .foregroundColor(.white)
                .padding()
                .background(Color.red)
                .cornerRadius(10)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(15)
        .shadow(radius: 5)
    }
}
