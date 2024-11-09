import SwiftUI

struct ScreenshotSelectionView: View {
    @Binding var selectionRect: CGRect
    @Binding var isDragging: Bool
    @Binding var showScreenshotSelection: Bool
    var onCapture: () -> Void
    
    @State private var startPoint: CGPoint = .zero
    @State private var showDimensions = false
    @State private var showMagnifier = false
    @State private var magnifierPosition: CGPoint = .zero
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 반투명 오버레이
                Color.black.opacity(0.5)
                    .edgesIgnoringSafeArea(.all)
                
                // 선택 영역 컷아웃
                Path { path in
                    path.addRect(geometry.frame(in: .global))
                    path.addRect(selectionRect)
                }
                .fill(style: FillStyle(eoFill: true))
                
                // 선택 영역 테두리
                SelectionBorder(rect: selectionRect)
                
                // 치수 표시
                if showDimensions {
                    DimensionsView(rect: selectionRect)
                }
                
                // 돋보기
                if showMagnifier {
                    MagnifierView(position: magnifierPosition)
                }
                
                // 컨트롤 버튼
                VStack {
                    Spacer()
                    HStack(spacing: 20) {
                        Button("Cancel") {
                            showScreenshotSelection = false
                        }
                        .buttonStyle(ControlButtonStyle(color: .red))
                        
                        Button("Capture") {
                            if selectionRect.width > 0 && selectionRect.height > 0 {
                                onCapture()
                            }
                        }
                        .buttonStyle(ControlButtonStyle(color: .green))
                        .disabled(selectionRect.width <= 0 || selectionRect.height <= 0)
                    }
                    .padding(.bottom, 20)
                }
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        handleDragGesture(value)
                    }
                    .onEnded { _ in
                        handleDragEnd()
                    }
            )
            .onAppear {
                NSCursor.crosshair.push()
            }
            .onDisappear {
                NSCursor.pop()
            }
        }
    }
    
    private func handleDragGesture(_ value: DragGesture.Value) {
        if !isDragging {
            startPoint = value.location
            isDragging = true
        }
        
        let width = value.location.x - startPoint.x
        let height = value.location.y - startPoint.y
        
        selectionRect = CGRect(
            x: width > 0 ? startPoint.x : value.location.x,
            y: height > 0 ? startPoint.y : value.location.y,
            width: abs(width),
            height: abs(height)
        )
        
        showDimensions = true
        showMagnifier = true
        magnifierPosition = value.location
    }
    
    private func handleDragEnd() {
        isDragging = false
        showMagnifier = false
        
        // 최소 크기 확인
        if selectionRect.width < 10 || selectionRect.height < 10 {
            selectionRect = .zero
        }
    }
}

// MARK: - Supporting Views
struct SelectionBorder: View {
    let rect: CGRect
    
    var body: some View {
        Rectangle()
            .stroke(Color.white, lineWidth: 2)
            .frame(width: rect.width, height: rect.height)
            .position(x: rect.midX, y: rect.midY)
            .overlay(
                ResizeHandles(rect: rect)
            )
    }
}

struct DimensionsView: View {
    let rect: CGRect
    
    var body: some View {
        Text("\(Int(rect.width)) x \(Int(rect.height))")
            .font(.system(size: 12))
            .foregroundColor(.white)
            .padding(4)
            .background(Color.black.opacity(0.7))
            .cornerRadius(4)
            .position(x: rect.midX, y: rect.maxY + 20)
    }
}

struct MagnifierView: View {
    let position: CGPoint
    
    var body: some View {
        Circle()
            .fill(Color.white)
            .frame(width: 80, height: 80)
            .overlay(
                Circle()
                    .stroke(Color.gray, lineWidth: 2)
            )
            .position(x: position.x + 40, y: position.y - 40)
    }
}

struct ResizeHandles: View {
    let rect: CGRect
    
    var body: some View {
        ZStack {
            ForEach(0..<4) { i in
                Rectangle()
                    .fill(Color.white)
                    .frame(width: 8, height: 8)
                    .position(handlePosition(for: i))
            }
        }
    }
    
    private func handlePosition(for index: Int) -> CGPoint {
        switch index {
        case 0: return CGPoint(x: 0, y: 0)
        case 1: return CGPoint(x: rect.width, y: 0)
        case 2: return CGPoint(x: rect.width, y: rect.height)
        case 3: return CGPoint(x: 0, y: rect.height)
        default: return .zero
        }
    }
}

struct ControlButtonStyle: ButtonStyle {
    let color: Color
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
            .background(color.opacity(configuration.isPressed ? 0.7 : 1))
            .foregroundColor(.white)
            .cornerRadius(8)
            .shadow(radius: 2)
    }
}
