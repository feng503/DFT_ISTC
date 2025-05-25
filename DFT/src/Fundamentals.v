module Fundamentals #(
    parameter size = 28
)(
    input clk, rstn, dataIn,
    input [31:0] data[0:size-1], RE[0:size-1], IM[0:size-1],
    output dataOut,
    output reg [31:0] result
);

/*
    clk : clock signal, usually 50MHz or 100MHz
    rstn : reset signal not, [=0: reset, =1: normal]
    dataIn : data input signal, [=1 means data is ready, =0 means data is not ready]
    data[0:size-1] : data input
    RE[0:size-1] : real coefficient
    IM[0:size-1] : imaginary coefficient 
    dataOut : data output signal, [=1 means data is prepared, =0 means data is not prepared]
    result : result of FFT

    Note: the machine code of data[], RE[], IM[] and result are all 32-bit, satisfy the IEEE754 standard
*/

/*
             _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   
      clk:  | |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_|   
                 ________________________________________________________________________________________________________________________________________________________________________________________
     rstn:  ____|
                                                     ________________________________________                                          ________________________________________
   dataIn:  ________________________________________|                                        |________________________________________|                                        |_________________________
 RE,IM or   ________________________________________ _________________________________________________________________________________ __________________________________________________________________
     data:  ________________________________________X_________________________________________________________________________________X__________________________________________________________________
                                                                                                      ________________________________                                              _____________________
  dataOut:  XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX_______________________________...______________|                                |_______________________________...__________|
            ________________________________________ ________________________________________________ ________________________________ ____________________________________________ _____________________
   result:  (0.00)__________________________________X(0.00)__________________________________________X(data*RE + data*IM)_____________X(0.00)______________________________________X(data*RE + data*IM)__
*/

    wire dataInFlag;
    DataInFlag IDataInFlag(.clk(clk), .rstn(rstn), .dataIn(dataIn), .Flag(dataInFlag));

    always @(posedge dataIn) begin
        result <= 0;
    end   

    
/*     
    wire [31:0] sumRE, sumIM, sumRE2, sumIM2;
    wire dataOutRE, dataOutIM, dataOutRE2, dataOutIM2, dataOutAmp;


    WeightSum #(.size(size)) IWeightSumRE(.clk(clk), .rstn(rstn), .dataIn(dataIn), .data(data), .weight(RE), .dataOut(dataOutRE), .result(sumRE));
    WeightSum #(.size(size)) IWeightSumIM(.clk(clk), .rstn(rstn), .dataIn(dataIn), .data(data), .weight(IM), .dataOut(dataOutIM), .result(sumIM));

    MultiplyFloat IMultiplyFloatRE(.clk(clk), .rstn(rstn), .dataIn(dataOutRE), .x(sumRE), .y(sumRE), .dataOut(dataOutRE2), .prod(sumRE2));
    MultiplyFloat IMultiplyFloatIM(.clk(clk), .rstn(rstn), .dataIn(dataOutIM), .x(sumIM), .y(sumIM), .dataOut(dataOutIM2), .prod(sumIM2));

    AddFloat IAddFloat(.clk(clk), .rstn(rstn), .dataIn(dataOutRE2 & dataOutIM2), .sub(1'b0), .x(sumRE2), .y(sumIM2), .dataOut(dataOutAmp), .result(result));

    assign dataOut = dataOutRE & dataOutIM & dataOutRE2 & dataOutIM2 & dataOutAmp;


*/
    wire [31:0] sumRE, sumIM, sumRE2, sumIM2, sumAmp;
    wire dataOutRE, dataOutIM, dataOutRE2, dataOutIM2, dataOutAmp;

    reg dataInRE, dataInIM, dataInRE2, dataInIM2, dataInAmp;

    WeightSum #(.size(size)) IWeightSumRE(.clk(clk), .rstn(rstn), .dataIn(dataInRE), .data(data), .weight(RE), .dataOut(dataOutRE), .result(sumRE));
    WeightSum #(.size(size)) IWeightSumIM(.clk(clk), .rstn(rstn), .dataIn(dataInIM), .data(data), .weight(IM), .dataOut(dataOutIM), .result(sumIM));

    MultiplyFloat IMultiplyFloatRE(.clk(clk), .rstn(rstn), .dataIn(dataInRE2), .x(sumRE), .y(sumRE), .dataOut(dataOutRE2), .prod(sumRE2));
    MultiplyFloat IMultiplyFloatIM(.clk(clk), .rstn(rstn), .dataIn(dataInIM2), .x(sumIM), .y(sumIM), .dataOut(dataOutIM2), .prod(sumIM2));

    AddFloat IAddFloat(.clk(clk), .rstn(rstn), .dataIn(dataOutRE & dataOutIM & dataOutRE2 & dataOutIM2), .sub(1'b0), .x(sumRE2), .y(sumIM2), .dataOut(dataOutAmp), .result(sumAmp));

    reg dataOutTmp;
    reg [3:0] step;

    always @(posedge clk or negedge rstn) begin
        if (!rstn || !dataInFlag) begin
            dataInRE <= 0; dataInIM <= 0; dataInRE2 <= 0; dataInIM2 <= 0; dataInAmp <= 0;
            dataOutTmp <= 0;
            if (!rstn) begin
                step <= 0;
            end else begin
                step <= 1;
            end
        end else begin
            case (step)
                4'd1: begin 
                    dataInRE <= 1; dataInIM <= 1;
                    step <= step + 1;
                end
                4'd2: begin
                    if (dataOutRE & dataOutIM) begin    
                        dataInRE2 <= 1; dataInIM2 <= 1;
                        step <= step + 1;
                    end
                end
                4'd3: begin
                    if (dataOutRE2 & dataOutIM2) begin
                        dataInAmp <= 1;
                        step <= step + 1;
                    end
                end
                4'd4: begin
                    if (dataOutAmp) begin
                        dataOutTmp <= 1;
                        result <= sumAmp;
                        step <= step + 1;
                    end
                end
                default : begin
                end
            endcase
        end 
    end

    assign dataOut = dataOutTmp & dataInFlag;


/*
*/    

endmodule //Fundamentals