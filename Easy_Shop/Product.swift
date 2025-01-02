import SwiftUI

// WelcomePage View, not used yet
struct WelcomePagee: View {
    var userEmail: String // The logged-in user's email

    var body: some View {
        VStack {
            Text("Hello, \(userEmail)!")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.green)
                .padding()

            Text("Welcome to our app!\n Have a nice day.")
                .font(.title2)
                .foregroundColor(.secondary)
                .padding(.top, 10)

            Spacer()
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
        .toolbar {
            NavigationLink(destination: CartView(cart: $cart)) {
                Text("Cart (\(cart.count))")
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

