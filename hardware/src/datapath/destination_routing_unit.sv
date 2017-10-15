/*
 * Responsible for routing ALU results to either registers or output channels. The predicate
 * updates are taken care of by the predicate unit.
 */

`include "datapath.svh"

module destination_routing_unit
    (input logic [TIA_WORD_WIDTH - 1:0] datapath_result,
     input logic [TIA_DT_WIDTH - 1:0] dt,
     input logic [TIA_DI_WIDTH - 1:0] di,
     input logic [TIA_OCI_WIDTH - 1:0] oci,
     output logic register_write_enable,
     output logic [TIA_REGISTER_INDEX_WIDTH - 1:0] register_write_index,
     output logic [TIA_WORD_WIDTH - 1:0] register_write_data,
     output logic [TIA_WORD_WIDTH - 1:0] output_channel_data [TIA_NUM_OUTPUT_CHANNELS -1:0]);

    // --- Internal Logic and Wiring ---

    // Not synthesized.
    integer i, j;

    // --- Combinational Logic ---

    // Write the datapath result out to an output channel, if requested.
    always_comb begin
        for (i = 0; i < TIA_NUM_OUTPUT_CHANNELS; i++) begin
            if (oci[i])
                output_channel_data[i] = datapath_result;
            else
                output_channel_data[i] = 0;
        end
    end

    // Write the datapath result out to the register file, if requested.
    always_comb begin
        if (dt == TIA_DESTINATION_TYPE_REGISTER) begin
            register_write_enable = 1;
            register_write_index = di;
            register_write_data = datapath_result;
        end else begin
            register_write_enable = 0;
            register_write_index = 0;
            register_write_data = 0;
        end
    end
endmodule
