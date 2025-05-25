module Coefficients (
    input clk, rstn, dataIn,
    input [31:0] amp[0:2],
    output dataOut,
    output reg [31:0] coff
);

/*
    clk  : clock signal, usually 50MHz or 100MHz
    rstn : reset signal not, [=0: reset, =1: normal]
    dataIn : data input signal, [=1 means data is ready, =0 means data is not ready]
    amp[0:2] : amplitude of 3 current channels: IA, IB, IC
    dataOut : data output signal, [=1 means data is prepared, =0 means data is not prepared]
    coff : asymmetric coefficient of 3 current channels, value range from 0 to 1, coff = 2*(max(amp)-min(amp))/sum(amp);

    Note: the machine code of amp and coff are all 32-bit, satisfy the IEEE754 standard
*/

/*
             _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   
      clk:  | |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_|   
                 ________________________________________________________________________________________________________________________________________________________________________________________
     rstn:  ____|
                                                     ________________________________________                                          ________________________________________
   dataIn:  ________________________________________|                                        |________________________________________|                                        |_________________________
            ________________________________________ _________________________________________________________________________________ __________________________________________________________________
      amp:  ________________________________________X_(amp[0:2])______________________________________________________________________X_(amp[0:2])_______________________________________________________
                                                                                                      ________________________________                                                  _________________
  dataOut:  XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX_______________________________...______________|                                |_______________________________...______________|
            ________________________________________ ________________________________________________ ________________________________ ________________________________________________ _________________
     coff:  __(0.00)________________________________X_(0.00)_________________________________________X_(coff)_________________________X_(0.00)_________________________________________X_(coff)__________
*/


    wire dataInFlag;
    DataInFlag IDataInFlag(.clk(clk), .rstn(rstn), .dataIn(dataIn), .Flag(dataInFlag));

    always @(posedge dataIn) begin
        coff <= 0;
    end    

    wire [31:0] max = (amp[0] >  amp[1]) ? (amp[0] >  amp[2] ? amp[0] : amp[2]) : (amp[1] >  amp[2] ? amp[1] : amp[2]);
    wire [31:0] min = (amp[0] <  amp[1]) ? (amp[0] <  amp[2] ? amp[0] : amp[2]) : (amp[1] <  amp[2] ? amp[1] : amp[2]);

/*
    reg [31:0] sum2, sum3, diff;
    wire dataOutDiff, dataOutSum2, dataOutSum3, dataOutCoffTmp;
    
    AddFloat IAddFloat0(.clk(clk), .rstn(rstn), .dataIn(dataIn), .sub(1'b1), .x(max), .y(min), .dataOut(dataOutDiff), .result(diff));
    AddFloat IAddFloat1(.clk(clk), .rstn(rstn), .dataIn(dataInSum2), .sub(1'b0), .x(amp[0]), .y(amp[1]), .dataOut(dataOutSum2), .result(sum2));
    AddFloat IAddFloat2(.clk(clk), .rstn(rstn), .dataIn(dataOutSum2), .sub(1'b0), .x(sum2), .y(amp[2]), .dataOut(dataOutSum3), .result(sum3));

    DivideFloat IDivideFloat0(.clk(clk), .rstn(rstn), .dataIn(dataOutDiff & dataOutSum3), .dend(diff), .dsor(sum3), .dataOut(dataOutCoffTmp), .quot(coff));

    assign dataOut = dataOutDiff & dataOutSum2 & dataOutSum3 & dataOutCoffTmp & dataInFlag;

*/
    reg [31:0] sum2, sum3, diff, coffTmp;
    reg dataInDiff, dataInSum2;
    wire dataOutSum2, dataOutSum3, dataOutDiff, dataOutCoffTmp;

    AddFloat IAddFloat0(.clk(clk), .rstn(rstn), .dataIn(dataInDiff), .sub(1'b1), .x(max), .y(min), .dataOut(dataOutDiff), .result(diff));
    AddFloat IAddFloat1(.clk(clk), .rstn(rstn), .dataIn(dataInSum2), .sub(1'b0), .x(amp[0]), .y(amp[1]), .dataOut(dataOutSum2), .result(sum2));
    AddFloat IAddFloat2(.clk(clk), .rstn(rstn), .dataIn(dataOutSum2), .sub(1'b0), .x(sum2), .y(amp[2]), .dataOut(dataOutSum3), .result(sum3));

    DivideFloat IDivideFloat0(.clk(clk), .rstn(rstn), .dataIn(dataOutDiff & dataOutSum3), .dend(diff), .dsor(sum3), .dataOut(dataOutCoffTmp), .quot(coffTmp));

    reg dataOutTmp;
    reg [3:0] step;
    always @(posedge clk or negedge rstn) begin
        if (!rstn || !dataInFlag) begin
            sum2  <= 32'b0; sum3 <= 32'b0; diff <= 32'b0; coffTmp <= 32'b0;
            dataInDiff  <= 1'b0; dataInSum2  <= 1'b0;
            dataOutTmp <= 1'b0;
            if (!rstn) begin
                step <= 4'b0;
            end else begin
                step <= 4'b1;
            end
        end else begin
            case (step)
                4'd1: begin
                    dataInDiff  <= 1; dataInSum2  <= 1;
                    step <= step + 2; 
                end
                4'd2: begin
                    step  <= step + 1;
                end
                4'd3: begin
                    if (dataOutCoffTmp) begin
                        coff <= {coffTmp[31], (coffTmp[30:23]+1), coffTmp[22:0]};
                        dataOutTmp <= 1;
                        step <= step + 1;
                    end
                end
                default: begin
                end
            endcase
        end
    end

    assign dataOut = dataOutTmp & dataInFlag;

/*
*/


endmodule //Coefficients
