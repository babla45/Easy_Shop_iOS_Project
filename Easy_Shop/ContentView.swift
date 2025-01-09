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

// Product Model
struct Product: Identifiable {
    var id: String
    var name: String
    var description: String
    var price: Double
    var image: String // Firebase Storage URL
}

// Preview Updates
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        //bablaView()
        bablaView()
    }
}

// Main Navigation Update
struct bablaView: View {
    @State private var loggedInUserEmail: String? = nil

    var body: some View {
        NavigationStack {
            ZStack {
                // Background Image
                Image("front") // This refers to an image in your asset catalog
                    .resizable()
                    .scaledToFill()
                    .edgesIgnoringSafeArea(.all) // This makes the image cover the entire screen
                    .allowsHitTesting(false) // Ensures the background doesn't block interactions

                VStack {
                    if let email = loggedInUserEmail {
                        if email == "admin@gmail.com" { // Admin account check
                            AdminPage(loggedInUserEmail: $loggedInUserEmail)
                        } else {
                            ProductGridView(loggedInUserEmail: $loggedInUserEmail)
                        }
                    } else {
                        VStack {
                            // Welcome Image
                            Image("front") // Repeating the background image for a smaller part or another section
                                .frame(width: 400, height: 390) // Set the size of the image
                                .cornerRadius(10) // Optionally add rounded corners

                            Text("Welcome to Easy Shop\n Login to your account.")
                                .font(.title)
                                .padding()
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .background(.orange).opacity(0.78)
                                .cornerRadius(10)

                            HStack {
                                // Login Button
                                NavigationLink(destination: LoginPage(loggedInUserEmail: $loggedInUserEmail)) {
                                    Text("Login")
                                        .font(.title)
                                        .fontWeight(.bold)
                                        .padding(.horizontal, 30)
                                        .padding(.vertical, 10)
                                        .background(Color.blue)
                                        .foregroundColor(.white)
                                        .cornerRadius(10)
                                }
                                .padding()

                                // Signup Button
                                NavigationLink(destination: SignupPage()) {
                                    Text("Signup")
                                        .font(.title)
                                        .fontWeight(.bold)
                                        .padding(.horizontal, 30)
                                        .padding(.vertical, 10)
                                        .background(Color.green)
                                        .foregroundColor(.white)
                                        .cornerRadius(10)
                                }
                                .padding()
                            }
                        }
                        .padding() // Add padding to the content to prevent it from touching the screen edges
                    }
                }
            }
        }
    }
}

// Product Grid View with Firebase Data
struct ProductGridView: View {
    @State private var products: [Product] = []
    @State private var cart: [Product] = [] // State variable for cart
    let db = Firestore.firestore()
    @Binding var loggedInUserEmail: String?
    @State private var isLoggedOut = false
    @State private var showFlashMessage = false

