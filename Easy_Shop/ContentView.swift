import SwiftUI
import Firebase
import FirebaseAuth

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

// Entry page or view
struct bablaView: View {
    @State private var loggedInUserEmail: String? = nil

    var body: some View {
        NavigationView {
            VStack {
                if let email = loggedInUserEmail {
                    // Show Product List View when logged in
                    ProductListView(userEmail: email, logoutAction: logout)
                } else {
                    // Show welcome message and navigation buttons when logged out
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

    func logout() {
        do {
            try Auth.auth().signOut()
            loggedInUserEmail = nil
        } catch {
            print("Error logging out: \(error.localizedDescription)")
        }
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
    var id: Int
    var name: String
    var description: String
    var price: Double
    var image: String
}

// Product List View
struct ProductListView: View {
    var userEmail: String
    var logoutAction: () -> Void // Logout action passed from bablaView
    @State private var cart: [Product] = []
    
    let products: [Product] = [
        Product(id: 1, name: "Apple iPhone 13", description: "Latest iPhone", price: 799, image: "iphone"),
        Product(id: 2, name: "MacBook Pro", description: "Apple laptop", price: 1299, image: "macbook"),
        Product(id: 3, name: "Samsung Galaxy S21", description: "Flagship Android", price: 749, image: "samsung"),
        Product(id: 4, name: "AirPods Pro", description: "Wireless Earbuds", price: 249, image: "airpods"),
        Product(id: 5, name: "Apple Watch Series 7", description: "Smartwatch", price: 399, image: "applewatch"),
        Product(id: 6, name: "Google Pixel 6", description: "Latest Android Phone", price: 599, image: "pixel"),
        Product(id: 7, name: "Sony WH-1000XM4", description: "Noise-cancelling headphones", price: 349, image: "sonyheadphones"),
        Product(id: 8, name: "Dell XPS 13", description: "Premium Laptop", price: 999, image: "dellxps"),
        Product(id: 9, name: "iPad Pro 12.9", description: "Tablet for Professionals", price: 1099, image: "ipad"),
        Product(id: 10, name: "Beats Studio Buds", description: "Wireless Earbuds", price: 149, image: "beats")
    ]
    
    var body: some View {
        VStack {
            List(products) { product in
                HStack {
                    Image(systemName: product.image)
                        .resizable()
                        .frame(width: 50, height: 50)
                        .cornerRadius(8)
                    
                    VStack(alignment: .leading) {
                        Text(product.name)
                            .font(.headline)
                        Text("$\(product.price, specifier: "%.2f")")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        addToCart(product)
                    }) {
                        Text("Add to Cart")
                            .padding(8)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
                .padding(.vertical, 5)
            }
            
            Spacer()
        }
        .navigationTitle("Products")
        .navigationBarBackButtonHidden(true)
        .toolbar {
            NavigationLink(destination: CartView(cart: $cart)) {
                Text("Cart (\(cart.count))")
            }
            
            Button(action: {
                logoutAction() // Call the logoutAction passed from bablaView
            }) {
                Text("Logout")
                    .foregroundColor(.red)
            }
        }
    }
    
    func addToCart(_ product: Product) {
        cart.append(product)
    }
}




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
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        LoginPage(loggedInUserEmail: .constant(nil))
    }
}
