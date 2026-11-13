// https://github.com/KhronosGroup/SPIRV-Headers/blob/main/include/spirv/spir-v.xml
const std = @import("std");
pub const spv = @import("enums.zig");
pub const display = @import("display.zig");

pub const SpirVError = error{ InvalidWC, WriteFailed };

pub const SpirVIns = union(enum) {
    capability: spv.SpvCapability,
    memory_model: struct { addr: spv.SpvAddressingModel, mem: spv.SpvMemoryModel },
    ext_inst_import: struct {
        result_id: u32,
        name: []const u8,
    },
    source: struct { source_lang: spv.SpvSourceLanguage, version: u32 },
    source_extension: []const u8,
    name: struct {
        id_target: u32,
        name: []const u8,
    },
    entry_point: struct {
        execution_model: spv.SpvExecutionModel,
        entry_point: u32,
        name: []const u8,
        interface_id_1: u32,
        interface_id_2: u32,
    },
    decoration: struct {
        id_target: u32,
        decoration: spv.SpvDecoration,
        extra_operand: spv.DecorationExtraOperand,
    },
    execution_mode: struct {
        entry_point: u32,
        mode: spv.SpvExecutionMode,
    },
    _return: void,
    function_end: void,
    _unk: void,
};

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

    pub fn decode(self: *SpirVOp) SpirVError!SpirVIns {
        switch (self.raw.opcode()) {
            .OpCapability => {
                const capability: spv.SpvCapability = @fromBackingInt(self.operands.items[0]);

                return .{
                    .capability = capability,
                };
            },
            .OpMemoryModel => {
                if (self.raw.wc() != 3) {
                    std.debug.print("Word Count Should be 3, but it is {}", .{self.raw.wc()});
                    return SpirVError.InvalidWC;
                }

                const addr_model_word = self.operands.items[0];
                const memory_model_word = self.operands.items[1];

                const addr_model: spv.SpvAddressingModel = @fromBackingInt(addr_model_word);
                const memory_model: spv.SpvMemoryModel = @fromBackingInt(memory_model_word);

                return .{
                    .memory_model = .{
                        .addr = addr_model,
                        .mem = memory_model,
                    },
                };
            },
            .OpFunctionEnd => {
                return SpirVIns{
                    .function_end = {},
                };
            },
            .OpReturn => {
                return SpirVIns{
                    ._return = {},
                };
            },
            .OpExtInstImport => {
                const id = self.operands.items[0];
                const raw = std.mem.sliceAsBytes(self.operands.items[1 .. self.raw.wc() - 2]);

                return .{
                    .ext_inst_import = .{
                        .result_id = id,
                        .name = raw[0..detect_spv_string_end(raw)],
                    },
                };
            },
            .OpEntryPoint => {
                // WAIT!!!!!!!! MAGIC NUMBER DETECTED!!!!!!!!!!!!!!! THE 2 IS BECAUSE DE STRING STARTS AT POSITION 2
                const name_len = 2 + detect_spv_string_end_operands(self.operands.items[2..]);
                const name = std.mem.sliceAsBytes(self.operands.items[2..name_len]);

                return SpirVIns{
                    .entry_point = .{
                        .execution_model = @fromBackingInt(self.operands.items[0]),
                        .entry_point = self.operands.items[1],
                        .name = name,
                        // TODO NOTE: this code can be buggy
                        .interface_id_1 = self.operands.items[name_len + 1],
                        .interface_id_2 = self.operands.items[name_len + 2],
                    },
                };
            },
            .OpSource => {
                const source_language: spv.SpvSourceLanguage = @fromBackingInt(self.operands.items[0]);
                const version = self.operands.items[1];

                return .{
                    .source = .{
                        .source_lang = source_language,
                        .version = version,
                    },
                };
            },
            .OpSourceExtension => {
                const raw = std.mem.sliceAsBytes(self.operands.items[0 .. self.raw.wc() - 1]);

                return .{
                    .source_extension = raw[0..detect_spv_string_end(raw)],
                };
            },
            .OpName => {
                const raw = std.mem.sliceAsBytes(self.operands.items[1 .. self.raw.wc() - 1]);

                return .{
                    .name = .{ .id_target = self.operands.items[0], .name = raw[0..detect_spv_string_end(raw)] },
                };
            },
            .OpDecorate => {
                // NOTE: This behavior is used in other op so this should be in a function or something like that

                const decoration: spv.SpvDecoration = @fromBackingInt(self.operands.items[1]);
                var extra_op: spv.DecorationExtraOperand = undefined;

                switch (decoration) {
                    .BuiltIn => {
                        extra_op = spv.DecorationExtraOperand{
                            .build_in = @fromBackingInt(self.operands.items[2]),
                        };
                    },
                    .SpecId, .ArrayStride, .MatrixStride, .UniformId, .Stream, .Location, .Component, .Index, .Binding, .DescriptorSet, .Offset, .XfbBuffer, .XfbStride => {
                        extra_op = spv.DecorationExtraOperand{
                            .literal = self.operands.items[2],
                        };
                    },
                    else => {
                        extra_op = spv.DecorationExtraOperand{
                            .none = {},
                        };
                    },
                }

                return .{
                    .decoration = .{
                        .id_target = self.operands.items[0],
                        .decoration = decoration,
                        .extra_operand = extra_op,
                    },
                };
            },
            .OpExecutionMode => {
                return SpirVIns{
                    .execution_mode = .{
                        .entry_point = self.operands.items[0],
                        .mode = @fromBackingInt(self.operands.items[1]),
                    },
                };
            },
            else => {
                return .{
                    ._unk = {},
                };
            },
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

pub fn detect_spv_string_end_operands(spv_operands: []const u32) usize {
    var end: usize = 0;

    for (spv_operands) |spv_operand| {
        const m: []const u8 = std.mem.asBytes(&spv_operand);

        if (m[0] == 0 or m[1] == 0 or m[2] == 0 or m[3] == 0) {
            break;
        }

        end += 1;
    }

    return end;
}

pub fn detect_spv_string_end(spv_str: []const u8) usize {
    var end: usize = 0;

    for (spv_str) |m| {
        if (m == 0) {
            break;
        }

        end += 1;
    }

    return end;
}
