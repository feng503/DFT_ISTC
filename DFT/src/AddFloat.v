module AddFloat (
    input clk, rstn, dataIn, sub,
    input [31:0] x, y,
    output dataOut,
    output reg [31:0] result
);
/*
    clk : clock signal, usually 50MHz or 100MHz
    rstn : reset signal not, [=0: reset, =1: normal]
    dataIn : data input signal, [=posedge means data is freshed]
    sub: 0 for addition, 1 for subtraction
    x,y: the data to be added or subtracted
    dataOut : data output signal, [=1 means data is prepared, =0 means data is not prepared]
    result: the sum or sub of x and y

    Note: the machine code of x, y and result are all 32-bit, satisfy the IEEE754 standard
*/

/*
             _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   
      clk:  | |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_|   
                 ________________________________________________________________________________________________________________________________________________________________________________________
     rstn:  ____|
                                                                                                       __________________________________________________________________________________________________
      sub:  __________________________________________________________________________________________|
                                                     ________________________________________                                          ________________________________________
   dataIn:  ________________________________________|                                        |________________________________________|                                        |_________________________
            ________________________________________ _________________________________________________________________________________ __________________________________________________________________
   x or y:  ________________________________________X_________________________________________________________________________________X__________________________________________________________________
                                                                                                      ________________________________                                                  _________________
  dataOut:  XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX_______________________________...______________|                                |_______________________________...______________|
            ________________________________________ ________________________________________________ ________________________________ ________________________________________________ _________________
   result:  (0.00)__________________________________X(0.00)__________________________________________X(x+y)___________________________X(0.00)__________________________________________X(x-y)____________

*/

    wire dataInFlag;
    DataInFlag IDataInFlag(.clk(clk), .rstn(rstn), .dataIn(dataIn), .Flag(dataInFlag));

    always @(posedge dataIn) begin
        result <= 0;
    end

    localparam width = 27;

    reg signX, signY, signRes;
    reg [7:0] expX, expY, expRes, expResTmp;
    reg [width-1:0] fracXSrc, fracYSrc;
    reg signed [width-1:0] fracXCmp, fracYCmp, fracXTmp, fracYTmp, fracResSrc, fracRes;
    wire signed [width-1:0] fracResCmp;

    AddInt #(.width(width)) IAddInt(.sub(sub), .x(fracXTmp), .y(fracYTmp), .cout(), .ovfl(), .result(fracResCmp));

    reg dataOutTmp;
    reg [3:0] step;



    always @(posedge clk) begin
        if (!rstn | !dataInFlag) begin
            signX <= 0; signY <= 0; signRes <= 0;
            expX  <= 0; expY  <= 0; expRes  <= 0; expResTmp <= 0;
            fracXSrc <= 0; fracYSrc <= 0; fracXCmp <= 0; fracYCmp <= 0;
            fracXTmp <= 0; fracYTmp <= 0; fracResSrc <= 0; fracRes <= 0;
            dataOutTmp <= 1'b0;
            if(!rstn) begin
                step <= 0;
            end else begin
                step <= 1;
            end
        end else begin
            case (step)
                4'd1: begin 
                signX <= x[31];    signY <= y[31];
                expX  <= x[30:23]; expY  <= y[30:23];
                //  符号位 防止溢出位 整数位 小数位 规格化进位
                fracXCmp <= {x[31], ({1'b0, |x[30:0], x[22:0], 1'b0}^{(width-1){x[31]}}) + x[31]};
                fracYCmp <= {y[31], ({1'b0, |y[30:0], y[22:0], 1'b0}^{(width-1){y[31]}}) + y[31]};
                step <= step + 1;
                end
                4'd2: begin
                    if ((x == 32'hFF800000)||(y == 32'hFF800000)) begin
                        step <= 13; //  +Inf
                    end else if ((x == 32'h7F800000)||(y == 32'h7F800000)) begin
                        step <= 14; //  -Inf
                    end else if (((expX == 8'hFF) && (|x[22:0] == 1)) || ((expY == 8'hFF) && (|y[22:0] == 1))) begin
                        // only if x or y is NaN, then return is NaN
                        step <= 15; //  NaN
                    end else if (expX > expY) begin
                        expResTmp <= expX + 1;
                        fracXTmp <= fracXCmp;
                        fracYTmp <= fracYCmp >>> (expX - expY);
                        step <= step + 1;
                    end else begin
                        expResTmp <= expY + 1;
                        fracXTmp <= fracXCmp >>> (expY - expX);
                        fracYTmp <= fracYCmp;
                        step <= step + 1;
                    end
                end
                4'd3: begin
                    signRes <= fracResCmp[width-1];
                    step <= step + 1;
                end
                4'd4: begin
                    if (signRes) begin
                        fracResSrc <= ({signRes, ~fracResCmp[width-2:0]} + 1) << 1;
                    end else begin
                        fracResSrc <= fracResCmp << 1;
                    end
                    step <= step + 1;
                end
                4'd5: begin 
                    automatic integer shift_num = 0;
                    for (shift_num = 0; shift_num < width - 1; shift_num = shift_num + 1) begin
                        if (fracResSrc[width - shift_num - 1]) begin
                            fracRes <= fracResSrc << shift_num;
                            expRes <= expResTmp - shift_num;
                            break;
                        end
                    end
                    step <= step + 1;
                end
                4'd6: begin
                    result <= {signRes, expRes, (fracRes[width-2 -: 23] + (fracRes[width-25]))};
                    dataOutTmp <= 1;
                    step <= step + 1;
                end
                4'd13: begin
                    //  -Inf 32'hFF800000
                    dataOutTmp <= 1;
                    result <= 32'hFF800000;
                    step <= 13;
                end
                4'd14: begin
                    //  +Inf 32'h7F800000
                    dataOutTmp <= 1;
                    result <= 32'h7F800000;
                    step <= 14;
                end
                4'd15: begin
                    //  NaN 
                    dataOutTmp <= 1;
                    result <= {1'b0, {8{1'b1}}, {7{1'b1}}, expX, expY};
                    step <= 15;
                end
                default: begin

                end
            endcase
        end

    end

    assign dataOut = dataOutTmp & dataInFlag;

endmodule //AddFloat
