import RevenueCat
import SwiftUI

@available(iOS 16.0, macOS 13.0, tvOS 16.0, *)
struct MultiPackageBoldTemplate: TemplateViewType {

    private let configuration: TemplateViewConfiguration
    private var localization: [Package: ProcessedLocalizedConfiguration]

    @State
    private var selectedPackage: Package

    @EnvironmentObject
    private var introEligibilityViewModel: IntroEligibilityViewModel
    @EnvironmentObject
    private var purchaseHandler: PurchaseHandler

    init(_ configuration: TemplateViewConfiguration) {
        self._selectedPackage = .init(initialValue: configuration.packages.default.content)

        self.configuration = configuration
        self.localization = Dictionary(
            uniqueKeysWithValues: configuration.packages.all
                .lazy
                .map { ($0.content, $0.localization) }
            )
    }

    var body: some View {
        self.content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background {
                self.backgroundImage
                    .unredacted()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .edgesIgnoringSafeArea(.all)
            }
    }

    @ViewBuilder
    var content: some View {
        VStack(spacing: 10) {
            self.iconImage

            self.scrollableContent
                .scrollableIfNecessary()

            self.subscribeButton
                .padding(.horizontal)

            if case .fullScreen = self.configuration.mode {
                FooterView(configuration: self.configuration.configuration,
                           color: self.configuration.colors.text1Color,
                           purchaseHandler: self.purchaseHandler)
            }
        }
        .animation(Constants.fastAnimation, value: self.selectedPackage)
        .frame(maxHeight: .infinity)
        .multilineTextAlignment(.center)
        .frame(maxHeight: .infinity)
    }

    private var scrollableContent: some View {
        VStack {
            Spacer()

            Text(self.selectedLocalization.title)
                .foregroundColor(self.configuration.colors.text1Color)
                .font(.largeTitle.bold())

            Spacer()

            Text(self.selectedLocalization.subtitle ?? "")
                .foregroundColor(self.configuration.colors.text1Color)
                .font(.title3)

            Spacer()

            self.packages

            Spacer()
        }
        .padding(.horizontal)
        .frame(maxHeight: .infinity)
    }

    private var packages: some View {
        VStack(spacing: 8) {
            ForEach(self.configuration.packages.all, id: \.content.id) { package in
                let isSelected = self.selectedPackage === package.content

                Button {
                    self.selectedPackage = package.content
                } label: {
                    self.packageButton(package, selected: isSelected)
                        .contentShape(Rectangle())
                }
                .buttonStyle(PackageButtonStyle(isSelected: isSelected))
            }
        }
        .padding(.bottom)
    }

    @ViewBuilder
    private func packageButton(_ package: TemplateViewConfiguration.Package, selected: Bool) -> some View {
        let alignment: Alignment = .leading

        VStack(alignment: alignment.horizontal, spacing: 5) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .hidden(if: !selected)
                    .overlay {
                        if selected {
                            EmptyView()
                        } else {
                            Circle()
                                .foregroundColor(self.selectedBackgroundColor.opacity(0.5))
                        }
                    }

                Text(self.localization(for: package.content).offerName ?? package.content.productName)
            }
            .foregroundColor(self.configuration.colors.accent1Color)

            IntroEligibilityStateView(
                textWithNoIntroOffer: package.localization.offerDetails,
                textWithIntroOffer: package.localization.offerDetailsWithIntroOffer,
                introEligibility: self.introEligibility[package.content],
                foregroundColor: selected
                    ? self.configuration.colors.backgroundColor
                    : self.configuration.colors.text1Color,
                alignment: alignment
            )
            .fixedSize(horizontal: false, vertical: true)
            .font(.body)
        }
        .font(.body.weight(.medium))
        .padding()
        .multilineTextAlignment(.leading)
        .frame(maxWidth: .infinity, alignment: alignment)
        .overlay {
            if selected {
                EmptyView()
            } else {
                RoundedRectangle(cornerRadius: Self.cornerRadius)
                    .stroke(self.configuration.colors.text1Color, lineWidth: 2)
            }
        }
        .background {
            RoundedRectangle(cornerRadius: Self.cornerRadius, style: .continuous)
                .foregroundColor(
                    selected
                    ? self.selectedBackgroundColor
                    : .clear
                )
        }
    }

    private var subscribeButton: some View {
        PurchaseButton(
            package: self.selectedPackage,
            colors: self.configuration.colors,
            localization: self.selectedLocalization,
            introEligibility: self.introEligibility[self.selectedPackage],
            mode: self.configuration.mode,
            purchaseHandler: self.purchaseHandler
        )
    }

    @ViewBuilder
    private var backgroundImage: some View {
        if let url = self.configuration.backgroundImageURL {
            if self.configuration.configuration.blurredBackgroundImage {
                RemoteImage(url: url)
                    .blur(radius: 40)
                    .opacity(0.7)
            } else {
                RemoteImage(url: url)
            }
        } else {
            DebugErrorView("Template configuration is missing background URL",
                           releaseBehavior: .emptyView)
        }
    }

    @ViewBuilder
    private var iconImage: some View {
        Group {
            if let url = self.configuration.iconImageURL {
                RemoteImage(url: url, aspectRatio: 1, maxWidth: Self.iconSize)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            } else {
                // Placeholder to be able to add a consistent padding
                Text(verbatim: "")
                    .hidden()
            }
        }
        .padding(.top)
    }

    // MARK: -

    private var introEligibility: [Package: IntroEligibilityStatus] {
        return self.introEligibilityViewModel.allEligibility
    }

    private var selectedBackgroundColor: Color { self.configuration.colors.accent2Color }

    private static let iconSize: CGFloat = 100
    private static let cornerRadius: CGFloat = 15

}

// MARK: - Extensions

@available(iOS 16.0, macOS 13.0, tvOS 16.0, *)
private extension MultiPackageBoldTemplate {

    func localization(for package: Package) -> ProcessedLocalizedConfiguration {
        // Because of how packages are constructed this is known to exist
        return self.localization[package]!
    }

    var selectedLocalization: ProcessedLocalizedConfiguration {
        return self.localization(for: self.selectedPackage)
    }

}