// Copyright © 2026 Jack Lusher. All rights reserved.

import Foundation
import ImageIO
import Metal
import UniformTypeIdentifiers

/// The pictures the lab knows: the shader file, the stitchable's name and its floats for a seed and time.
let pictures: [String: (file: String, data: (Int, Double) -> [Float])] = [
    "glass": ("Glass", { Picture.cells(seed: $0, t: $1) }),
    "isobars": ("Flow", { s, _ in Picture.gradients(seed: s, salt: 0x464C_4F57, count: 2) }),
    "ephemeris": ("Sky", { Picture.ephemeris(seed: $0, t: $1, period: 30) }),
    "cords": ("Loom", { s, _ in Picture.gradients(seed: s, salt: 0x4C4F_4F4D, count: 2) }),
]

let usage = """
    usage: scripts/picture-lab.sh render <picture> <out.png> [seed] [t] [side px] [layout stack]
           scripts/picture-lab.sh bench <picture>...
    pictures: \(pictures.keys.sorted().joined(separator: ", "))
    """

let root = URL(fileURLWithPath: CommandLine.arguments[0]).deletingLastPathComponent()
    .deletingLastPathComponent().deletingLastPathComponent()
let device = MTLCreateSystemDefaultDevice()!
let queue = device.makeCommandQueue()!

/// The picture's shader compiled as a plain function, behind a kernel that runs each pixel's taps back through the
/// stack as `unstir` in Unstir.metal does (a copy: change the two together) and evaluates the picture there.
func pipeline(_ name: String) throws -> MTLComputePipelineState {
    let source: String
    if name == "flat" {
        source = "#include <metal_stdlib>\nusing namespace metal;\n"
            + "static half4 flat(float2 pos, float radius, float px, device const float *data, int count, float t) { return half4(half(fract(pos.x * 0.01 + pos.y * 0.013)), 0.5h, 0.5h, 1.0h); }\n"
    } else {
        let url = root.appendingPathComponent("Sources/\(pictures[name]!.file).metal")
        source = try String(contentsOf: url, encoding: .utf8)
            .replacingOccurrences(of: "#include <SwiftUI/SwiftUI_Metal.h>", with: "")
            .replacingOccurrences(of: "[[ stitchable ]]", with: "")
    }
    let kernel = """

        kernel void lab(device float4 *out [[buffer(0)]], device const float *data [[buffer(1)]],
                        constant int &count [[buffer(2)]], device const float *twists [[buffer(3)]],
                        constant int &n [[buffer(4)]], constant float4 &args [[buffer(5)]],
                        uint2 gid [[thread_position_in_grid]]) {
            float radius = args.x, side = 2.0 * radius;
            if (gid.x >= uint(side) || gid.y >= uint(side)) return;
            int taps = int(args.w);
            float3 acc = 0;
            for (int j = 0; j < taps; j++) {
                float2 off = taps == 1 ? 0.0 : (float2(j & 1, j >> 1) - 0.5) * 0.5;
                float2 q = (float2(gid) + 0.5 + off - radius) / radius;
                for (int i = n - 1; i >= 0; i--) {
                    float2 c = float2(twists[4 * i], twists[4 * i + 1]), d = q - c;
                    float s = length(d) / twists[4 * i + 2];
                    if (s >= 1.0) continue;
                    float a = -twists[4 * i + 3] * (1.0 - smoothstep(0.6, 1.0, s));
                    float cs = cos(a), sn = sin(a);
                    q = c + float2(d.x * cs - d.y * sn, d.x * sn + d.y * cs);
                }
                float3 s = float3(\(name)(radius + q * radius, radius, args.y, data, count, args.z).rgb);
                acc += s * s;
            }
            out[gid.y * uint(side) + gid.x] = float4(sqrt(acc / float(taps)), 1.0);
        }
        """
    let library = try device.makeLibrary(source: source + kernel, options: nil)
    return try device.makeComputePipelineState(function: library.makeFunction(name: "lab")!)
}

struct Frame {
    let out: MTLBuffer, data: MTLBuffer, twists: MTLBuffer
    let count: Int32, n: Int32, args: SIMD4<Float>, side: Int
}

func frame(_ data: [Float], _ twists: [Float], side: Int, t: Double, taps: Int) -> Frame {
    let d = data.isEmpty ? [0] : data, w = twists.isEmpty ? [0, 0, 0, 0] : twists
    return Frame(out: device.makeBuffer(length: side * side * 16, options: .storageModeShared)!,
                 data: device.makeBuffer(bytes: d, length: d.count * 4, options: .storageModeShared)!,
                 twists: device.makeBuffer(bytes: w, length: w.count * 4, options: .storageModeShared)!,
                 count: Int32(data.count), n: Int32(twists.count / 4),
                 args: SIMD4(Float(side) / 2, 2 / Float(side), Float(t), Float(taps)), side: side)
}

