import SwiftUI

@main
public struct AttendanceApp: App {
    @StateObject private var splashViewModel = SplashViewModel()
    @State private var currentRoute: SplashDestination = .loading

    public init() {}

    public var body: some Scene {
        WindowGroup {
            ZStack {
                switch currentRoute {
                case .loading:
                    SplashScreen(viewModel: splashViewModel) { destination in
                        withAnimation(.easeInOut(duration: 0.3)) {
                            currentRoute = destination
                        }
                    }
                case .login:
                    LoginScreen(
                        onNavigateToHome: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                currentRoute = .home
                            }
                        },
                        onNavigateToPending: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                currentRoute = .pendingApproval
                            }
                        }
                    )
                case .pendingApproval:
                    PendingApprovalScreen(
                        onNavigateToHome: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                currentRoute = .home
                            }
                        },
                        onNavigateToLogin: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                currentRoute = .login
                            }
                        }
                    )
                case .home:
                    HomeScreen(
                        onNavigateToLogin: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                currentRoute = .login
                            }
                        }
                    )
                }
            }
            .onAppear {
                LocationManager.shared.requestAuthorization()
            }
        }
    }
}

