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

    pub fn print(self: *DisplayCtx, ins: spirv.SpirVIns, writer: *std.Io.Writer) !void {
        _ = self;
        switch (ins.operands) {
            .capability => |cap| {
                try writer.print("OpCapability {s}\n", .{@tagName(cap)});
            },
            .memory_model => |mem| {
                try writer.print("OpMemoryModel {s} {s}\n", .{ @tagName(mem.addr), @tagName(mem.mem) });
            },
            // ....and then!
            else => {},
        }
    }

    pub fn deinit(self: *DisplayCtx) void {
        self.symbols.deinit();
    }
};
