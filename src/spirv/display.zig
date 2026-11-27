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
            .label => |label| {
                try writer.print("%{} = OpLabel\n", .{label});
            },
            .ford_less_than => |ford_less| {
                try writer.print("%{} = OpFOrdLessThan %{} %{} %{}", .{ ford_less.result_id, ford_less.result_type, ford_less.operand_1, ford_less.operand_2 });
            },
            .type_void => |v| {
                try writer.print("%{} = OpTypeVoid\n", .{v});
            },
            .type_bool => |v| {
                try writer.print("%{} = OpTypeBool\n", .{v});
            },
            .branch => |target| {
                try writer.print("OpBranch %{}\n", .{target});
            },
            .access_chain => |ac| {
                try writer.print("%{} = OpAccessChain %{} %{}", .{ ac.result_id, ac.result_type, ac.base });

                for (ac.indexes) |idx| {
                    try writer.print(" %{}", .{idx});
                }

                try writer.print("\n", .{});
            },
            .loop_merge => |lm| {
                try writer.print("OpLoopMerge %{} %{} {s}", .{ lm.merge_block, lm.continue_target, @tagName(lm.loop_control) });

                for (lm.loop_control_params) |param| {
                    try writer.print(" {}", .{param});
                }

                try writer.print("\n", .{});
            },
            .function => |func| {
                try writer.print("%{} = OpFunction %{} {s} %{}\n", .{ func.result_id, func.result_type, @tagName(func.function_control), func.function_type });
            },
            .constant => |con| {
                // TODO(Juanperias): Detect type of the literal value
                try writer.print("%{} = OpConstant %{} {}\n", .{ con.result_id, con.result_type, con.val });
            },
            .branch_conditional => |cond| {
                try writer.print("OpBranchConditional %{} %{} %{}", .{ cond.condition, cond.true_label, cond.false_label });

                for (cond.branch_weights) |weights| {
                    try writer.print(" {}", .{weights});
                }

                try writer.print("\n", .{});
            },
            .composite_construct => |composite| {
                try writer.print("%{} = OpCompositeConstruct %{}", .{ composite.result_id, composite.result_type });

                for (composite.constituents) |constituent| {
                    try writer.print(" %{}", .{constituent});
                }

                try writer.print("\n", .{});
            },
            .load => |l| {
                try writer.print("%{} = OpLoad %{} %{}\n", .{ l.result_id, l.result_type, l.pointer });
            },
            .type_function => |f| {
                try writer.print("%{} = OpTypeFunction %{}", .{ f.result_id, f.return_type });
                for (f.parameters) |param| {
                    try writer.print("%{} ", .{param});
                }

                try writer.print("\n", .{});
            },
            .composite_extract => |composite| {
                try writer.print("%{} = OpCompositeExtract %{} %{}", .{ composite.result_id, composite.result_type, composite.composite });

                for (composite.indexes) |index| {
                    try writer.print(" {}", .{index});
                }

                try writer.print("\n", .{});
            },
            .type_float => |ty_float| {
                try writer.print("%{} = OpTypeFloat {}", .{ ty_float.result_id, ty_float.width });

                if (ty_float.fp_enconding) |enc| {
                    try writer.print(" {s}", .{@tagName(enc)});
                }

                try writer.print("\n", .{});
            },
            .extension => |name| {
                try writer.print("OpExtension \"{s}\"\n", .{name});
            },
            .variable => |variable| {
                try writer.print("%{} = OpVariable %{} {s}", .{ variable.result_id, variable.result_type, @tagName(variable.storage_class) });

                if (variable.init) |_init| {
                    try writer.print(" %{}", .{_init});
                }

                try writer.print("\n", .{});
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
            ._return => {
                try writer.print("OpReturn\n", .{});
            },
            .type_int => |int| {
                try writer.print("%{} = OpTypeInt {} {}", .{ int.result_id, int.width, int.signedness });
            },
            .type_pointer => |ptr| {
                try writer.print("%{} = OpTypePointer {s} %{}\n", .{ ptr.result_id, @tagName(ptr.storage_class), ptr.ty });
            },
            .function_end => {
                try writer.print("OpFunctionEnd\n", .{});
            },
            .store => |store| {
                try writer.print("OpStore %{} %{}\n", .{ store.pointer, store.object });
            },
            .type_vector => |vec| {
                try writer.print("%{} = OpTypeVector %{} {}\n", .{ vec.result_id, vec.component_type, vec.component_count });
            },
            .member_decorate => |dec| {
                try writer.print("OpMemberDecorate %{} {} {s}", .{ dec.structure_type, dec.member, @tagName(dec.decoration) });

                switch (dec.extra_operand) {
                    .literal => |lit| {
                        try writer.print(" {}", .{lit});
                    },
                    .build_in => |b| {
                        try writer.print(" {s}", .{@tagName(b)});
                    },
                    else => {},
                }

                try writer.print("\n", .{});
            },
            .decoration => |dec| {
                try writer.print("OpDecorate %{} {s}", .{ dec.id_target, @tagName(dec.decoration) });

                switch (dec.extra_operand) {
                    .literal => |lit| {
                        try writer.print(" {}", .{lit});
                    },
                    .build_in => |b| {
                        try writer.print(" {s}", .{@tagName(b)});
                    },
                    else => {},
                }

                try writer.print("\n", .{});
            },
            ._unk => |op| {
                try writer.print("{s} is ??\n", .{@tagName(op)});
            },
        }
    }

    pub fn deinit(self: *DisplayCtx) void {
        self.symbols.deinit();
    }
};
