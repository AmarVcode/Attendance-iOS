import SwiftUI

/// Registration screen matching Android SignupScreen.
public struct SignupScreen: View {
    @StateObject private var viewModel = SignupViewModel()
    @Environment(\.presentationMode) private var presentationMode
    public let onNavigateToPending: () -> Void

    @State private var showDatePicker: Bool = false
    @State private var selectedDate: Date = Date()

    public init(onNavigateToPending: @escaping () -> Void) {
        self.onNavigateToPending = onNavigateToPending
    }

    public var body: some View {
        ZStack {
            Color.lightBackground
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    CustomCard(cornerRadius: 20) {
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Employee Registration")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.slateDark)

                            Text("Provide your employee details for device verification")
                                .font(.system(size: 12))
                                .foregroundColor(.slateMedium)

                            Divider().background(Color.borderLight)

                            // Name
                            InputField(title: "Full Name *", icon: "person.fill", text: $viewModel.name)

                            // Employee ID
                            InputField(title: "Employee ID *", icon: "person.text.rectangle.fill", text: $viewModel.employeeId)

                            // Email
                            InputField(title: "Email Address *", icon: "envelope.fill", text: $viewModel.email, keyboardType: .emailAddress)

                            // Phone
                            InputField(title: "Phone Number *", icon: "phone.fill", text: $viewModel.phone, keyboardType: .phonePad)

                            // Department
                            InputField(title: "Department *", icon: "building.2.fill", text: $viewModel.department)

                            // Designation
                            InputField(title: "Designation *", icon: "briefcase.fill", text: $viewModel.designation)

                            // Joining Date
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Joining Date (YYYY-MM-DD) *")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.slateMedium)

                                Button(action: { showDatePicker.toggle() }) {
                                    HStack {
                                        Image(systemName: "calendar")
                                            .foregroundColor(.primaryBlue)
                                            .frame(width: 20)

                                        Text(viewModel.joiningDate.isEmpty ? "Select Date" : viewModel.joiningDate)
                                            .foregroundColor(.slateDark)
                                            .font(.system(size: 15))

                                        Spacer()
                                    }
                                    .padding(14)
                                    .background(Color.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.borderLight, lineWidth: 1)
                                    )
                                }
                            }

                            // Password
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Password *")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.slateMedium)

                                HStack {
                                    Image(systemName: "lock.fill")
                                        .foregroundColor(.primaryBlue)
                                        .frame(width: 20)

                                    if viewModel.isPasswordVisible {
                                        TextField("Enter password", text: $viewModel.password)
                                            .autocapitalization(.none)
                                            .disableAutocorrection(true)
                                    } else {
                                        SecureField("Enter password", text: $viewModel.password)
                                    }

                                    Button(action: { viewModel.togglePasswordVisibility() }) {
                                        Image(systemName: viewModel.isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                                            .foregroundColor(.slateMedium)
                                    }
                                }
                                .padding(14)
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.borderLight, lineWidth: 1)
                                )
                            }

                            // Confirm Password
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Confirm Password *")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.slateMedium)

                                HStack {
                                    Image(systemName: "lock.rotation")
                                        .foregroundColor(.primaryBlue)
                                        .frame(width: 20)

                                    SecureField("Confirm password", text: $viewModel.confirmPassword)
                                }
                                .padding(14)
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.borderLight, lineWidth: 1)
                                )
                            }

                            Spacer().frame(height: 10)

                            PrimaryButton(
                                title: "SUBMIT REGISTRATION",
                                backgroundColor: .primaryBlue,
                                isLoading: viewModel.isLoading
                            ) {
                                viewModel.register()
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
            }
        }
        .navigationTitle("Create Account")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showDatePicker) {
            VStack {
                DatePicker("Joining Date", selection: $selectedDate, displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .padding()

                Button("Done") {
                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyy-MM-dd"
                    viewModel.joiningDate = formatter.string(from: selectedDate)
                    showDatePicker = false
                }
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.primaryBlue)
                .padding()
            }
        }
        .alert(isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Alert(
                title: Text("Registration"),
                message: Text(viewModel.errorMessage ?? ""),
                dismissButton: .default(Text("OK"))
            )
        }
        .onChange(of: viewModel.didRegisterSuccessfully) { success in
            if success {
                onNavigateToPending()
                viewModel.clearState()
            }
        }
    }
}

private struct InputField: View {
    let title: String
    let icon: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.slateMedium)

            HStack {
                Image(systemName: icon)
                    .foregroundColor(.primaryBlue)
                    .frame(width: 20)

                TextField("", text: $text)
                    .keyboardType(keyboardType)
                    .autocapitalization(.none)
            }
            .padding(14)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.borderLight, lineWidth: 1)
            )
        }
    }
}

