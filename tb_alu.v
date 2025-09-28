
module tb_alu;
    reg  [7:0] a, b;
    reg  [3:0]       op;
    wire [7:0] y;
    wire             carry_out, overflow, zero, negative;

    // DUT
    alu_8bit dut (
        .a(a), .b(b), .op(op),
        .y(y), .carry_out(carry_out), .overflow(overflow),
        .zero(zero), .negative(negative)
    );

    // Reference model for comparison
    function [8:0] add_ext(input [7:0] aa, input [7:0] bb);
        add_ext = {1'b0, aa} + {1'b0, bb};
    endfunction

    function [8:0] sub_ext(input [7:0] aa, input [7:0] bb);
        sub_ext = {1'b0, aa} + {1'b0, ~bb} + 1'b1;
    endfunction

    task model_alu(
        input  [7:0] aa, bb,
        input  [3:0]       oo,
        output [7:0] yy,
        output             c_out, ovf
    );
        reg [8:0] tmp;
        begin
            c_out = 1'b0; ovf = 1'b0;
            case (oo)
                4'b0000: begin // ADD
                    tmp  = add_ext(aa, bb);
                    yy   = tmp[7:0];
                    c_out= tmp[8];
                    ovf  = (aa[7] == bb[7]) && (yy[7] != aa[7]);
                end
                4'b0001: begin // SUB
                    tmp  = sub_ext(aa, bb);
                    yy   = tmp[7:0];
                    c_out= tmp[8];
                    ovf  = (aa[7] != bb[7]) && (yy[7] != aa[7]);
                end
                4'b0010: yy = aa & bb;
                4'b0011: yy = aa | bb;
                4'b0100: yy = aa ^ bb;
                4'b0101: yy = ~(aa | bb);
                4'b0110: yy = aa << bb[2:0];
                4'b0111: yy = aa >> bb[2:0];
                4'b1000: yy = ($signed(aa) < $signed(bb)) ? 8'h01 : 8'h00;
                default: yy = {8{1'b0}};
            endcase
        end
    endtask

    // compare helper
    task check_case(input [7:0] aa, bb, input [3:0] oo);
        reg [7:0] yy_ref;
        reg c_ref, ovf_ref;
        begin
            a = aa; b = bb; op = oo;
            #1; // small delta to allow combinational settle
            model_alu(aa, bb, oo, yy_ref, c_ref, ovf_ref);

            if (y !== yy_ref || carry_out !== c_ref || overflow !== ovf_ref) begin
                $display("FAIL: op=%b a=%0d(0x%0h) b=%0d(0x%0h) | y=%0d(0x%0h) c=%b v=%b || ref y=%0d(0x%0h) c=%b v=%b",
                    oo, $signed(a), a, $signed(b), b, $signed(y), y, carry_out, overflow, $signed(yy_ref), yy_ref, c_ref, ovf_ref);
                $fatal(1);
            end
        end
    endtask

    integer i;

    initial begin
        // edge cases
        check_case(8'h7F, 8'h01, 4'b0000); // 127 + 1 -> overflow
        check_case(8'h80, 8'hFF, 4'b0000); // -128 + -1 -> overflow (two's comp)
        check_case(8'h00, 8'h00, 4'b0001); // 0 - 0
        check_case(8'h00, 8'h01, 4'b0001); // 0 - 1 (borrow)
        check_case(8'hFF, 8'h01, 4'b0111); // SRL
        check_case(8'h01, 8'h01, 4'b0110); // SLL
        check_case(8'hFE, 8'hFF, 4'b1000); // SLT signed: -2 < -1 => 1

        // Random sweep across all operations
        for (i = 0; i < 2000; i = i + 1) begin
            check_case($urandom, $urandom, $urandom % 9);
        end

        $display("All tests PASSED :)");
        #5 $finish;
    end

endmodule
