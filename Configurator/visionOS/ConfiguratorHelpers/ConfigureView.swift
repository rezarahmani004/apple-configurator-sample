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

struct ConfigureView: View {
    @Environment(ConfiguratorAppModel.self) var configuratorAppModel
    @Environment(ConfiguratorViewModel.self) var configuratorViewModel

    var body: some View {
        EmptyView()
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

    return ConfigureView()
        .environment(configuratorAppModel)
        .environment(configuratorViewModel)
        .environment(appModel)
}
