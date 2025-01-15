//
//  login-and-signup.swift
//  Easy_Shop
//
//  Created by Dibyo sarkar on 8/1/25.
//
import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

// Login page view
struct LoginPage: View {
    @Binding var loggedInUserEmail: String?
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var errorMessage: String = ""
    @State private var showSuccessMessage: Bool = false
    @State private var navigateToProductGrid: Bool = false
    @State private var navigateToAdminPage: Bool = false

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

                if showSuccessMessage {
                    Text("Login successful!")
                        .foregroundColor(.green)
                }

                Spacer()
            }
            .padding()
            .background(
                Group {
                    NavigationLink(destination: ProductGridView(loggedInUserEmail: $loggedInUserEmail).navigationBarBackButtonHidden(true), isActive: $navigateToProductGrid) {
                        EmptyView()
                    }
                    NavigationLink(destination: AdminPage(loggedInUserEmail: $loggedInUserEmail).navigationBarBackButtonHidden(true), isActive: $navigateToAdminPage) {
                        EmptyView()
                    }
                }
            )
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
                showSuccessMessage = true
                print("User logged in successfully: \(user.email ?? "No Email")")
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    if user.email == "admin@gmail.com" {
                        navigateToAdminPage = true
                    } else {
                        navigateToProductGrid = true
                    }
                }
            }
        }
    }
} 


// Sign up page view
struct SignupPage: View {
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var errorMessage: String = ""
    @State private var showSuccessMessage: Bool = false
    @Environment(\.presentationMode) var presentationMode

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

            if showSuccessMessage {
                Text("Signup successful! Please log in.")
                    .foregroundColor(.green)
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
                showSuccessMessage = true
                print("User signed up successfully")
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    self.presentationMode.wrappedValue.dismiss()
                }
            }
        }
    }
}
