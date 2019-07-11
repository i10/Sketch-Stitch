import Metal
import MetalKit
import simd

struct FilterParameters {
    var minR : Float = 0
    var minG : Float = 0
    var minB : Float = 0
    var maxR : Float = 1
    var maxG : Float = 1
    var maxB : Float = 1
}

struct Processor {
    private let device: MTLDevice
    private let library: MTLLibrary
    
    init() throws {
        guard let device = MTLCreateSystemDefaultDevice() else { throw Error.systemMetalDeviceNotFound }
        
        let libraryFile = Bundle.main.path(forResource: "Filter", ofType: "metallib")
        
        self.library = try device.makeLibrary(filepath: libraryFile!)
        
        self.device = device
    }
}

extension Processor {
    
    
    func run(input: CGImage, parameters: FilterParameters) throws -> MTLTexture {
        
        var params = parameters
        
        let commandQueue = device.makeCommandQueue()
        let commandBuffer = commandQueue?.makeCommandBuffer()
        let commandEncoder = commandBuffer?.makeComputeCommandEncoder()
        
        let kernelFunction = library.makeFunction(name: "filter_rgb")
        
        let computePipelineState = try device.makeComputePipelineState(function: kernelFunction!)
        
        let textureLoader = MTKTextureLoader(device: device)
        
        let textureLoaderOption = [
            MTKTextureLoader.Option.allocateMipmaps: NSNumber(value: false),
            MTKTextureLoader.Option.SRGB: NSNumber(value: false)
        ]
        
        guard let texture = try? textureLoader.newTexture(cgImage: input, options: textureLoaderOption) else {
            throw Error.imageDataNotFound(name: "R", path: FileManager.default.currentDirectoryPath)
        }
        
        let outTextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .rgba8Unorm,
            width: texture.width,
            height: texture.height,
            mipmapped: false
        )
        outTextureDescriptor.usage = [.shaderWrite, .shaderRead]
        guard let outTexture = device.makeTexture(descriptor: outTextureDescriptor) else {
            throw Error.failedToMakeTexture
        }
        
        let threads = makeThreadgroups(textureWidth: outTexture.width, textureHeight: outTexture.height)
        
        commandEncoder?.setComputePipelineState(computePipelineState)
        commandEncoder?.setTexture(texture, index: 0)
        commandEncoder?.setTexture(outTexture, index: 1)
        commandEncoder?.setBytes(&params, length: MemoryLayout<FilterParameters>.stride, index: 0)
        
        commandEncoder?.dispatchThreadgroups(threads.threadgroupsPerGrid, threadsPerThreadgroup: threads.threadsPerThreadgroup)
        commandEncoder?.endEncoding()
        
        let syncEncoder = commandBuffer?.makeBlitCommandEncoder()
        syncEncoder?.synchronize(resource: outTexture)
        syncEncoder?.endEncoding()
        
        commandBuffer?.commit()
        commandBuffer?.waitUntilCompleted()
        
        return outTexture
    }
}

private extension Processor {
    func makeThreadgroups(textureWidth: Int, textureHeight: Int) -> (threadgroupsPerGrid: MTLSize, threadsPerThreadgroup: MTLSize) {
        let threadSize = 16
        let threadsPerThreadgroup = MTLSizeMake(threadSize, threadSize, 1)
        let horizontalThreadgroupCount = textureWidth / threadsPerThreadgroup.width + 1
        let verticalThreadgroupCount = textureHeight / threadsPerThreadgroup.height + 1
        let threadgroupsPerGrid = MTLSizeMake(horizontalThreadgroupCount, verticalThreadgroupCount, 1)
        
        return (threadgroupsPerGrid: threadgroupsPerGrid, threadsPerThreadgroup: threadsPerThreadgroup)
    }
}

extension Processor {
    enum Error: Swift.Error, CustomStringConvertible {
        case libraryNotFound
        case systemMetalDeviceNotFound
        case unsuppoertedExtension
        case imageDataNotFound(name: String, path: String)
        case failedToMakeTexture
        case kernelFunctionNotFound(inputFunction: String, availableFunctions: [String])
        
        var description: String {
            switch self {
            case .libraryNotFound: return "default.metallib not found."
            case .systemMetalDeviceNotFound: return "Seems system metal device is unavailable."
            case .unsuppoertedExtension: return "Unsupported file extension is used."
            case .imageDataNotFound(let name, let path): return "'\(name)' doesn't exist in '\(path)'"
            case .failedToMakeTexture: return "Failed to make texture."
            case .kernelFunctionNotFound(let inputFunction, let availableFunctions):
                let listText = availableFunctions.reduce("") { acc, value in
                    return acc + "\(value), "
                    }.dropLast(2)
                return "\(inputFunction) is unavailable.\n" + "Available functions: [" + listText + "]"
            }
        }
    }
}
