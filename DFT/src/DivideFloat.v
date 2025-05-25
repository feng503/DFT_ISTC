module DivideFloat (
    input clk, rstn, dataIn,
    input [31:0] dend, dsor,
    output reg dataOut,
    output reg [31:0] quot
);

/*
    clk : clock signal, usually 50MHz or 100MHz
    rstn : reset signal not, [=0: reset, =1: normal]
    dataIn : data input signal, [=posedge means data is freshed]
    dend : the data to be divided
    dsor : the number by which dividend is divided
    dataOut : data output signal, [=1 means data is prepared, =0 means data is not prepared]
    quot : the quotient of dividend and divisor
    
    Note: the machine code of dene, dsor and quot are all 32-bit, satisfy the IEEE754 standard
*/

/*
             _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   
      clk:  | |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_|   
                 ________________________________________________________________________________________________________________________________________________________________________________________
     rstn:  ____|
                                                     ________________________________________                                          ________________________________________
   dataIn:  ________________________________________|                                        |________________________________________|                                        |_________________________
            ________________________________________ _________________________________________________________________________________ __________________________________________________________________
 denddsor:  ________________________________________X_________________________________________________________________________________X__________________________________________________________________
                                                                                                      ________________________________                                                  _________________
  dataOut:  XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX_______________________________...______________|                                |_______________________________...______________|
            ________________________________________ ________________________________________________ ________________________________ ________________________________________________ _________________
     quot:  (0.00)__________________________________X(0.00)__________________________________________X(x/y)___________________________X(0.00)__________________________________________X(x/y)____________
*/

    wire dataInFlag;
    DataInFlag IDataInFlag(.clk(clk), .rstn(rstn), .dataIn(dataIn), .Flag(dataInFlag));

    always @(posedge dataIn) begin
        quot <= 0;
    end    


    localparam widthFrac = 24, widthExp = 10;

    reg signDend, signDsor, signQuot;
    reg [widthExp-1:0] expDend, expDsor, expQuot, expQuotTmp2;
    wire [widthExp-1:0] expQuotTmp1;
    reg [2*widthFrac:0] fracDend;
    wire [2*widthFrac:0] fracQuotTmp;
    reg [widthFrac-1:0] fracDsor, fracQuot;
    reg fracDataIn, fracRstn;
    wire fracDataOut;

    DivideInt #(.widthDend(2*widthFrac+1), .widthDsor(widthFrac)) IDivideInt(.clk(clk), .dataIn(fracDataIn), .rstn(fracRstn), .sign(1'b0), .dend(fracDend), .dsor(fracDsor), .dataOut(fracDataOut), .quot(fracQuotTmp), .rmdr());

    AddInt #(.width(widthExp)) IAddSub(.sub(1'b1), .x(expDend + 10'd127), .y(expDsor), .cout(), .ovfl(), .result(expQuotTmp1));

    reg dataOutTmp;
    reg [3:0] step;

    always @(posedge clk or negedge rstn) begin
        if (!rstn || !dataInFlag) begin
            quot <= 32'b0;
            signDend <= 1'b0; signDsor <= 1'b0; signQuot <= 1'b0;
            expDend <= {widthExp{1'b0}}; expDsor <= {widthExp{1'b0}}; expQuot <= {widthExp{1'b0}}; expQuotTmp2 <= {widthExp{1'b0}};
            fracDend <= {2*widthFrac+1{1'b0}}; fracDsor <= {widthFrac{1'b0}}; fracQuot <= {widthFrac{1'b0}};
            fracDataIn <= 1'b0; fracRstn <= 1'b0; dataOutTmp <= 1'b0; 
            if (!rstn) begin
                step <= 0;
            end else begin
                step <= 1;
            end
        end else begin
            case (step)
                4'd1: begin
                    signDend <= dend[31]; signDsor <= dsor[31]; signQuot <= dend[31] ^ dsor[31];
                    expDend <= {{(widthExp-8){1'b0}}, dend[30:23]}; expDsor <= {{(widthExp-8){1'b0}}, dsor[30:23]};
                    fracDend <= {1'b1, dend[22:0], {widthFrac+1{1'b0}}}; fracDsor <= {1'b1, dsor[22:0]};
                    step <= step + 1;
                end
                4'd2: begin
                    if (|dsor[30:0] == 0) begin
                        step <= 14; //  dsor is 0, answer is Inf or -Inf
                    end else if (dsor[30:0] == 31'h7F800000) begin
                        step <= 13; //  dsor is +Inf or -Inf, answer is 0 or -0
                    end else if (|dend[30:0] == 0) begin 
                        step <= 13; //  dend is 0, answer is 0 or -0
                    end else if (dend[30:0] == 31'h7F800000) begin
                        step <= 14; //  dend is +Inf or -Inf, answer is Inf or -Inf
                    end else if (((expDend == 8'hFF) && (|dend[22:0] == 1)) || ((expDsor== 8'hFF) && (|dsor[22:0] == 1))) begin
                        step <= 15; //  dend or dsor is NaN, answer is NaN
                    end else begin
                        fracDataIn <= 1; fracRstn <= 1;
                        step <= step + 1;
                    end
                end
                4'd3: begin
                    if (fracDataOut) begin
                        if (fracQuotTmp[widthFrac+1]) begin
                            fracQuot <= fracQuotTmp[widthFrac+1 -: widthFrac];
                            expQuotTmp2 <= expQuotTmp1;
                        end else begin
                            fracQuot <= fracQuotTmp[widthFrac -: widthFrac];
                            expQuotTmp2 <= expQuotTmp1 - 1;
                        end
                        step <= step + 1;
                    end
                end
                4'd4: begin
                    case (expQuotTmp2[widthExp-1: widthExp-2])
                        2'b00: begin
                            expQuot <= expQuotTmp2;
                            step <= step + 1;
                        end
                        2'b01: begin
                            expQuot <= {{(widthExp-8){1'b0}}, {8{1'b1}}};  // overflow +Inf or -Inf
                            step <= 14;
                        end
                        2'b10, 2'b11: begin
                            expQuot <= {{(widthExp-8){1'b0}}, {8{1'b0}}};  // underflow 0 or -0
                            step <= 13;
                        end
                    endcase
                end
                4'd5: begin 
                    quot <= {signQuot, expQuot[7:0], fracQuot[widthFrac-2:0]};
                    dataOutTmp <= 1;
                    step <= step + 1;
                end
                4'd13: begin // +0 or -0: 32'h00000000 or 32'h80000000
                    quot <= {signQuot, 31'h0000000};
                    dataOutTmp <= 1;
                    step <= 13;
                end
                4'd14: begin // +Inf or -Inf: 32'h7F800000 or 32'hFF800000
                    quot <= {signQuot, 31'h7F800000};
                    dataOutTmp <= 1;
                    step <= 14;
                end
                4'd15: begin // NaN: 32'h7FC00000 or 32'hFFC00000
                    quot <= {signQuot, {8{1'b1}}, {7{1'b1}}, dend[30:23], dsor[30:23]};
                    dataOutTmp <= 1;
                    step <= 15;
                end
                default: begin
                end
            endcase
        end
    end

    assign dataOut = dataOutTmp & dataInFlag;

endmodule //DivideFloat