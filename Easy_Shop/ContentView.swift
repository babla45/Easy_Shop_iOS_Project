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
        ProductGridView()
    }
}

// Main Navigation Update
struct bablaView: View {
    @State private var loggedInUserEmail: String? = nil

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
                    Text("Welcome to Easy Shop\n Please login to your account.")
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

// Product Grid View with Firebase Data
struct ProductGridView: View {
    @State private var products: [Product] = []
    @State private var cart: [Product] = [] // State variable for cart
    let db = Firestore.firestore()

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))]) {
                    ForEach(products) { product in
                        NavigationLink(destination: ProductDetailView(product: product, cart: $cart)) {
                            VStack {
                                if let url = URL(string: product.image) {
                                    AsyncImage(url: url) { image in
                                        image.frame(width:150, height: 100)
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
    @Binding var cart: [Product]
    
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
                    }
                }) {
                    Text("Add to Cart")
                        .font(.title2)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
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

