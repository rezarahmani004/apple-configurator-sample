// SPDX-FileCopyrightText: Copyright (c) 2024 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
// SPDX-License-Identifier: LicenseRef-NvidiaProprietary
//
// NVIDIA CORPORATION, its affiliates and licensors retain all intellectual
// property and proprietary rights in and to this material, related
// documentation and any modifications thereto. Any use, reproduction,
// disclosure or distribution of this material and related documentation
// without an express license agreement from NVIDIA CORPORATION or
// its affiliates is strictly prohibited.

import SwiftUI
import CloudXRKit
import RealityKit

struct OmniConfigurator: View {
#if DEBUG
    @AppStorage("showDebug") var showDebugUI = true
#else
    @AppStorage("showDebug") var showDebugUI = false
#endif

    enum Section {
        case configure
        case environment
        case hud

        var title: String {
            switch self {
            case .configure:
                "Configure"
            case .environment:
                "Environment"
            case .hud:
                "HUD"
            }
        }
    }

    @Environment(AppModel.self) var appModel
    @Environment(ConfiguratorViewModel.self) var configuratorViewModel
    @Environment(ConfiguratorAppModel.self) var configuratorAppModel
    @Environment(\.scenePhase) var scenePhase
    @Environment(\.openImmersiveSpace) var openImmersiveSpace

    @State var section = Section.configure
    @State var showCameras = false
    @State var showDebugPopup = false

    @Binding var application: Application

    // MARK: - NVIDIA-Inspired Colors

    private let nvidiaGreen = Color(red: 118/255, green: 185/255, blue: 0/255)   // #76B900
    private let nvidiaHighlight = Color(red: 164/255, green: 225/255, blue: 0/255) // #A4E100
    private let deepBlack = Color(red: 10/255, green: 10/255, blue: 10/255)      // #0A0A0A
    private let panelTint = Color.black.opacity(0.58)

