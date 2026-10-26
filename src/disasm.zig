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

    const len = try file.length(init.io);

    if ((len & 3) != 0) {
        std.debug.print("Invalid SPIR-V File!", .{});
        std.process.exit(1);
    }

    var header: spirv.SpirVHeader = undefined;

    _ = try file.readPositionalAll(init.io, std.mem.asBytes(&header), 0);

    try output.print("; SPIR-V\n", .{});
    try output.print("; Version: {}.{}\n", .{ header.major(), header.minor() });
    try output.print("; Generator: {s}; {}\n", .{ header.tool_id_string(), header.tool_version() });
    try output.print("; Bound: {}\n", .{header.bound});
    try output.print("; Schema: {}\n", .{header._reserved});

    try output.flush();

    if (!header.is_valid()) {
        std.debug.print("Invalid SPIR-V File!", .{});
        std.process.exit(1);
    }

    var raw_op: spirv.RawSpirVOp = undefined;

    var offset: u64 = @sizeOf(spirv.SpirVHeader);

    const allocator = init.arena.allocator();

    while (offset < len) {
        _ = try file.readPositionalAll(init.io, std.mem.asBytes(&raw_op), offset);

        var op = try spirv.SpirVOp.new(
            raw_op,
            allocator,
        );

        defer op.deinit(allocator);

        try op.feed(init.io, file, offset + @sizeOf(spirv.RawSpirVOp));

        try output.print("{} ", .{op.raw.opcode()});

        try op.printOperands(output);

        try output.writeByte('\n');

        offset += op.raw.wc() * 4;
    }

    try output.flush();
}
