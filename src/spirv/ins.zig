const spv = @import("enums.zig");

pub const SpirVIns = union(enum) {
    capability: spv.SpvCapability,
    memory_model: struct { addr: spv.SpvAddressingModel, mem: spv.SpvMemoryModel },
    ext_inst_import: struct {
        result_id: u32,
        name: []const u8,
    },
    extension: []const u8,
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
    member_decorate: struct { structure_type: u32, member: u32, decoration: spv.SpvDecoration, extra_operand: spv.DecorationExtraOperand },
    execution_mode: struct {
        entry_point: u32,
        mode: spv.SpvExecutionMode,
    },
    store: struct {
        pointer: u32,
        object: u32,
    },
    load: struct {
        result_type: u32,
        result_id: u32,
        pointer: u32,
    },
    label: u32,
    variable: struct {
        result_type: u32,
        result_id: u32,
        storage_class: spv.SpvStorageClass,
        init: ?u32,
    },
    type_function: struct {
        result_id: u32,
        return_type: u32,
        parameters: []const u32,
    },
    type_int: struct {
        result_id: u32,
        width: u32,
        signedness: u32,
    },
    type_pointer: struct {
        result_id: u32,
        storage_class: spv.SpvStorageClass,
        ty: u32,
    },
    type_float: struct {
        result_id: u32,
        width: u32,
        fp_enconding: ?spv.SpvFpEncoding,
    },
    type_vector: struct {
        result_id: u32,
        component_type: u32,
        component_count: u32,
    },
    constant: struct {
        result_type: u32,
        result_id: u32,
        val: u32,
    },
    function: struct {
        result_type: u32,
        result_id: u32,
        function_control: spv.SpvFunctionControl,
        function_type: u32,
    },
    composite_extract: struct {
        result_type: u32,
        result_id: u32,
        composite: u32,
        // NOTE(JUANPERAS): Well.... The spec says that this is variable
        indexes: []const u32,
    },
    branch_conditional: struct {
        condition: u32,
        true_label: u32,
        false_label: u32,
        branch_weights: []const u32,
    },
    composite_construct: struct {
        result_type: u32,
        result_id: u32,
        constituents: []const u32,
    },
    type_void: u32,
    type_bool: u32,
    branch: u32,
    access_chain: struct {
        result_type: u32,
        result_id: u32,
        base: u32,
        indexes: []const u32,
    },
    ford_less_than: struct {
        result_type: u32,
        result_id: u32,
        operand_1: u32,
        operand_2: u32,
    },
    loop_merge: struct {
        merge_block: u32,
        continue_target: u32,
        loop_control: spv.SpvLoopControl,
        loop_control_params: []const u32,
    },
    _return: void,
    function_end: void,
    _unk: spv.SpvOpCode,
};
