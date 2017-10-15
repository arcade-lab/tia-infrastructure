/*
 * Processing element to core and router mapper.
 */

`include "mmio.svh"

module processing_element_mapper
    (mmio_if.device host_interface,
     mmio_if.host core_interface,
     mmio_if.host router_interface);

    // --- Combinational Logic ---

    // Map reads.
    always_comb begin
        if (host_interface.read_req) begin
            if (host_interface.read_index >= TIA_CORE_BASE_INDEX
                && host_interface.read_index < TIA_CORE_BOUND_INDEX) begin
                core_interface.read_req = host_interface.read_req;
                core_interface.read_index = host_interface.read_index - TIA_CORE_BASE_INDEX;
                host_interface.read_ack = core_interface.read_ack;
                host_interface.read_data = core_interface.read_data;
                router_interface.read_req = 0;
                router_interface.read_index = 0;
            end else if (host_interface.read_index >= TIA_ROUTER_BASE_INDEX
                         && host_interface.read_index < TIA_ROUTER_BOUND_INDEX) begin
                core_interface.read_req = 0;
                core_interface.read_index = 0;
                router_interface.read_req = host_interface.read_req;
                router_interface.read_index = host_interface.read_index - TIA_ROUTER_BASE_INDEX;
                host_interface.read_ack = router_interface.read_ack;
                host_interface.read_data = router_interface.read_data;
            end else begin
                host_interface.read_ack = 0;
                host_interface.read_data = 0;
                core_interface.read_req = 0;
                core_interface.read_index = 0;
                router_interface.read_req = 0;
                router_interface.read_index = 0;
            end
        end else begin
            host_interface.read_ack = 0;
            host_interface.read_data = 0;
            core_interface.read_req = 0;
            core_interface.read_index = 0;
            router_interface.read_req = 0;
            router_interface.read_index = 0;
        end
    end

    // Map writes.
    always_comb begin
        if (host_interface.write_req) begin
            if (host_interface.write_index >= TIA_CORE_BASE_INDEX
                && host_interface.write_index < TIA_CORE_BOUND_INDEX) begin
                    core_interface.write_req = host_interface.write_req;
                    core_interface.write_index = host_interface.write_index - TIA_CORE_BASE_INDEX;
                    core_interface.write_data = host_interface.write_data;
                    host_interface.write_ack = core_interface.write_ack;
                    router_interface.write_req = 0;
                    router_interface.write_index = 0;
                    router_interface.write_data = 0;
            end else if (host_interface.write_index >= TIA_ROUTER_BASE_INDEX
                         && host_interface.write_index < TIA_ROUTER_BOUND_INDEX) begin
                    core_interface.write_req = 0;
                    core_interface.write_index = 0;
                    core_interface.write_data = 0;
                    router_interface.write_req = host_interface.write_req;
                    router_interface.write_index = host_interface.write_index - TIA_ROUTER_BASE_INDEX;
                    router_interface.write_data = host_interface.write_data;
                    host_interface.write_ack = router_interface.write_ack;
            end else begin
                host_interface.write_ack = 0;
                core_interface.write_req = 0;
                core_interface.write_index = 0;
                core_interface.write_data = 0;
                router_interface.write_req = 0;
                router_interface.write_index = 0;
                router_interface.write_data = 0;
            end
        end else begin
            host_interface.write_ack = 0;
            core_interface.write_req = 0;
            core_interface.write_index = 0;
            core_interface.write_data = 0;
            router_interface.write_req = 0;
            router_interface.write_index = 0;
            router_interface.write_data = 0;
        end
    end
endmodule
