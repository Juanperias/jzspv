const std = @import("std");
const spirv = @import("root.zig");
const spv = spirv.spv;

pub const DisplayCtx = struct {
    symbols: std.AutoHashMap(u32, []const u8),

    pub fn init(allocator: std.mem.Allocator) DisplayCtx {
        return .{
            .symbols = std.AutoHashMap(u32, []const u8).init(allocator),
        };
    }

    // TODO!
    // pub fn feed() {}

    pub fn print(self: *DisplayCtx, ins: spirv.SpirVIns, writer: *std.Io.Writer) !void {
        _ = self;
        switch (ins) {
            .capability => |cap| {
                try writer.print("OpCapability {s}\n", .{@tagName(cap)});
            },
            .memory_model => |mem| {
                try writer.print("OpMemoryModel {s} {s}\n", .{ @tagName(mem.addr), @tagName(mem.mem) });
            },
            .ext_inst_import => |ins_import| {
                try writer.print("%{} = OpExtInstImport \"{s}\"\n", .{ ins_import.result_id, ins_import.name });
            },
            .source => |s| {
                try writer.print("OpSource {s} {}\n", .{ @tagName(s.source_lang), s.version });
            },
            .source_extension => |ext| {
                try writer.print("OpSourceExtension \"{s}\"\n", .{ext});
            },
            .name => |name| {
                try writer.print("OpName %{} \"{s}\"\n", .{ name.id_target, name.name });
            },
            .execution_mode => |exe| {
                try writer.print("OpExecutionMode %{} {s}\n", .{ exe.entry_point, @tagName(exe.mode) });
            },
            .entry_point => |entry| {
                try writer.print("OpEntryPoint {s} %{} \"{s}\" %{} %{}\n", .{ @tagName(entry.execution_model), entry.entry_point, entry.name, entry.interface_id_1, entry.interface_id_2 });
            },
            .decoration => |dec| {
                try writer.print("OpDecorate %{} {s} ", .{ dec.id_target, @tagName(dec.decoration) });

                switch (dec.extra_operand) {
                    .literal => |lit| {
                        try writer.print("{}", .{lit});
                    },
                    .build_in => |b| {
                        try writer.print("{s}", .{@tagName(b)});
                    },
                    else => {},
                }

                try writer.print("\n", .{});
            },
            else => {},
        }
    }

    pub fn deinit(self: *DisplayCtx) void {
        self.symbols.deinit();
    }
};
