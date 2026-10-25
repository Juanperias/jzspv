const std = @import("std");
const Io = std.Io;

const spirv = @import("spirv");

pub fn main(init: std.process.Init) !void {
    const stdout = std.Io.File.stdout();
    var buffer: [4096]u8 = undefined;
    var stdout_writer = std.Io.File.writer(stdout, init.io, &buffer);
    const output = &stdout_writer.interface;

    const file = try std.Io.Dir.cwd().openFile(init.io, "../shader.frag.spv", .{});
    defer file.close(init.io);

    var header: spirv.SpirVHeader = undefined;

    var n = try file.readPositionalAll(init.io, std.mem.asBytes(&header), 0);

    if (n == 0) {
        std.debug.print("Invalid SPIR-V File!", .{});

        std.process.exit(1);
    }

    try output.print("; SPIR-V\n", .{});
    try output.print("; Version: {}.{}\n", .{ header.major(), header.minor() });
    try output.print("; Generator: {s}; {}\n", .{ header.tool_id_string(), header.tool_version() });
    try output.print("; Bound: {}\n", .{header.bound});
    try output.print("; Schema: {}\n", .{header._reserved});

    try output.flush();

    var op: spirv.SpirVOp = undefined;

    var offset: u64 = @sizeOf(spirv.SpirVHeader);

    const len = try file.length(init.io);

    while (offset < len) {
        n = try file.readPositionalAll(init.io, std.mem.asBytes(&op), offset);

        if (n == 0) {
            std.debug.print("Invalid SPIR-V File!", .{});

            std.process.exit(1);
        }

        try output.print("{}\n", .{op.opcode()});

        offset += op.wc() * 4;
    }

    try output.flush();
}
