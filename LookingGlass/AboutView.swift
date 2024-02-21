import SwiftUI
import UniformTypeIdentifiers
import OSLog

struct AboutView: View {
    let logger = Logger(subsystem: "LookingGlass", category: "About")
    var body: some View {
        VStack {
            Image("AboutImage")
                .resizable()
                .scaledToFit()
                .frame(width: 256, height: 256)
                .onAppear() {
                    logger.debug("AboutView.appear")
                }
                .onDisappear() {
                    logger.debug("AboutView.disappear")
                }
            Text("LookingGlass: Virtual Display Manager")
            Text("[Github](https://github.com/putgeminmouth/LookingGlass)")
        }
        .padding(20)
    }
}
