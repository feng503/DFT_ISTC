module MultiplyFloat (
    input clk, rstn, dataIn,
    input [31:0] x, y,
    output reg dataOut,
    output reg [31:0] prod
);

/*
    clk : clock signal, usually 50MHz or 100MHz
    rstn : reset signal not, [=0: reset, =1: normal]
    dataIn : data input signal, [=posedge means data is freshed]
    x,y : the data to be multiplied
    dataOut : data output signal, [=1 means data is prepared, =0 means data is not prepared]
    result: the prod of x and y
    
    Note: the machine code of x, y and prod are all 32-bit, satisfy the IEEE754 standard
*/

/*
             _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   
      clk:  | |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_|   
                 ________________________________________________________________________________________________________________________________________________________________________________________
     rstn:  ____|
                                                     ________________________________________                                          ________________________________________
   dataIn:  ________________________________________|                                        |________________________________________|                                        |_________________________
            ________________________________________ _________________________________________________________________________________ __________________________________________________________________
   x or y:  ________________________________________X_________________________________________________________________________________X__________________________________________________________________
                                                                                                      ________________________________                                                  _________________
  dataOut:  XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX_______________________________...______________|                                |_______________________________...______________|
            ________________________________________ ________________________________________________ ________________________________ ________________________________________________ _________________
     prod:  (0.00)__________________________________X(0.00)__________________________________________X(x*y)___________________________X(0.00)__________________________________________X(x*y)____________

*/

    wire dataInFlag;
    DataInFlag IDataInFlag(.clk(clk), .rstn(rstn), .dataIn(dataIn), .Flag(dataInFlag));
    
    always @(posedge dataIn) begin
        prod <= 0;
    end



    localparam widthFrac = 24, widthExp = 10;

    reg signX, signY, signProd;
    reg [widthExp-1:0] expX, expY, expSum, expSumTmp2;
    wire [widthExp-1:0] expSumTmp1;
    reg [widthFrac-1:0] fracXSrc, fracYSrc, fracProdSrc;
    wire [2*widthFrac-1:0] fracProdTmp;
    reg fracDataIn, fracRstn;
    wire fracDataOut;

    MultiplyInt #(.width(widthFrac)) IMultiplyInt(.clk(clk), .rstn(fracRstn), .dataIn(fracDataIn), .sign(1'd0), .x(fracXSrc), .y(fracYSrc), .dataOut(fracDataOut), .prod(fracProdTmp));

    AddInt #(.width(widthExp)) IAddInt(.sub(1'd0), .x(expX - 10'd127), .y(expY), .cout(), .ovfl(), .result(expSumTmp1));

    reg dataOutTemp;
    reg [3:0] step;

    always @(posedge clk or negedge rstn) begin
        if (!rstn || !dataInFlag) begin
            signX <= 0; signY <= 0; signProd <= 0;
            expX <= 0; expY <= 0; expSum <= 0; expSumTmp2 <= 0;
            fracXSrc <= 0; fracYSrc <= 0; fracProdSrc <= 0;
            fracDataIn <= 0; fracRstn <= 0;
            dataOutTemp <= 0;
            if (!rstn) begin
                step <= 0;
            end else begin
                step <= 1;
            end
        end else begin
            case (step)
                4'd1: begin
                    signX <= x[31]; signY <= y[31]; signProd = x[31] ^ y[31];
                    expX <= {{(widthExp-8){1'b0}}, x[30:23]}; fracXSrc <= {1'b1, x[22:0]};
                    expY <= {{(widthExp-8){1'b0}}, y[30:23]}; fracYSrc <= {1'b1, y[22:0]};
                    step <= step + 1;
                end
                4'd2: begin
                    if ((|x[30:0] == 0) || (y[30:0] == 0)) begin
                        step <= 13; //  0
                    end else if ((x[30:0] == 31'h7F800000)||(y[30:0] == 31'h7F800000)) begin
                        step <= 14; //  +Inf or -Inf
                    end else if(((expX == 8'hFF) && (|x[22:0] == 1)) || ((expY == 8'hFF) && (|y[22:0] == 1))) begin
                        step <= 15; //  NaN
                    end else begin
                        fracDataIn <= 1; fracRstn <= 1;
                        step <= step + 1;
                    end
                end
                4'd3: begin 
                    if (fracDataOut) begin 
                        if (fracProdTmp[2*widthFrac-1]) begin
                            fracProdSrc <= fracProdTmp[2*widthFrac-1:widthFrac] + fracProdTmp[widthFrac-1];
                        end else begin
                            fracProdSrc <= fracProdTmp[2*widthFrac-2:widthFrac-1] + fracProdTmp[widthFrac-2];
                        end
                        expSumTmp2  <= expSumTmp1 + fracProdTmp[2*widthFrac-1];
                        step <= step + 1;
                    end
                end
                4'd4: begin 
                    case (expSumTmp2[widthExp-1:widthExp-2])
                        2'b00: begin
                            expSum <= expSumTmp2;
                            step <= step + 1;
                        end
                        2'b01: begin
                            expSum <= {{(widthExp-8){1'b0}}, {8{1'b1}}};
                            step <= 14; //  +Inf or -Inf
                        end
                        2'b10, 2'b11: begin
                            expSum <= {{(widthExp-8){1'b0}}, {8{1'b0}}};
                            step <= 13; //  0
                        end 
                    endcase
                end
                4'd5: begin
                    dataOutTemp <= 1;
                    prod <= {signProd, expSum[7:0], fracProdSrc[widthFrac-2:0]};
                    step <= step + 1;
                end
                4'd13: begin // 0
                    dataOutTemp <= 1;
                    prod <= {signProd, 31'h0000_0000};
                    step <= 13;
                end
                4'd14: begin // +Inf or -Inf
                    dataOutTemp <= 1;
                    prod <= {signProd, 31'h7F80_0000};
                    step <= 14;
                end
                4'd15: begin // NaN
                    dataOutTemp <= 1;
                    prod <= {1'b0, {8{1'b1}}, {7{1'b1}}, x[30:23], y[30:23]};
                    step <= 15;
                end
                default: begin
                    
                end
            endcase
        end
    end

    assign dataOut = dataOutTemp & dataInFlag;


endmodule //MultiplyFloat