    var body: some View {
        VStack {
            HStack {
                Text("User: \(loggedInUserEmail ?? "Unknown")")
                    .font(.subheadline)
                    .padding()
                Spacer()
                Button(action: logout) {
                    Text("Logout")
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.red)
                        .cornerRadius(10)
                }
                .padding()
            }
            .padding(.horizontal)

            if showFlashMessage {
                Text("Product added to cart!")
                    .foregroundColor(.green)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(10)
                    .shadow(radius: 10)
                    .transition(.slide)
                    .animation(.easeInOut)
            }

            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))]) {
                    ForEach(products) { product in
                        NavigationLink(destination: ProductDetailView(product: product, cart: $cart, showFlashMessage: $showFlashMessage)) {
                            VStack {
                                if let url = URL(string: product.image) {
                                    AsyncImage(url: url) { image in
                                        image.frame(width:145, height: 100)
                                             .cornerRadius(10.0)
                                    } placeholder: {
                                        ProgressView()
                                    }
                                } else {
                                    Rectangle()
                                        .fill(Color.gray)
                                        .frame(height: 100)
                                }
                                Text(product.name)
                                    .font(.headline)
                                Text("$\(product.price, specifier: "%.2f")")
                                    .foregroundColor(.green)
                                    .font(.subheadline)
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
            .toolbar {
                NavigationLink(destination: CartView(cart: $cart)) {
                    HStack {
                        Image(systemName: "cart")
                        Text("Cart (\(cart.count))")
                            .font(.subheadline)
                    }
                }
            }
            .background(
                NavigationLink(destination: bablaView().navigationBarBackButtonHidden(true), isActive: $isLoggedOut) {
                    EmptyView()
                }
            )
        }
        .navigationBarBackButtonHidden(true)
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

    func logout() {
        do {
            try Auth.auth().signOut()
            loggedInUserEmail = nil
            isLoggedOut = true
        } catch let signOutError as NSError {
            print("Error signing out: %@", signOutError)
        }
    }
}

// Product Detail View
struct ProductDetailView: View {
    var product: Product
    @Binding var cart: [Product]
    @Binding var showFlashMessage: Bool
    
    var body: some View {
        ScrollView {
            VStack {
                if let url = URL(string: product.image) {
                    AsyncImage(url: url) { image in
                        image.frame(width:365, height: 257)
                            .cornerRadius(15)
                    } placeholder: {
                        ProgressView()
                    }
                }
                Text("Product Name:\n" + product.name)
                    .font(.title2)
                    .padding()
                    .fontWeight(.bold)
                    .foregroundColor(.purple)
                
                Text("Product Description:\n" + product.description)
                    .font(.body)
                    .padding()
                    .foregroundColor(.blue)
                    .fontWeight(.bold)
                
                Text("Price: $\(String(format: "%.2f", product.price))")
                    .font(.title2)
                    .foregroundColor(.green)
                    .padding()
                    .fontWeight(.bold)
                
                Spacer()
                
                Button(action: {
                    if !cart.contains(where: { $0.id == product.id }) {
                        cart.append(product)
                        showFlashMessage = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            showFlashMessage = false
                        }
                    }
                }) {
                    Text("Add to Cart")
                        .font(.title2)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                }

                if showFlashMessage {
                    Text("Product added to cart!")
                        .foregroundColor(.green)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(10)
                        .shadow(radius: 10)
                        .transition(.slide)
                        .animation(.easeInOut)
                }
            }
            .navigationTitle("Product Details")
            .padding()
        }
    }
}

// Cart View
struct CartView: View {
    @Binding var cart: [Product]
    @State private var quantities: [String: Int] = [:]
    @State private var navigateToCheckout = false
    
    var body: some View {
        VStack {
            List {
                ForEach(cart) { product in
                    VStack(alignment: .leading) {
                        Text(product.name)
                            .font(.headline)
                        
                        HStack {
                            Stepper(
                                value: Binding(
                                    get: { quantities[product.id] ?? 1 },
                                    set: { quantities[product.id] = $0 }
                                ),
                                in: 1...99
                            ) {
                                HStack {
                                    Text("Quantity: \(quantities[product.id] ?? 1)")
                                    Spacer()
                                    Text("$\(product.price * Double(quantities[product.id] ?? 1), specifier: "%.2f")")
                                }
                            }
                            
                            Button(action: {
                                deleteProduct(product)
                            }) {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }
                            .buttonStyle(BorderlessButtonStyle())
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            
            Spacer()
            
            Text("Total: $\(totalPrice(), specifier: "%.2f")")
                .font(.title)
                .padding()
            
            Button(action: {
                navigateToCheckout = true
            }) {
                Text("Proceed to Checkout")
                    .font(.title2)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.green)
                    .cornerRadius(10)
            }
            .padding(.bottom, 20)
            .background(
                NavigationLink(destination: CheckoutView(cart: $cart), isActive: $navigateToCheckout) {
                    EmptyView()
                }
            )
        }
        .navigationTitle("Your Cart")
        .onAppear {
            initializeQuantities()
        }
    }
    
    private func initializeQuantities() {
        for product in cart {
            if quantities[product.id] == nil {
                quantities[product.id] = 1
            }
        }
    }
    
    func totalPrice() -> Double {
        cart.reduce(0) { $0 + ($1.price * Double(quantities[$1.id] ?? 1)) }
    }
    
    func deleteProduct(_ product: Product) {
        if let index = cart.firstIndex(where: { $0.id == product.id }) {
            quantities[product.id] = nil
            cart.remove(at: index)
        }
    }
}

// Checkout View
struct CheckoutView: View {
    @Binding var cart: [Product]
    @State private var mobileNumber: String = ""
    @State private var address: String = ""
    @State private var email: String = ""
    @State private var showSuccessMessage: Bool = false
    @Environment(\.presentationMode) var presentationMode

    let db = Firestore.firestore()

    var body: some View {
        VStack(spacing: 20) {
            Text("Checkout")
                .font(.largeTitle)
                .fontWeight(.bold)

            TextField("Mobile Number", text: $mobileNumber)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)

            TextField("Address", text: $address)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)

            TextField("Email", text: $email)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)

            Button(action: placeOrder) {
                Text("Place Order")
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.top, 20)

            if showSuccessMessage {
                Text("Order placed successfully!")
                    .foregroundColor(.green)
            }

            Spacer()
        }
        .padding()
    }

    func placeOrder() {
        let orderData: [String: Any] = [
            "mobileNumber": mobileNumber,
            "address": address,
            "email": email,
            "products": cart.map { ["id": $0.id, "name": $0.name, "price": $0.price] }
        ]

        db.collection("orders").addDocument(data: orderData) { error in
            if let error = error {
                print("Error placing order: \(error.localizedDescription)")
            } else {
                showSuccessMessage = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    self.presentationMode.wrappedValue.dismiss()
                }
            }
        }
    }
}

