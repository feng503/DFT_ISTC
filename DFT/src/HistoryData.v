module HistoryData #(
    parameter size = 28
)(  
    input rstn, dataIn,
    input [31:0] data,
    output reg [31:0] array[0:size-1]
);

/*
    rstn : reset signal not, [=0: reset, =1: normal]
    dataIn : data input signal, [=1 means data is ready, =0 means data is not ready]
    data : the latest data input
    array : history data array, the first element is the oldest data, the last element is the newest data

    Note: the machine code of data and array[] is all 32-bit, satisfy the IEEE754 standard
*/

/*
            ______                 ______________________________________________________________________________________________________________________________________________________________________
     rstn:        |_______________|
                                                     ________________________________________                                          ________________________________________
   dataIn:  ________________________________________|                                        |________________________________________|                                        |_________________________
            ________________________________________ _________________________________________________________________________________ __________________________________________________________________
     data:  _data0__________________________________X_data1___________________________________________________________________________X_data2____________________________________________________________
            ________________________________________ _________________________________________________________________________________ __________________________________________________________________
    array:  ________________________________________X_array[0:size]___________________________________________________________________X_array[0:size]____________________________________________________
                   array[0] <= 32'b0;                 array[0] <= array[1];                                                             array[0] <= array[1];                                    
                   array[1] <= 32'b0;                 array[1] <= array[2];                                                             array[1] <= array[2];                                    
                            :                                  :                                                                                 :                                   
                   array[26] <= 32'b0;                array[26] <= array[27];                                                           array[26] <= array[27];                                    
                   array[27] <= 32'b0;                array[27] <= data0;                                                               array[27] <= data1;                                    
*/

    always @(posedge dataIn or negedge rstn) begin
        if (!rstn) begin
            for (integer i = 0; i < 28; i = i + 1) begin
                array[i] <= 32'b0;
            end
        end else begin
            for (integer i = 0; i < 27; i = i + 1) begin
                array[i] <= array[i + 1];
            end
            // Store new data at the beginning of the arrays
            array[27] <= data;
        end
    end

endmodule //HistoryData