    var body: some View {
#if DEBUG
        let _ = Self._printChanges()
#endif

        ZStack {
            premiumBackground

            VStack(spacing: 0) {
                titleBar
                    .padding(.horizontal, 28)
                    .padding(.top, 18)
                    .padding(.bottom, 10)

                switch section {
                case .configure:
                    VStack {
                        Spacer(minLength: 10)

                        centerBrandingPanel

                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                case .environment:
                    EnvironmentView()

                case .hud:
                    if let session = configuratorAppModel.session {
                        ScrollView {
                            HUDView(session: session, hudConfig: HUDConfig())
                        }
                    }
                }
            }
        }
        .ornament(visibility: .visible, attachmentAnchor: .scene(.init(x: 0.5, y: 0.92))) {
            bottomOrnament
        }
    }

    // MARK: - Background

    var premiumBackground: some View {
        ZStack {
            LinearGradient(
                colors: [
                    deepBlack,
                    Color(red: 12/255, green: 16/255, blue: 12/255),
                    Color(red: 8/255, green: 10/255, blue: 8/255)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            RadialGradient(
                colors: [
                    nvidiaGreen.opacity(0.10),
                    nvidiaHighlight.opacity(0.05),
                    Color.clear
                ],
                center: .center,
                startRadius: 40,
                endRadius: 430
            )
            .blur(radius: 40)
            .ignoresSafeArea()

            RadialGradient(
                colors: [
                    Color.clear,
                    Color.black.opacity(0.18),
                    Color.black.opacity(0.34)
                ],
                center: .center,
                startRadius: 120,
                endRadius: 900
            )
            .ignoresSafeArea()
        }
    }

    // MARK: - Top Title Bar

    var titleBar: some View {
        HStack {
            Button {
                guard let viewing = configuratorAppModel.asset[viewingKey] as? ViewingModel else { return }
                configuratorAppModel.asset[viewingKey] = viewing.toggle()
            } label: {
                if configuratorViewModel.viewIsLoading {
                    ProgressView()
                } else {
                    Image(systemName: portalSymbol)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(
                            width: ConfiguratorUIConstants.topCornerButtonSize,
                            height: ConfiguratorUIConstants.topCornerButtonSize
                        )
                        .padding(.vertical, UIConstants.margin)
                        .foregroundStyle(.white)
                        .help(portalHelp)
                }
            }
            .disabled(configuratorViewModel.isPlacing)
            .padding(11)
            .background(.ultraThinMaterial, in: Circle())
            .overlay(
                Circle()
                    .stroke(nvidiaGreen.opacity(0.18), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.35), radius: 10, y: 5)

            Spacer()

            VStack(spacing: 10) {
                brandedTitle(fontSize: 34)

                Button(appModel.ratingText) {
                    appModel.isRatingViewPresented = true
                }
                .disabled(appModel.disableFeedback)
                .sheet(isPresented: Binding(get: { appModel.isRatingViewPresented }, set: { _ in })) {
                    StarRatingView()
                }
            }

            Spacer()

            Button {
                showCameras.toggle()
            } label: {
                cameraImage
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(
                        width: ConfiguratorUIConstants.topCornerButtonSize,
                        height: ConfiguratorUIConstants.topCornerButtonSize
                    )
                    .padding(.vertical, UIConstants.margin)
                    .foregroundStyle(.white)
                    .help(cameraHelp)
            }
            .padding(11)
            .background(.ultraThinMaterial, in: Circle())
            .overlay(
                Circle()
                    .stroke(nvidiaGreen.opacity(0.18), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.35), radius: 10, y: 5)
            .opacity(configuratorViewModel.currentViewing.mode == .tabletop ? 0 : 1)
            .disabled(configuratorViewModel.currentViewing.mode == .tabletop)
            .popover(isPresented: $showCameras) {
                CameraSheet()
                    .frame(
                        width: ConfiguratorUIConstants.cameraSheetSize.width,
                        height: ConfiguratorUIConstants.cameraSheetSize.height
                    )
                    .padding()
            }
        }
    }

    // MARK: - Center Panel

    var centerBrandingPanel: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 42, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 42, style: .continuous)
                        .fill(panelTint)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 42, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    nvidiaGreen.opacity(0.45),
                                    nvidiaHighlight.opacity(0.22),
                                    Color.white.opacity(0.08),
                                    nvidiaGreen.opacity(0.18)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.25
                        )
                )
                .shadow(color: nvidiaGreen.opacity(0.16), radius: 22, y: 0)
                .shadow(color: Color.black.opacity(0.38), radius: 30, y: 18)