/// GPU seconds per dispatch over `reps` dispatches of the kernel over the frame, the least of `buffers` command buffers.
func run(_ state: MTLComputePipelineState, _ f: Frame, reps: Int = 1, buffers: Int = 1) -> Double {
    var best = Double.infinity
    for _ in 0..<buffers {
        let buffer = queue.makeCommandBuffer()!
        let enc = buffer.makeComputeCommandEncoder()!
        enc.setComputePipelineState(state)
        var count = f.count, n = f.n, args = f.args
        enc.setBuffer(f.out, offset: 0, index: 0)
        enc.setBuffer(f.data, offset: 0, index: 1)
        enc.setBytes(&count, length: 4, index: 2)
        enc.setBuffer(f.twists, offset: 0, index: 3)
        enc.setBytes(&n, length: 4, index: 4)
        enc.setBytes(&args, length: 16, index: 5)
        for _ in 0..<reps {
            enc.dispatchThreads(MTLSize(width: f.side, height: f.side, depth: 1),
                                threadsPerThreadgroup: MTLSize(width: 16, height: 16, depth: 1))
        }
        enc.endEncoding()
        buffer.commit()
        buffer.waitUntilCompleted()
        best = min(best, (buffer.gpuEndTime - buffer.gpuStartTime) / Double(reps))
    }
    return best
}

func twists(_ layout: String, _ stack: String) -> [Float] {
    guard let layout = Layout(rawValue: layout) else { fatalError("no layout \(layout)") }
    return [Twist].parse(stack, in: layout).flatMap { t -> [Float] in
        let r = layout.rods[t.rod]
        return [Float(r.x), Float(r.y), Float(r.z), Float(Double(t.steps) * Tank.step)]
    }
}

func write(_ f: Frame, to path: String) {
    let p = f.out.contents().bindMemory(to: SIMD4<Float>.self, capacity: f.side * f.side)
    var bytes = [UInt8](repeating: 0, count: f.side * f.side * 4)
    for i in 0..<f.side * f.side {
        for c in 0..<3 { bytes[4 * i + c] = UInt8(min(max(p[i][c], 0), 1) * 255 + 0.5) }
        bytes[4 * i + 3] = 255
    }
    let provider = CGDataProvider(data: Data(bytes) as CFData)!
    let image = CGImage(width: f.side, height: f.side, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: 4 * f.side,
                        space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipLast.rawValue),
                        provider: provider, decode: nil, shouldInterpolate: false, intent: .defaultIntent)!
    let dest = CGImageDestinationCreateWithURL(URL(fileURLWithPath: path) as CFURL, UTType.png.identifier as CFString, 1, nil)!
    CGImageDestinationAddImage(dest, image, nil)
    CGImageDestinationFinalize(dest)
}

let args = Array(CommandLine.arguments.dropFirst())
switch args.first {
case "render" where args.count >= 3 && pictures[args[1]] != nil:
    let seed = args.count > 3 ? Int(args[3])! : 1, t = args.count > 4 ? Double(args[4])! : 3
    let side = args.count > 5 ? Int(args[5])! : 1200
    let w = args.count > 7 ? twists(args[6], args[7]) : []
    let f = frame(pictures[args[1]]!.data(seed, t), w, side: side, t: t, taps: 4)
    _ = run(try pipeline(args[1]), f)
    write(f, to: args[2])
case "bench" where args.count >= 2:
    // The phone's tank is about 1284 px across. A stack entry is one entry of the chain, four taps, on a flat picture.
    // Kernels take turns, 15 rounds of 100 dispatches each, and each reads its median: the Mac's GPU clock wanders.
    let side = 1284, flat = try pipeline("flat")
    let chain = twists("hex", (0..<24).map { "\($0 % 7):+\(1 + $0 % 5)" }.joined(separator: ","))
    let names = ["glass"] + args.dropFirst().filter({ $0 != "glass" && pictures[$0] != nil })
    var jobs: [(MTLComputePipelineState, Frame)] = [(flat, frame([], [], side: side, t: 0, taps: 4)),
                                                    (flat, frame([], chain, side: side, t: 0, taps: 4)),
                                                    (flat, frame([], [], side: side, t: 0, taps: 1))]
    for name in names { jobs.append((try pipeline(name), frame(pictures[name]!.data(1, 3), [], side: side, t: 3, taps: 1))) }
    let start = Date()
    while Date().timeIntervalSince(start) < 3 { _ = run(flat, jobs[1].1, reps: 20) }
    var times = [[Double]](repeating: [], count: jobs.count)
    for _ in 0..<15 { for (k, job) in jobs.enumerated() { times[k].append(run(job.0, job.1, reps: 100, buffers: 1)) } }
    let median = times.map { $0.sorted()[$0.count / 2] }
    let entry = (median[1] - median[0]) / 24
    print(String(format: "one stack entry, four taps: %.3f ms", entry * 1000))
    let glass = median[3] - median[2]
    for (k, name) in names.enumerated() {
        let cost = median[3 + k] - median[2]
        print(String(format: "%@: %.3f ms, %.2f entries measured, %.2f scaled to the glass's 4", name, cost * 1000,
                     cost / entry, 4 * cost / glass))
    }
default:
    print(usage)
    exit(2)
}
