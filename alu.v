module alu_8bit (
    input  wire [7:0] a,
    input  wire [7:0] b,
    input  wire [3:0] op,
    output reg  [7:0] y,
    output reg        carry_out,   // unsigned carry 
    output reg        overflow,    // signed overflow
    output wire       zero,
    output wire       negative
);
    // Extended add/sub for carry
    wire [8:0] add_ext = {1'b0, a} + {1'b0, b};
    wire [8:0] sub_ext = {1'b0, a} + {1'b0, ~b} + 9'b1; // a - b

    always @* begin
        // safe defaults (avoid latches)
        y         = 8'h00;
        carry_out = 1'b0;
        overflow  = 1'b0;

        case (op)
            4'b0000: begin // ADD
                y         = add_ext[7:0];
                carry_out = add_ext[8];
                overflow  = (a[7] == b[7]) && (y[7] != a[7]);
            end
            4'b0001: begin // SUB  a - b
                y         = sub_ext[7:0];
                carry_out = sub_ext[8]; // note: borrow = ~carry_out in some conventions
                overflow  = (a[7] != b[7]) && (y[7] != a[7]);
            end
            4'b0010: y = a & b;                  // AND
            4'b0011: y = a | b;                  // OR
            4'b0100: y = a ^ b;                  // XOR
            4'b0101: y = ~(a | b);               // NOR
            4'b0110: y = a << b[2:0];            // SLL
            4'b0111: y = a >> b[2:0];            // SRL
            4'b1000: y = ($signed(a) < $signed(b)) ? 8'h01 : 8'h00; // SLT (signed)
            default: y = 8'h00;
        endcase
    end

    assign zero = (y == {8{1'b0}});
    assign negative = y[7];

endmodule

                        
