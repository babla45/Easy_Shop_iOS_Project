import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

// Main entry point
@main
struct FirebaseLab3App: App {
//    @State private var adminEmail: String? = "admin@gmail.com"
    
    init() {
        // Initialize Firebase
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            bablaView()
//            AdminPage(loggedInUserEmail: $adminEmail)
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
    var quantity: Int = 1 // Add quantity property
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
    @State private var navigateToUserOrders = false

    var body: some View {
        VStack {
            HStack {
                Text("Username: \(loggedInUserEmail ?? "Unknown")")
                    .font(.subheadline)
                    .padding()
                    .foregroundColor(.purple)
                Spacer()
                Button(action: logout) {
                    Text("Logout")
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 5)
                        .background(Color.red)
                        .cornerRadius(10)
                }
                .padding()
            }
            .padding(.horizontal)

            if showFlashMessage {
                VStack {
                    Spacer()
                    Text("Product added to cart!")
                        .foregroundColor(.green)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(10)
                        .shadow(radius: 10)
                        .transition(.slide)
                        .animation(.easeInOut)
                    Spacer()
                }
            }

            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))]) {
                    ForEach(products) { product in
                        NavigationLink(destination: ProductDetailView(product: product, cart: $cart, showFlashMessage: $showFlashMessage)) {
                            VStack {
                                if let url = URL(string: product.image) {
                                    AsyncImage(url: url) { image in
                                        image
                                            .resizable() // Ensure the image is resizable
                                            .scaledToFit() // Scale the image to fit within the frame
                                            .frame(width: 145, height: 100)
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
                NavigationLink(destination: CartView(cart: $cart, loggedInUserEmail: $loggedInUserEmail)) {
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

            Button(action: {
                navigateToUserOrders = true
            }) {
                Text("View Your Orders")
                    .font(.title2)
                    .foregroundColor(.white)
                    .padding(.horizontal, 15)
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .padding(.bottom, 20)
            .background(
                NavigationLink(destination: UserOrdersView(loggedInUserEmail: $loggedInUserEmail), isActive: $navigateToUserOrders) {
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
                        image
                            .resizable() // Ensure the image is resizable
                            .scaledToFit() // Scale the image to fit within the frame
                            .frame(width: 365, height: 257)
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
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(Color.blue)
                        .cornerRadius(10)
                }

                if showFlashMessage {
                    VStack {
                        Spacer()
                        Text("Product added to cart!")
                            .foregroundColor(.green)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(10)
                            .shadow(radius: 10)
                            .transition(.slide)
                            .animation(.easeInOut)
                        Spacer()
                    }
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
    @Binding var loggedInUserEmail: String?
    @State private var navigateToCurrencyRates = false // Add this line

    var body: some View {
        VStack {
            List {
                ForEach(cart) { product in
                    VStack(alignment: .leading) {
                        Text(product.name)
                            .font(.headline)
                        
                        HStack {
                            if let url = URL(string: product.image) {
                                AsyncImage(url: url) { image in
                                    image
                                        .resizable() // Ensure the image is resizable
                                        .scaledToFit() // Scale the image to fit within the frame
                                        .frame(width: 50, height: 50)
                                        .cornerRadius(5.0)
                                } placeholder: {
                                    ProgressView()
                                }
                            } else {
                                Rectangle()
                                    .fill(Color.gray)
                                    .frame(width: 50, height: 50)
                            }
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
            
            // Add this button before the total price
            Button(action: {
                navigateToCurrencyRates = true
            }) {
                HStack {
                    Image(systemName: "dollarsign.circle.fill")
                    Text("View Price in Other Currencies")
                }
                .font(.headline)
                .foregroundColor(.blue)
                .padding(.vertical, 10)
            }
            .background(
                NavigationLink(destination: CurrencyRatesView(cart: $cart), isActive: $navigateToCurrencyRates) {
                    EmptyView()
                }
            )
            
            Text("Total: $\(totalPrice(), specifier: "%.2f")")
                .font(.title)
                .padding()
            
            Button(action: {
                navigateToCheckout = true
            }) {
                Text("Proceed to Checkout")
                    .font(.title2)
                    .foregroundColor(.white)
                    .padding(.horizontal, 15)
                    .padding(.vertical, 7)
                    .background(Color.green)
                    .cornerRadius(10)
            }
            .padding(.bottom, 20)
            .background(
                NavigationLink(destination: CheckoutView(cart: $cart, loggedInUserEmail: $loggedInUserEmail), isActive: $navigateToCheckout) {
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
    @State private var name: String = "" // Add name state
    @State private var mobileNumber: String = ""
    @State private var address: String = ""
    @State private var email: String = ""
    @State private var paymentMethod: String = "Cash on Delivery" // Add payment method state
    @State private var showSuccessMessage: Bool = false
    @Environment(\.presentationMode) var presentationMode
    @State private var quantities: [String: Int] = [:]
    @Binding var loggedInUserEmail: String?
    @State private var navigateToProductGrid = false

    let db = Firestore.firestore()

    var body: some View {
        VStack(spacing: 20) {
            Text("Checkout")
                .font(.largeTitle)
                .fontWeight(.bold)

            TextField("Name", text: $name) // Add name field
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)

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
                .disabled(true) // Disable editing

            Text("Payment Method")
                .font(.headline)
                .padding(.top, 10)

            Picker("Payment Method", selection: $paymentMethod) {
                Text("Cash on Delivery").tag("Cash on Delivery")
                // Add more payment methods here if needed
            }
            .pickerStyle(MenuPickerStyle())
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
        .onAppear {
            initializeQuantities()
            email = loggedInUserEmail ?? ""
        }
        .background(
            NavigationLink(destination: ProductGridView(loggedInUserEmail: $loggedInUserEmail).navigationBarBackButtonHidden(true), isActive: $navigateToProductGrid) {
                EmptyView()
            }
        )
    }

    func initializeQuantities() {
        for product in cart {
            if quantities[product.id] == nil {
                quantities[product.id] = 1
            }
        }
    }

    func placeOrder() {
        let orderData: [String: Any] = [
            "name": name, // Add name to order data
            "mobileNumber": mobileNumber,
            "address": address,
            "email": email,
            "paymentMethod": paymentMethod, // Add payment method to order data
            "products": cart.map { ["id": $0.id, "name": $0.name, "price": $0.price, "quantity": quantities[$0.id] ?? 1] }
        ]

        db.collection("orders").addDocument(data: orderData) { error in
            if let error = error {
                print("Error placing order: \(error.localizedDescription)")
            } else {
                showSuccessMessage = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    cart.removeAll()
                    navigateToProductGrid = true
                }
            }
        }
    }
}

// User Orders View
struct UserOrdersView: View {
    @Binding var loggedInUserEmail: String?
    @State private var orders: [Order] = []
    let db = Firestore.firestore()

    var body: some View {
        VStack {
            Text("Your Orders")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding()

            List {
                ForEach(orders) { order in
                    VStack(alignment: .leading) {
                        Text("Order ID: \(order.id)")
                        Text("Name: \(order.name)") // Add name display
                        Text("Mobile: \(order.mobileNumber)")
                        Text("Address: \(order.address)")
                        Text("Email: \(order.email)")
                        Text("Payment Method: \(order.paymentMethod)") // Add payment method display
                        ForEach(order.products) { product in
                            Text("\(product.name) - $\(product.price, specifier: "%.2f") x \(product.quantity)")
                        }
                        Text("Total: $\(order.totalPrice, specifier: "%.2f")")
                            .fontWeight(.bold)
                    }
                    .padding()
                }
            }
        }
        .onAppear {
            loadUserOrders()
        }
    }

    func loadUserOrders() {
        guard let email = loggedInUserEmail else { return }
        db.collection("orders").whereField("email", isEqualTo: email).getDocuments { snapshot, error in
            if let error = error {
                print("Error loading orders: \(error.localizedDescription)")
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
}

// Currency Rates View to display exchange rates
struct CurrencyRatesView: View {
    @State private var conversionRates: [String: Double] = [:]
    @State private var selectedCurrency: (String, Double)? = nil // State for selected currency
    @State private var navigateToCurrencyDetail = false // State for navigation
    @Binding var cart: [Product] // Add this line

    var body: some View {
        VStack {
            Text("Currency Rates")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.orange)
                .padding()

            List(conversionRates.sorted(by: >), id: \.key) { key, value in
                VStack(alignment: .leading) {
                    Text("\(key): \(value, specifier: "%.4f")")
                        .font(.headline)
                }
                .padding()
                .onTapGesture {
                    selectedCurrency = (key, value)
                    navigateToCurrencyDetail = true
                }
            }
        }
        .onAppear {
            fetchCurrencyRates()
        }
        .background(
            NavigationLink(destination: CurrencyDetailView(currency: selectedCurrency, cart: $cart), isActive: $navigateToCurrencyDetail) {
                EmptyView()
            }
        )
    }

    func fetchCurrencyRates() {
        let apiKey = "2d01062e9692eed1a3fbc009"
        let urlString = "https://v6.exchangerate-api.com/v6/\(apiKey)/latest/USD"
        guard let url = URL(string: urlString) else { return }

        URLSession.shared.dataTask(with: url) { data, response, error in
            if let data = data {
                do {
                    let currencyResponse = try JSONDecoder().decode(CurrencyResponse.self, from: data)
                    DispatchQueue.main.async {
                        self.conversionRates = currencyResponse.conversion_rates
                    }
                } catch {
                    print("Error decoding currency data: \(error)")
                }
            }
        }.resume()
    }
}

// New view to show currency conversion details
struct CurrencyDetailView: View {
    var currency: (String, Double)?
    @Binding var cart: [Product]
    @State private var quantities: [String: Int] = [:]
    
    private var totalUSDPrice: Double {
        cart.reduce(0) { $0 + ($1.price * Double(quantities[$1.id] ?? 1)) }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if let currency = currency {
                    // Currency Header
                    VStack {
                        Text(currency.0)
                            .font(.system(size: 40, weight: .bold))
                            .foregroundColor(.primary)
                        Text("Currency Details")
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical)
                    
                    // Conversion Rate Card
                    VStack(spacing: 15) {
                        HStack {
                            Image(systemName: "arrow.left.arrow.right.circle.fill")
                                .font(.title)
                                .foregroundColor(.blue)
                            Text("Exchange Rate")
                                .font(.headline)
                        }
                        
                        Text("1 USD = \(currency.1, specifier: "%.4f") \(currency.0)")
                            .font(.title2)
                            .foregroundColor(.green)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color(.systemGray6))
                    )
                    .padding(.horizontal)
                    
                    // Cart Total Conversion Card
                    VStack(spacing: 15) {
                        HStack {
                            Image(systemName: "cart.fill")
                                .font(.title)
                                .foregroundColor(.orange)
                            Text("Cart Total")
                                .font(.headline)
                        }
                        
                        Divider()
                        
                        VStack(spacing: 10) {
                            HStack {
                                Text("USD Total:")
                                Spacer()
                                Text("$\(totalUSDPrice, specifier: "%.2f")")
                                    .foregroundColor(.blue)
                                    .font(.headline)
                            }
                            
                            HStack {
                                Text("\(currency.0) Total:")
                                Spacer()
                                Text("\(totalUSDPrice * currency.1, specifier: "%.2f") \(currency.0)")
                                    .foregroundColor(.green)
                                    .font(.headline)
                            }
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color(.systemGray6))
                    )
                    .padding(.horizontal)
                    
                    // Additional Info
                    if cart.isEmpty {
                        Text("Your cart is empty")
                            .font(.callout)
                            .foregroundColor(.secondary)
                            .padding()
                    } else {
                        Text("Cart Items: \(cart.count)")
                            .font(.callout)
                            .foregroundColor(.secondary)
                            .padding()
                    }
                } else {
                    Text("No currency selected")
                        .font(.title)
                        .foregroundColor(.secondary)
                        .padding()
                }
            }
        }
        .navigationTitle("Currency Details")
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
}

// Models for Currency API response
struct CurrencyResponse: Codable {
    let conversion_rates: [String: Double]
}

