//
//  ContentView.swift
//  BrainVision
//
//  Created by John Brewer on 9/14/24.
//

import SwiftUI
import RealityKit
import RealityKitContent

struct ContentView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    @Environment(\.dismissWindow) private var dismissWindow

    var body: some View {
        VStack {
            Model3D(named: "Scene", bundle: realityKitContentBundle)
                .padding(.bottom, 50)

            Text("Hello, world!")

            ToggleImmersiveSpaceButton()
        }
        .padding()
        .task {
            switch await openImmersiveSpace(id: "ImmersiveSpace") {
            case .opened:
                dismissWindow(id: "MainWindow")
            case .userCancelled:
                break
            case .error:
                break
            @unknown default:
                break
            }

        }
    }
}

#Preview(windowStyle: .automatic) {
    ContentView()
        .environment(AppModel())
}
