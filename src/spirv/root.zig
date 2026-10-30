// https://github.com/KhronosGroup/SPIRV-Headers/blob/main/include/spirv/spir-v.xml
const std = @import("std");
const spv = @import("enums.zig");

pub const SpirVOp = struct {
    raw: RawSpirVOp,
    operands: std.ArrayList(u32),

    pub fn new(raw: RawSpirVOp, allocator: std.mem.Allocator) !SpirVOp {
        var l = try std.ArrayList(u32).initCapacity(allocator, @as(usize, raw.wc() - 1));

        try l.resize(allocator, raw.wc() - 1);

        return .{ .raw = raw, .operands = l };
    }

    pub fn feed(self: *SpirVOp, io: std.Io, file: std.Io.File, offset: usize) !void {
        if (self.raw.wc() == 1)
            return;

        _ = try file.readPositionalAll(io, std.mem.sliceAsBytes(self.operands.items), offset);
    }

    pub fn printOperands(self: *SpirVOp, writer: *std.Io.Writer) !void {
        switch (self.raw.opcode()) {
            .OpCapability => {
                for (self.operands.items) |item| {
                    const cap: spv.SpvCapability = @fromBackingInt(item);
                    try writer.print("{} ", .{cap});
                }
            },
            .OpMemoryModel => {
                //if (self.raw.wc < 3) {
                //
                // }
            },
            else => {},
        }
    }

    pub fn deinit(self: *SpirVOp, allocator: std.mem.Allocator) void {
        self.operands.deinit(allocator);
    }
};

pub const RawSpirVOp = extern struct {
    op: u32,

    pub fn wc(self: *const RawSpirVOp) u16 {
        return @intCast((self.op >> 16) & 0xffff);
    }

    pub fn opcode(self: *const RawSpirVOp) spv.SpvOpCode {
        return @fromBackingInt(@intCast(self.op & 0xffff));
    }
};

pub const SpirVHeader = extern struct {
    magic_number: u32,
    version: u32,
    gen_magic_number: u32,
    bound: u32,
    _reserved: u32,

    pub fn is_valid(self: *const SpirVHeader) bool {
        return self.magic_number == 0x07230203;
    }

    pub fn tool_id_string(self: *const SpirVHeader) []const u8 {
        return switch (self.tool_id()) {
            0 => "Khronos",
            1 => "LunarG",
            2 => "Valve",
            3 => "Codeplay",
            4 => "NVIDIA",
            5 => "ARM",
            6 => "Khronos LLVM/SPIR-V Translator",
            7 => "Khronos SPIR-V Tools Assembler",
            8 => "Khronos Glslang Reference Front End",
            9 => "Qualcomm",
            10 => "AMD",
            11 => "Intel",
            12 => "Imagination",
            13 => "Google Shaderc over Glslang",
            14 => "Google spiregg",
            15 => "Google rspirv",
            16 => "X-LEGEND Mesa3D GLSL-IR/SPIR-V Translator",
            17 => "Khronos SPIR-V Tools Linker",
            18 => "Wine VKD3D Shader Compiler",
            19 => "Tellusim Clay Shader Compiler",
            20 => "W3C WebGPU Group WHLSL Shader Translator",
            21 => "Google Clspv",
            22 => "LLVM MLIR SPIR-V Serializer",
            23 => "Google Tint Compiler",
            24 => "Google ANGLE Shader Compiler",
            25 => "Netease Games Messiah Shader Compiler",
            26 => "Xenia Xenia Emulator Microcode Translator",
            27 => "Embark Studios Rust GPU Compiler Backend",
            28 => "gfx-rs community Naga",
            29 => "Mikkosoft Productions MSP Shader Compiler",
            30 => "SpvGenTwo community SpvGenTwo SPIR-V IR Tools",
            31 => "Google Skia SkSL",
            32 => "TornadoVM Beehive SPIRV Toolkit",
            33 => "DragonJoker ShaderWriter",
            34 => "Rayan Hatout SPIRVSmith",
            35 => "Saarland University Shady",
            36 => "Taichi Graphics Taichi",
            37 => "heroseh Hero C Compiler",
            38 => "Meta SparkSL",
            39 => "SirLynix Nazara ShaderLang Compiler",
            40 => "Khronos Slang Compiler",
            41 => "Zig Software Foundation Zig Compiler",
            42 => "Rendong Liang spq",
            43 => "LLVM LLVM SPIR-V Backend",
            44 => "Robert Konrad Kongruent",
            45 => "Kitsunebi Games Nuvk SPIR-V Emitter and DLSL compiler",
            46 => "Nintendo",
            47 => "ARM",
            48 => "Goopax",
            49 => "Icyllis Milica Arc3D Shader Compiler",
            50 => "Isochron Pred",
            51 => "apilatosba Apila Jai Compiler",
            else => "??",
        };
    }

    pub fn tool_id(self: *const SpirVHeader) u16 {
        return @intCast((self.gen_magic_number >> 16) & 0xffff);
    }

    pub fn tool_version(self: *const SpirVHeader) u16 {
        return @intCast(self.gen_magic_number & 0xffff);
    }

    pub fn major(self: *const SpirVHeader) u8 {
        return @intCast((self.version >> 16) & 0xff);
    }

    pub fn minor(self: *const SpirVHeader) u8 {
        return @intCast((self.version >> 8) & 0xff);
    }
};
