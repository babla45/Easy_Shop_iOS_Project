import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

// Main entry point
@main
struct FirebaseLab3App: App {
    init() {
        // Initialize Firebase
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            bablaView()
        }
    }
}


// Admin Page with CRUD Operations
struct AdminPage: View {
    @State private var products: [Product] = []
    @State private var newProduct = Product(id: UUID().uuidString, name: "", description: "", price: 0, image: "")
    @State private var isEditing = false
    @State private var errorMessage = ""
    let db = Firestore.firestore()
    let storage = Storage.storage()

    var body: some View {
        VStack {
            Text("Admin Panel")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding()

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
                        .background(Color.green)
                        .cornerRadius(10)
                }
                .padding(.top)
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
                                .foregroundColor(.blue)
                        }
                        Button(action: {
                            deleteProduct(product)
                        }) {
                            Text("Delete")
                                .foregroundColor(.red)
                        }
                    }
                }
            }

            // Logout Button
            Button(action: logout) {
                Text("Logout")
                    .font(.title2)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.red)
                    .cornerRadius(10)
            }
            .padding()
        }
        .onAppear {
            loadProducts()
        }
    }

    func addProduct() {
        guard !newProduct.name.isEmpty, newProduct.price > 0 else {
            errorMessage = "Invalid product details."
            return
        }

        // Image upload logic if newProduct.image is provided
        if !newProduct.image.isEmpty {
            let storageRef = storage.reference().child("images/\(newProduct.image)")
            storageRef.putData(Data(), metadata: nil) { _, error in
                if let error = error {
                    errorMessage = "Image upload failed: \(error.localizedDescription)"
                    saveProductData() // Save product data even if image upload fails
                    return
                }

                // After uploading the image, save product details
                saveProductData()
            }
        } else {
            saveProductData() // Save product data directly if no image
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
                if error.localizedDescription.contains("Firestore API is not available for Firestore in Datastore Mode") {
                    errorMessage = "Firestore is in Datastore mode. Please switch to Native mode in the Firebase console."
                } else {
                    errorMessage = "Error adding product: \(error.localizedDescription)"
                }
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
                loadProducts() // Ensure the view is updated after deletion
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
        } catch {
            errorMessage = "Error logging out: \(error.localizedDescription)"
        }
    }
}



// Product Grid View with Firebase Data
struct ProductGridView: View {
    @State private var products: [Product] = []
    let db = Firestore.firestore()

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))]) {
                    ForEach(products) { product in
                        NavigationLink(destination: ProductDetailView(product: product)) {
                            VStack {
                                if !product.image.isEmpty {
                                    Image(systemName: product.image)
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(height: 100)
                                } else {
                                    Rectangle()
                                        .fill(Color.gray)
                                        .frame(height: 100)
                                }
                                Text(product.name)
                                    .font(.headline)
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Products")
            .onAppear {
                loadProducts()
            }
        }
    }

    func loadProducts() {
        db.collection("products").getDocuments { snapshot, error in
            if let error = error {
                print("Error loading products: \(error.localizedDescription)")
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
}


// Product Detail View
struct ProductDetailView: View {
    var product: Product

    var body: some View {
        VStack {
            if !product.image.isEmpty {
                Image(systemName: product.image) // Replace with actual image fetching if using Firebase Storage
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 200)
            }
            Text(product.name)
                .font(.title)
                .padding()

            Text(product.description)
                .font(.body)
                .padding()

            Text("$\(product.price, specifier: "%.2f")")
                .font(.title2)
                .foregroundColor(.green)
                .padding()

            Spacer()
        }
        .navigationTitle("Product Details")
        .padding()
    }
}


// Main Navigation Update
struct bablaView: View {
    @State private var loggedInUserEmail: String? = "admin@gmail.com"

    var body: some View {
        NavigationView {
            VStack {
                if let email = loggedInUserEmail {
                    if email == "admin@gmail.com" { // Admin account check
                        AdminPage()
                    } else {
                        ProductGridView()
                    }
                } else {
                    Text("Welcome to Easy Shop")
                        .font(.title)
                        .foregroundColor(.purple)

                    HStack {
                        NavigationLink(destination: LoginPage(loggedInUserEmail: $loggedInUserEmail)) {
                            Text("Login")
                                .font(.title2)
                                .fontWeight(.bold)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        .padding()

                        NavigationLink(destination: SignupPage()) {
                            Text("Signup")
                                .font(.title2)
                                .fontWeight(.bold)
                                .padding()
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        .padding()
                    }
                }
            }
            .padding()
        }
    }
}



// Mock Products for Preview
//let mockProducts: [Product] = [
//    Product(id: 1, name: "Sample Product 1", description: "This is a sample product.", price: 19.99, image: "iphone"),
//    Product(id: 2, name: "Sample Product 2", description: "This is another sample product.", price: 29.99, image: "macbook")
//]

// Preview Updates
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        bablaView()
    }
}




// Login page view
struct LoginPage: View {
    @Binding var loggedInUserEmail: String?
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var errorMessage: String = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Login to your account")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                TextField("Email", text: $email)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)

                SecureField("Password", text: $password)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)

                Button(action: login) {
                    Text("Login")
                        .padding()
                        .fontWeight(.bold)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.top, 20)

                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                }

                Spacer()
            }
            .padding()
        }
    }

    func login() {
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            if let error = error {
                errorMessage = error.localizedDescription
            } else if let user = Auth.auth().currentUser {
                // Successful login
                errorMessage = ""
                loggedInUserEmail = user.email
                print("User logged in successfully: \(user.email ?? "No Email")")
            }
        }
    }
}

// Product Model
struct Product: Identifiable {
    var id: String
    var name: String
    var description: String
    var price: Double
    var image: String
}


// Product List View




// Cart View
struct CartView: View {
    @Binding var cart: [Product]
    
    var body: some View {
        VStack {
            List {
                ForEach(cart) { product in
                    HStack {
                        Text(product.name)
                        Spacer()
                        Text("$\(product.price, specifier: "%.2f")")
                    }
                }
                .onDelete(perform: deleteProduct)
            }
            
            Spacer()
            
            Text("Total: $\(totalPrice(), specifier: "%.2f")")
                .font(.title)
                .padding()
            
            Button(action: {
                // Handle checkout action
            }) {
                Text("Proceed to Checkout")
                    .font(.title2)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.green)
                    .cornerRadius(10)
            }
            .padding(.bottom, 20)
        }
        .navigationTitle("Your Cart")
    }
    
    func totalPrice() -> Double {
        return cart.reduce(0) { $0 + $1.price }
    }
    
    func deleteProduct(at offsets: IndexSet) {
        cart.remove(atOffsets: offsets)
    }
}

// Sign up page view
struct SignupPage: View {
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var errorMessage: String = ""

    var body: some View {
        VStack(spacing: 20) {
            Text("Signup")
                .font(.largeTitle)
                .fontWeight(.bold)

            TextField("Email", text: $email)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)

            SecureField("Password", text: $password)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)

            SecureField("Confirm Password", text: $confirmPassword)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)

            Button(action: signup) {
                Text("Signup")
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.top, 20)

            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .foregroundColor(.red)
            }

            Spacer()
        }
        .padding()
    }

    func signup() {
        if password != confirmPassword {
            errorMessage = "Passwords do not match"
            return
        }

        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if let error = error {
                errorMessage = error.localizedDescription
            } else {
                errorMessage = "User signed up successfully.\nPlease go back and log in."
                print("User signed up successfully")
                    
            }
        }
    }
}

// Contentview preview
/*
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        LoginPage(loggedInUserEmail: .constant(nil))
    }
}
*/
