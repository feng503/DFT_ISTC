module WeightSum #(
    parameter size = 28
)(
    input clk, rstn, dataIn,
    input [31:0] data[0:size-1], weight[0:size-1],
    output dataOut,
    output reg [31:0] result
);
/*
    clk : clock signal, [=1 means clock, =0 means not clock]
    rstn : reset signal not, [=0: reset, =1: normal]
    dataIn : data input signal, [=1 means data is ready, =0 means data is not ready]
    weight : weight array,
    data : data array,
    dataOut : data output signal, [=1 means data is prepared, =0 means data is not prepared]
    result : the sum of weight[i] * data[i], i range from 0 to size-1
*/

/*
             _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   
      clk:  | |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_|   
                 ________________________________________________________________________________________________________________________________________________________________________________________
     rstn:  ____|
                                                     ________________________________________                                          ________________________________________
   dataIn:  ________________________________________|                                        |________________________________________|                                        |_________________________
  data or   ________________________________________ _________________________________________________________________________________ __________________________________________________________________
   weight:  ________________________________________X_________________________________________________________________________________X__________________________________________________________________
                                                                                                      ________________________________                                                  _________________
  dataOut:  XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX_______________________________...______________|                                |_______________________________...______________|
            ________________________________________ ________________________________________________ ________________________________ ________________________________________________ _________________
   result:  (0.00)__________________________________X(0.00)__________________________________________X(data*weight)___________________X(0.00)__________________________________________X(data*weight)____
*/

    wire dataInFlag;
    DataInFlag IDataInFlag(.clk(clk), .rstn(rstn), .dataIn(dataIn), .Flag(dataInFlag));

    always @(posedge dataIn) begin
        result <= 0;
    end    

    localparam STAGE = clog2(size);

    wire [31:0] sums[0:STAGE][0:size-1];
    wire dataout [0:STAGE][0:size-1];

    generate
        genvar j;
        for (j = 0; j < size; j = j + 1) begin: zSTAGE
            MultiplyFloat IMultiplyFloat(.clk(clk), .rstn(rstn), .dataIn(dataIn), .x(weight[j]), .y(data[j]), .dataOut(dataout[0][j]), .prod(sums[0][j]));
        end

        genvar stage;
        for (stage = 1; stage <= STAGE; stage = stage + 1) begin: nSTAGE
            for (j = 0; j < ((size >> stage)+(((size >> (stage-1)) % 2) ? ((size % (1 << (stage-1))) != 0) : (0))); j = j + 1) begin: Floor
                AddFloat IAddFloat(.clk(clk), .rstn(rstn), .dataIn(dataout[stage-1][2*j] & dataout[stage-1][2*j+1]), .sub(1'b0), .x(sums[stage-1][2*j]), .y(sums[stage-1][2*j+1]), .dataOut(dataout[stage][j]), .result(sums[stage][j]));
            end
            if (((size >> (stage-1)) + ((size % (1 << (stage-1))) != 0)) % 2) begin
                assign sums[stage][((size >> (stage)) + ((size % (1 << (stage))) != 0)) - 1] = sums[stage-1][((size >> (stage-1)) + ((size % (1 << (stage-1))) != 0)) - 1];
                assign dataout[stage][((size >> (stage)) + ((size % (1 << (stage))) != 0)) - 1] = dataout[stage-1][((size >> (stage-1)) + ((size % (1 << (stage-1))) != 0)) - 1];
            end
        end

    endgenerate

    reg dataOutTmp;
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            dataOutTmp <= 1'b0;
        end else if (!dataInFlag) begin
            dataOutTmp <= 1'b0;
        end else if (dataout[0][size - 1] & dataout[STAGE][0]) begin
            dataOutTmp <= 1'b1;
            result <= sums[STAGE][0];
        end        
    end

    assign dataOut = dataOutTmp & dataInFlag;


//-------------------------function definition-------------------------//

// clog2: calculate the log2 of depth
    function integer clog2(
        input integer depth
    );
        begin
            if(depth == 0)
                clog2 = 1;
            else if(depth != 0)
                for(clog2 = 0; depth > 0;clog2 = clog2 + 1)
                    depth = depth >> 1;
        end
    endfunction


endmodule //WeightSum