            VStack(spacing: 28) {
                Spacer(minLength: 10)

                ZStack {
                    RadialGradient(
                        colors: [
                            nvidiaHighlight.opacity(0.22),
                            nvidiaGreen.opacity(0.14),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 20,
                        endRadius: 220
                    )
                    .frame(width: 460, height: 180)
                    .blur(radius: 26)

                    VStack(spacing: 18) {
                        brandedTitle(fontSize: 56)

                        Image("omnicool_logo")
                            .resizable()
                            .interpolation(.high)
                            .antialiased(true)
                            .scaledToFit()
                            .frame(maxWidth: 520)
                            .contrast(1.12)
                            .saturation(1.06)
                            .shadow(color: nvidiaGreen.opacity(0.18), radius: 18, y: 0)
                            .shadow(color: Color.black.opacity(0.40), radius: 14, y: 8)
                    }
                }

                Image("bottom_logos")
                    .resizable()
                    .interpolation(.high)
                    .antialiased(true)
                    .scaledToFit()
                    .frame(maxWidth: 560)
                    .contrast(1.12)
                    .saturation(1.04)
                    .shadow(color: Color.black.opacity(0.34), radius: 12, y: 7)

                Spacer(minLength: 8)
            }
            .padding(.horizontal, 44)
            .padding(.vertical, 42)
        }
        .frame(maxWidth: 860, minHeight: 440)
        .padding(.horizontal, 24)
    }

    // MARK: - Bottom Ornament

    var bottomOrnament: some View {
        HStack(spacing: 16) {
            Button {
                section = .configure
            } label: {
                brandedTitle(fontSize: 20)
            }
            .selectedStyle(isSelected: section == .configure)

            Button {
                showDebugPopup = true
            } label: {
                Image(systemName: "ellipsis")
                    .foregroundStyle(.white)
            }
            .popover(isPresented: $showDebugPopup) {
                Form {
                    Button("Disconnect", role: .destructive) {
                        appModel.showDisconnectionAlert = true
                    }
                    .confirmationDialog(
                        "Do you really want to disconnect?",
                        isPresented: Binding(
                            get: { appModel.showDisconnectionAlert },
                            set: { appModel.showDisconnectionAlert = $0 }
                        ),
                        titleVisibility: .visible
                    ) {
                        Button("Disconnect", role: .destructive) {
                            appModel.session?.disconnect()
                        }
                        Button("Cancel", role: .cancel) {}
                    }

                    if showDebugUI {
                        Button("Network Debug") {
                            section = .hud
                            showDebugPopup = false
                        }
                        .selectedStyle(isSelected: section == .hud)
                    }
                }
                .formStyle(.grouped)
                .padding(.vertical)
                .frame(width: 300, height: showDebugUI ? 150 : 95)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(
            Capsule()
                .fill(panelTint.opacity(0.65))
        )
        .overlay(
            Capsule()
                .stroke(nvidiaGreen.opacity(0.28), lineWidth: 1.1)
        )
        .shadow(color: nvidiaGreen.opacity(0.12), radius: 18, y: 0)
        .shadow(color: Color.black.opacity(0.30), radius: 16, y: 8)
    }

    // MARK: - Reusable Branding Title

    @ViewBuilder
    func brandedTitle(fontSize: CGFloat) -> some View {
        Text("OMNICOOL.")
            .font(.system(size: fontSize, weight: .black, design: .rounded))
            .tracking(fontSize >= 40 ? 2.2 : 1.4)
            .foregroundStyle(
                LinearGradient(
                    colors: [
                        nvidiaHighlight,
                        nvidiaGreen,
                        Color.white.opacity(0.92)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .shadow(color: nvidiaGreen.opacity(0.20), radius: 8, y: 0)
            .shadow(color: Color.black.opacity(0.35), radius: 8, y: 4)
    }

    // MARK: - Helpers

    var portalSymbol: String {
        switch configuratorViewModel.currentViewing.mode {
        case .portal:
            "cube.fill"
        case .tabletop:
            configuratorViewModel.isPlacing ? "arrow.down" : "cube"
        }
    }

    var portalHelp: String {
        switch configuratorViewModel.currentViewing.mode {
        case .portal:
            "Toggle AR View"
        case .tabletop:
            configuratorViewModel.isPlacing ? "Placing model" : "Toggle Portal View"
        }
    }

    var cameraHelp: String {
        switch configuratorViewModel.currentViewing.mode {
        case .portal:
            "Change Portal View"
        case .tabletop:
            "Only available in portal"
        }
    }

    var cameraImage: Image {
        Image(systemName: showCameras ? "video" : "video.fill")
    }
}

#Preview {
    @Previewable @State var appModel = AppModel()
    @Previewable @State var configuratorViewModel = ConfiguratorViewModel()
    @Previewable @State var configuratorAppModel = ConfiguratorAppModel()

    appModel.application = .generic_scene
    appModel.session = CloudXRSession(config: Config())

    configuratorAppModel
        .setup(
            application: appModel.application,
            configuratorViewModel: configuratorViewModel,
            session: appModel.session!
        )

    return OmniConfigurator(application: $appModel.application)
        .environment(appModel)
        .environment(configuratorViewModel)
        .environment(configuratorAppModel)
}
