import Foundation

/// User-controlled color tweaks applied before the image is turned to grayscale.
/// Hue matters even though the result ends up gray: the grayscale weights differ per
/// channel, so rotating hue changes which areas come out dark.
public struct ColorAdjustments: Sendable, Equatable {
    /// Hue rotation in degrees.
    public var hue: Double = 0
    /// 0 = fully desaturated, 1 = unchanged, >1 = boosted.
    public var saturation: Double = 1
    /// Output = input ^ gamma (normalized). <1 brightens, >1 darkens.
    public var gamma: Double = 1
    /// Swap light and dark, for light subjects on a dark background.
    public var invert = false

    public init(hue: Double = 0, saturation: Double = 1, gamma: Double = 1, invert: Bool = false) {
        self.hue = hue
        self.saturation = saturation
        self.gamma = gamma
        self.invert = invert
    }

    public static let identity = ColorAdjustments()
    public var isIdentity: Bool { self == .identity }

    /// Row-major 3x3 matrix: hue rotation followed by saturation
    /// (the standard luminance-preserving SVG/CSS color matrices).
    var colorMatrix: [Float] {
        let rad = hue * .pi / 180
        let c = cos(rad), s = sin(rad)
        let hueM: [Double] = [
            0.213 + c * 0.787 - s * 0.213, 0.715 - c * 0.715 - s * 0.715, 0.072 - c * 0.072 + s * 0.928,
            0.213 - c * 0.213 + s * 0.143, 0.715 + c * 0.285 + s * 0.140, 0.072 - c * 0.072 - s * 0.283,
            0.213 - c * 0.213 - s * 0.787, 0.715 - c * 0.715 + s * 0.715, 0.072 + c * 0.928 + s * 0.072,
        ]
        let t = saturation
        let satM: [Double] = [
            0.213 + 0.787 * t, 0.715 - 0.715 * t, 0.072 - 0.072 * t,
            0.213 - 0.213 * t, 0.715 + 0.285 * t, 0.072 - 0.072 * t,
            0.213 - 0.213 * t, 0.715 - 0.715 * t, 0.072 + 0.928 * t,
        ]
        var out = [Float](repeating: 0, count: 9)
        for r in 0..<3 {
            for col in 0..<3 {
                var sum = 0.0
                for k in 0..<3 { sum += satM[r * 3 + k] * hueM[k * 3 + col] }
                out[r * 3 + col] = Float(sum)
            }
        }
        return out
    }

    /// Per-channel lookup table for gamma + invert.
    var toneCurve: [UInt8] {
        (0..<256).map { i in
            var v = pow(Double(i) / 255, max(gamma, 0.01))
            if invert { v = 1 - v }
            return UInt8((v * 255).rounded())
        }
    }
}

extension RGBAImage {
    public func adjusted(_ adjustments: ColorAdjustments) -> RGBAImage {
        if adjustments.isIdentity { return self }
        let m = adjustments.colorMatrix
        let lut = adjustments.toneCurve
        let matrixIsIdentity = adjustments.hue == 0 && adjustments.saturation == 1
        var out = pixels
        out.withUnsafeMutableBufferPointer { p in
            lut.withUnsafeBufferPointer { lut in
                for i in stride(from: 0, to: p.count, by: 4) {
                    if matrixIsIdentity {
                        p[i] = lut[Int(p[i])]
                        p[i + 1] = lut[Int(p[i + 1])]
                        p[i + 2] = lut[Int(p[i + 2])]
                        continue
                    }
                    let r = Float(p[i]), g = Float(p[i + 1]), b = Float(p[i + 2])
                    p[i] = lut[Self.clampIndex(m[0] * r + m[1] * g + m[2] * b)]
                    p[i + 1] = lut[Self.clampIndex(m[3] * r + m[4] * g + m[5] * b)]
                    p[i + 2] = lut[Self.clampIndex(m[6] * r + m[7] * g + m[8] * b)]
                }
            }
        }
        return RGBAImage(width: width, height: height, pixels: out)
    }

    /// Luminance grayscale (Rec. 601 weights, same as the original Dart `image` package).
    public func grayscale() -> GrayImage {
        var gray = [UInt8](repeating: 0, count: width * height)
        pixels.withUnsafeBufferPointer { p in
            gray.withUnsafeMutableBufferPointer { g in
                for i in 0..<g.count {
                    let r = Float(p[i * 4]), gr = Float(p[i * 4 + 1]), b = Float(p[i * 4 + 2])
                    g[i] = UInt8(min(255, (0.299 * r + 0.587 * gr + 0.114 * b).rounded()))
                }
            }
        }
        return GrayImage(width: width, height: height, pixels: gray)
    }

    @inline(__always)
    private static func clampIndex(_ v: Float) -> Int {
        Int(min(max(v, 0), 255).rounded())
    }
}
