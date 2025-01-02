import SwiftUI
import Firebase
import FirebaseAuth


//main entry point
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




//entry page or view
struct bablaView: View {
    var body: some View {
        NavigationView {
            VStack {
                Text("Welcome to FirebaseLab3")
                    .font(.title)
                    .foregroundColor(.purple)
                HStack {
                    NavigationLink(destination: LoginPage()) {
                        Text("Login")
                            .font(.title2)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.leading)
                            .padding(.vertical, 10.0)
                            .padding(.horizontal, 20.0)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding()
                    
                    NavigationLink(destination: SignupPage()) {
                        Text("Signup")
                            .font(.title2)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.leading)
                            .padding(.vertical, 10.0)
                            .padding(.horizontal, 20.0)
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding()


                }

            }
            .padding()
        }
    }
}



//welcome page
struct WelcomePage: View {
    var userEmail: String // The logged-in user's email

    var body: some View {
        VStack {
            Text("Hello, \(userEmail)!")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.green)
                .padding()

            Text("Welcome to our app!")
                .font(.title2)
                .foregroundColor(.secondary)
                .padding(.top, 10)

            Spacer()
        }
        .padding()
    }
}





struct LoginPage: View {
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var errorMessage: String = ""
    @State private var loggedInUserEmail: String? = nil

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                if let userEmail = loggedInUserEmail {
                    WelcomePage(userEmail: userEmail)
                } else {
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





//sign up page view
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
                errorMessage = ""
                print("User signed up successfully")
            }
        }
    }
}

//contentview preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        LoginPage()
    }
}
