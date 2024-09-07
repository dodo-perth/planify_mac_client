import SwiftUI

struct SelectionOverlay: View {
    @Binding var selectionRect: CGRect
    @Binding var isDragging: Bool
    @State private var startPoint: CGPoint = .zero
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.opacity(0.5)
                    .edgesIgnoringSafeArea(.all)
                
                Path { path in
                    path.addRect(geometry.frame(in: .global))
                    path.addRect(selectionRect)
                }
                .fill(style: FillStyle(eoFill: true))
                
                Rectangle()
                    .stroke(Color.white, lineWidth: 2)
                    .frame(width: selectionRect.width, height: selectionRect.height)
                    .position(x: selectionRect.midX, y: selectionRect.midY)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        if !isDragging {
                            startPoint = value.location
                            isDragging = true
                        }
                        let width = value.location.x - startPoint.x
                        let height = value.location.y - startPoint.y
                        selectionRect = CGRect(x: startPoint.x, y: startPoint.y, width: width, height: height)
                    }
                    .onEnded { _ in
                        isDragging = false
                    }
            )
        }
    }
}
