import SwiftUI

/// Animated splash branding screen with authentication check.
public struct SplashScreen: View {
    @ObservedObject public var viewModel: SplashViewModel
    public let onNavigate: (SplashDestination) -> Void

    public init(viewModel: SplashViewModel, onNavigate: @escaping (SplashDestination) -> Void) {
        self.viewModel = viewModel
        self.onNavigate = onNavigate
    }

    public var body: some View {
        ZStack {
            Color.primaryBlue
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Logo icon container
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.15))
                        .frame(width: 130, height: 130)

                    Image(systemName: "person.badge.shield.checkmark.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 72, height: 72)
                        .foregroundColor(.white)
                }

                Spacer().frame(height: 28)

                Text("MNIT Attendance")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)

                Spacer().frame(height: 6)

                Text("Smart Attendance System")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color.white.opacity(0.8))

                Spacer().frame(height: 48)

                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.2)

                Spacer()
            }
        }
        .onChange(of: viewModel.destination) { destination in
            if destination != .loading {
                onNavigate(destination)
            }
        }
    }
}

