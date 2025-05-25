// the main module 

module FFT (
    input clk, rstn, sensorDataRefresh,
    input [31:0] data[0:5],
    output reg dataValid, dataOut,
    output reg [31:0] Amp[0:2], Coff
);

/*
    clk : clock signal, usually 50MHz or 100MHz
    rstn : reset signal not, [=0: reset, =1: normal]
    sensorDataRefresh : sensor data refresh signal, usually 20kHz or 25kHz
    data[0:5] : sensor data, include 6 channels: IA, IB, IC, Speed, Udc, Idc
    dataValid : data valid signal, [=1 means data is valid, =0 means data is invalid]
    dataOut : data output signal, [=1 means data is prepared, =0 means data is not prepared]
    Amp[0:2] : amplitude of 3 current channels: IA, IB, IC
    Coff : asymmetric coefficient of 3 current channels, value range from 0 to 1

    Note: the machine code of data, Amp and Coff are all 32-bit, satisfy the IEEE754 standard
*/

/*
             _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   
      clk:  | |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_|   
                 ________________________________________________________________________________________________________________________________________________________________________________________
     rstn:  ____|
                                                     ________________________________________                                          ________________________________________
sDRefresh:  ________________________________________|                                        |________________________________________|                                        |_________________________
            ________________________________________ _________________________________________________________________________________ __________________________________________________________________
data[0:5]:  ________________________________________X_________________________________________________________________________________X__________________________________________________________________

dataValid:  dataValid = (Idc > threshold) && (Speed > threshold) without any other conditions
                                                                                                      ________________________________                                                  _________________
  dataOut:  XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX_______________________________...______________|                                |_______________________________...______________|
            ________________________________________ _____________________________________ ___________________________________________ _____________________________________ ____________________________
 Amp[0:2]:  (0.00)__________________________________X(0.00)_______________________________X(****)_____________________________________X(0.00)_______________________________X(****)______________________
            ________________________________________ ________________________________________________ ________________________________ ________________________________________________ _________________
    Coff:   (0.00)__________________________________X(0.00)__________________________________________X(0.12)__________________________X(0.00)__________________________________________X(0.06)___________

*/

/*
    00.   AddInt.v              100%
    01.   AddFloat.v            100%
    02.   MultplyInt.v          100%
    03.   MultplyFloat.v        100%
    04.   DivideInt.v           100%
    05.   DivideFloat.v         100%


    11.   HistoryData.v         100%
    12.   WeightSum.v           100%
    13.   Fundamentals.v        100%
    14.   Coefficients.v        100%


*/    
//  size: the size of data array
    localparam size = 28;

//  speedxxxxx: speed_region switch of speed_abs
    localparam [31:0] speed13760 = 32'h46570000;
    localparam [31:0] speed13860 = 32'h46589000;
    localparam [31:0] speed14785 = 32'h46670400;
    localparam [31:0] speed14885 = 32'h46689400;
    localparam [31:0] speed15976 = 32'h4679A000;
    localparam [31:0] speed16076 = 32'h467B3000;
    localparam [31:0] speed17374 = 32'h4687BC00;
    localparam [31:0] speed17474 = 32'h46888400;
    localparam [31:0] speed19041 = 32'h4694C200;
    localparam [31:0] speed19141 = 32'h46958A00;
    localparam [31:0] speed21061 = 32'h46A48A00;
    localparam [31:0] speed21161 = 32'h46A55200;
    localparam [31:0] speed23561 = 32'h46B81200;
    localparam [31:0] speed23661 = 32'h46B8DA00;


    wire dataInFlag;
    DataInFlag IDataInFlag(.clk(clk), .rstn(rstn), .dataIn(sensorDataRefresh), .Flag(dataInFlag));

    always @(posedge sensorDataRefresh) begin
        Amp[0] <= 0; Amp[1] <= 0; Amp[2] <= 0; 
        Coff <= 0;
    end    



    wire [31:0] absSpeed = {1'b0, data[3][30:0]};
    assign dataValid = (absSpeed > speed13760) && (absSpeed < speed23661);





//-----------------------------speedRegion-------------------------//
//  corresponding absSpeed to refresh speedRegion and DFTCoff
    reg [3:0] speedRegion;
    reg [31:0] DFTCoffRE[0:size-1], DFTCoffIM[0:size-1];
    reg [31:0] array[0:5][0:size-1];
    always @(posedge sensorDataRefresh or negedge rstn) begin
        if(!rstn) begin
            speedRegion <= 0; Coff <= 0;
            for(integer i = 0; i < 3; i = i + 1) begin
                Amp[i] <= 32'b0;
            end
            for(integer i = 0; i < size; i = i + 1) begin
                DFTCoffRE[i] <= 32'b0;       DFTCoffIM[i] <= 32'b0;
            end
            for(integer i = 0; i < 6; i = i + 1) begin
                for(integer j = 0; j < size; j = j + 1) begin
                    array[i][j] <= 32'b0;
                end
            end
        end else begin
            case(speedRegion)
                4'd0: begin
                    if(absSpeed > speed13860) begin
                        speedRegion <= 1;
                    end
                end
                4'd1: begin
                    if(absSpeed < speed13760) begin
                        speedRegion <= 0;
                    end else if(absSpeed > speed14885) begin
                        speedRegion <= 2;
                    end
                end
                4'd2: begin
                    if(absSpeed < speed14785) begin
                        speedRegion <= 1;
                    end else if(absSpeed > speed16076) begin
                        speedRegion <= 3;
                    end
                end
                4'd3: begin
                    if(absSpeed < speed15976) begin
                        speedRegion <= 2;
                    end else if(absSpeed > speed17474) begin
                        speedRegion <= 4;
                    end
                end
                4'd4: begin
                    if(absSpeed < speed17374) begin
                        speedRegion <= 3;
                    end else if(absSpeed > speed19141) begin
                        speedRegion <= 5;
                    end
                end
                4'd5: begin
                    if(absSpeed < speed19041) begin
                        speedRegion <= 4;
                    end else if(absSpeed > speed21161) begin
                        speedRegion <= 6;
                    end
                end
                4'd6: begin
                    if(absSpeed < speed21061) begin
                        speedRegion <= 5;
                    end else if(absSpeed > speed23661) begin
                        speedRegion <= 7;
                    end
                end
                4'd7: begin
                    if(absSpeed < speed23561) begin
                        speedRegion <= 6;
                    end
                end
                default : begin
                    speedRegion <= 0;
                end
            endcase
            case(speedRegion)
                4'd0, 4'd7: begin
                    for(integer i = 0; i < size; i = i + 1) begin
                        DFTCoffRE[i] <= 32'b0;       DFTCoffIM[i] <= 32'b0;
                    end
                end
				4'd1: begin
					DFTCoffRE[0] 	<= 32'h3F800000;
					DFTCoffIM[0] 	<= 32'h00000000;
					DFTCoffRE[1] 	<= 32'h3F7994E0;
					DFTCoffIM[1] 	<= 32'h3E63DC87;
					DFTCoffRE[2] 	<= 32'h3F66A5E5;
					DFTCoffIM[2] 	<= 32'h3EDE2602;
					DFTCoffRE[3] 	<= 32'h3F48261C;
					DFTCoffIM[3] 	<= 32'h3F1F9D07;
					DFTCoffRE[4] 	<= 32'h3F1F9D07;
					DFTCoffIM[4] 	<= 32'h3F48261C;
					DFTCoffRE[5] 	<= 32'h3EDE2602;
					DFTCoffIM[5] 	<= 32'h3F66A5E5;
					DFTCoffRE[6] 	<= 32'h3E63DC87;
					DFTCoffIM[6] 	<= 32'h3F7994E0;
					DFTCoffRE[7] 	<= 32'h248D3000;
					DFTCoffIM[7] 	<= 32'h3F800000;
					DFTCoffRE[8] 	<= 32'hBE63DC87;
					DFTCoffIM[8] 	<= 32'h3F7994E0;
					DFTCoffRE[9] 	<= 32'hBEDE2602;
					DFTCoffIM[9] 	<= 32'h3F66A5E5;
					DFTCoffRE[10] 	<= 32'hBF1F9D07;
					DFTCoffIM[10] 	<= 32'h3F48261C;
					DFTCoffRE[11] 	<= 32'hBF48261C;
					DFTCoffIM[11] 	<= 32'h3F1F9D07;
					DFTCoffRE[12] 	<= 32'hBF66A5E5;
					DFTCoffIM[12] 	<= 32'h3EDE2602;
					DFTCoffRE[13] 	<= 32'hBF7994E0;
					DFTCoffIM[13] 	<= 32'h3E63DC87;
					DFTCoffRE[14] 	<= 32'hBF800000;
					DFTCoffIM[14] 	<= 32'h250D3000;
					DFTCoffRE[15] 	<= 32'hBF7994E0;
					DFTCoffIM[15] 	<= 32'hBE63DC87;
					DFTCoffRE[16] 	<= 32'hBF66A5E5;
					DFTCoffIM[16] 	<= 32'hBEDE2602;
					DFTCoffRE[17] 	<= 32'hBF48261C;
					DFTCoffIM[17] 	<= 32'hBF1F9D07;
					DFTCoffRE[18] 	<= 32'hBF1F9D07;
					DFTCoffIM[18] 	<= 32'hBF48261C;
					DFTCoffRE[19] 	<= 32'hBEDE2602;
					DFTCoffIM[19] 	<= 32'hBF66A5E5;
					DFTCoffRE[20] 	<= 32'hBE63DC87;
					DFTCoffIM[20] 	<= 32'hBF7994E0;
					DFTCoffRE[21] 	<= 32'hA553C800;
					DFTCoffIM[21] 	<= 32'hBF800000;
					DFTCoffRE[22] 	<= 32'h3E63DC87;
					DFTCoffIM[22] 	<= 32'hBF7994E0;
					DFTCoffRE[23] 	<= 32'h3EDE2602;
					DFTCoffIM[23] 	<= 32'hBF66A5E5;
					DFTCoffRE[24] 	<= 32'h3F1F9D07;
					DFTCoffIM[24] 	<= 32'hBF48261C;
					DFTCoffRE[25] 	<= 32'h3F48261C;
					DFTCoffIM[25] 	<= 32'hBF1F9D07;
					DFTCoffRE[26] 	<= 32'h3F66A5E5;
					DFTCoffIM[26] 	<= 32'hBEDE2602;
					DFTCoffRE[27] 	<= 32'h3F7994E0;
					DFTCoffIM[27] 	<= 32'hBE63DC87;
				end
				4'd2: begin
					DFTCoffRE[0] 	<= 32'h00000000;
					DFTCoffIM[0] 	<= 32'h00000000;
					DFTCoffRE[1] 	<= 32'h00000000;
					DFTCoffIM[1] 	<= 32'h00000000;
					DFTCoffRE[2] 	<= 32'h3F800000;
					DFTCoffIM[2] 	<= 32'h00000000;
					DFTCoffRE[3] 	<= 32'h3F788FA5;
					DFTCoffIM[3] 	<= 32'h3E750F2A;
					DFTCoffRE[4] 	<= 32'h3F62AD3F;
					DFTCoffIM[4] 	<= 32'h3EEDF032;
					DFTCoffRE[5] 	<= 32'h3F3F9E67;
					DFTCoffIM[5] 	<= 32'h3F29C268;
					DFTCoffRE[6] 	<= 32'h3F116CB1;
					DFTCoffIM[6] 	<= 32'h3F52AF12;
					DFTCoffRE[7] 	<= 32'h3EB58EC6;
					DFTCoffIM[7] 	<= 32'h3F6F5D39;
					DFTCoffRE[8] 	<= 32'h3DF6DBEF;
					DFTCoffIM[8] 	<= 32'h3F7E222B;
					DFTCoffRE[9] 	<= 32'hBDF6DBEF;
					DFTCoffIM[9] 	<= 32'h3F7E222B;
					DFTCoffRE[10] 	<= 32'hBEB58EC6;
					DFTCoffIM[10] 	<= 32'h3F6F5D39;
					DFTCoffRE[11] 	<= 32'hBF116CB1;
					DFTCoffIM[11] 	<= 32'h3F52AF12;
					DFTCoffRE[12] 	<= 32'hBF3F9E67;
					DFTCoffIM[12] 	<= 32'h3F29C268;
					DFTCoffRE[13] 	<= 32'hBF62AD3F;
					DFTCoffIM[13] 	<= 32'h3EEDF032;
					DFTCoffRE[14] 	<= 32'hBF788FA5;
					DFTCoffIM[14] 	<= 32'h3E750F2A;
					DFTCoffRE[15] 	<= 32'hBF800000;
					DFTCoffIM[15] 	<= 32'hA5B96800;
					DFTCoffRE[16] 	<= 32'hBF788FA5;
					DFTCoffIM[16] 	<= 32'hBE750F2A;
					DFTCoffRE[17] 	<= 32'hBF62AD3F;
					DFTCoffIM[17] 	<= 32'hBEEDF032;
					DFTCoffRE[18] 	<= 32'hBF3F9E67;
					DFTCoffIM[18] 	<= 32'hBF29C268;
					DFTCoffRE[19] 	<= 32'hBF116CB1;
					DFTCoffIM[19] 	<= 32'hBF52AF12;
					DFTCoffRE[20] 	<= 32'hBEB58EC6;
					DFTCoffIM[20] 	<= 32'hBF6F5D39;
					DFTCoffRE[21] 	<= 32'hBDF6DBEF;
					DFTCoffIM[21] 	<= 32'hBF7E222B;
					DFTCoffRE[22] 	<= 32'h3DF6DBEF;
					DFTCoffIM[22] 	<= 32'hBF7E222B;
					DFTCoffRE[23] 	<= 32'h3EB58EC6;
					DFTCoffIM[23] 	<= 32'hBF6F5D39;
					DFTCoffRE[24] 	<= 32'h3F116CB1;
					DFTCoffIM[24] 	<= 32'hBF52AF12;
					DFTCoffRE[25] 	<= 32'h3F3F9E67;
					DFTCoffIM[25] 	<= 32'hBF29C268;
					DFTCoffRE[26] 	<= 32'h3F62AD3F;
					DFTCoffIM[26] 	<= 32'hBEEDF032;
					DFTCoffRE[27] 	<= 32'h3F788FA5;
					DFTCoffIM[27] 	<= 32'hBE750F2A;
				end
				4'd3: begin
					DFTCoffRE[0] 	<= 32'h00000000;
					DFTCoffIM[0] 	<= 32'h00000000;
					DFTCoffRE[1] 	<= 32'h00000000;
					DFTCoffIM[1] 	<= 32'h00000000;
					DFTCoffRE[2] 	<= 32'h00000000;
					DFTCoffIM[2] 	<= 32'h00000000;
					DFTCoffRE[3] 	<= 32'h00000000;
					DFTCoffIM[3] 	<= 32'h00000000;
					DFTCoffRE[4] 	<= 32'h3F800000;
					DFTCoffIM[4] 	<= 32'h00000000;
					DFTCoffRE[5] 	<= 32'h3F7746EA;
					DFTCoffIM[5] 	<= 32'h3E8483EE;
					DFTCoffRE[6] 	<= 32'h3F5DB3D7;
					DFTCoffIM[6] 	<= 32'h3F000000;
					DFTCoffRE[7] 	<= 32'h3F3504F3;
					DFTCoffIM[7] 	<= 32'h3F3504F3;
					DFTCoffRE[8] 	<= 32'h3F000000;
					DFTCoffIM[8] 	<= 32'h3F5DB3D7;
					DFTCoffRE[9] 	<= 32'h3E8483EE;
					DFTCoffIM[9] 	<= 32'h3F7746EA;
					DFTCoffRE[10] 	<= 32'h248D3000;
					DFTCoffIM[10] 	<= 32'h3F800000;
					DFTCoffRE[11] 	<= 32'hBE8483EE;
					DFTCoffIM[11] 	<= 32'h3F7746EA;
					DFTCoffRE[12] 	<= 32'hBF000000;
					DFTCoffIM[12] 	<= 32'h3F5DB3D7;
					DFTCoffRE[13] 	<= 32'hBF3504F3;
					DFTCoffIM[13] 	<= 32'h3F3504F3;
					DFTCoffRE[14] 	<= 32'hBF5DB3D7;
					DFTCoffIM[14] 	<= 32'h3F000000;
					DFTCoffRE[15] 	<= 32'hBF7746EA;
					DFTCoffIM[15] 	<= 32'h3E8483EE;
					DFTCoffRE[16] 	<= 32'hBF800000;
					DFTCoffIM[16] 	<= 32'h250D3000;
					DFTCoffRE[17] 	<= 32'hBF7746EA;
					DFTCoffIM[17] 	<= 32'hBE8483EE;
					DFTCoffRE[18] 	<= 32'hBF5DB3D7;
					DFTCoffIM[18] 	<= 32'hBF000000;
					DFTCoffRE[19] 	<= 32'hBF3504F3;
					DFTCoffIM[19] 	<= 32'hBF3504F3;
					DFTCoffRE[20] 	<= 32'hBF000000;
					DFTCoffIM[20] 	<= 32'hBF5DB3D7;
					DFTCoffRE[21] 	<= 32'hBE8483EE;
					DFTCoffIM[21] 	<= 32'hBF7746EA;
					DFTCoffRE[22] 	<= 32'hA553C800;
					DFTCoffIM[22] 	<= 32'hBF800000;
					DFTCoffRE[23] 	<= 32'h3E8483EE;
					DFTCoffIM[23] 	<= 32'hBF7746EA;
					DFTCoffRE[24] 	<= 32'h3F000000;
					DFTCoffIM[24] 	<= 32'hBF5DB3D7;
					DFTCoffRE[25] 	<= 32'h3F3504F3;
					DFTCoffIM[25] 	<= 32'hBF3504F3;
					DFTCoffRE[26] 	<= 32'h3F5DB3D7;
					DFTCoffIM[26] 	<= 32'hBF000000;
					DFTCoffRE[27] 	<= 32'h3F7746EA;
					DFTCoffIM[27] 	<= 32'hBE8483EE;
				end
				4'd4: begin
					DFTCoffRE[0] 	<= 32'h00000000;
					DFTCoffIM[0] 	<= 32'h00000000;
					DFTCoffRE[1] 	<= 32'h00000000;
					DFTCoffIM[1] 	<= 32'h00000000;
					DFTCoffRE[2] 	<= 32'h00000000;
					DFTCoffIM[2] 	<= 32'h00000000;
					DFTCoffRE[3] 	<= 32'h00000000;
					DFTCoffIM[3] 	<= 32'h00000000;
					DFTCoffRE[4] 	<= 32'h00000000;
					DFTCoffIM[4] 	<= 32'h00000000;
					DFTCoffRE[5] 	<= 32'h00000000;
					DFTCoffIM[5] 	<= 32'h00000000;
					DFTCoffRE[6] 	<= 32'h3F800000;
					DFTCoffIM[6] 	<= 32'h00000000;
					DFTCoffRE[7] 	<= 32'h3F75A155;
					DFTCoffIM[7] 	<= 32'h3E903F40;
					DFTCoffRE[8] 	<= 32'h3F575C64;
					DFTCoffIM[8] 	<= 32'h3F0A6770;
					DFTCoffRE[9] 	<= 32'h3F27A4F4;
					DFTCoffIM[9] 	<= 32'h3F4178CE;
					DFTCoffRE[10] 	<= 32'h3ED4B147;
					DFTCoffIM[10] 	<= 32'h3F68DDA4;
					DFTCoffRE[11] 	<= 32'h3E11BAFB;
					DFTCoffIM[11] 	<= 32'h3F7D64F0;
					DFTCoffRE[12] 	<= 32'hBE11BAFB;
					DFTCoffIM[12] 	<= 32'h3F7D64F0;
					DFTCoffRE[13] 	<= 32'hBED4B147;
					DFTCoffIM[13] 	<= 32'h3F68DDA4;
					DFTCoffRE[14] 	<= 32'hBF27A4F4;
					DFTCoffIM[14] 	<= 32'h3F4178CE;
					DFTCoffRE[15] 	<= 32'hBF575C64;
					DFTCoffIM[15] 	<= 32'h3F0A6770;
					DFTCoffRE[16] 	<= 32'hBF75A155;
					DFTCoffIM[16] 	<= 32'h3E903F40;
					DFTCoffRE[17] 	<= 32'hBF800000;
					DFTCoffIM[17] 	<= 32'h26234C00;
					DFTCoffRE[18] 	<= 32'hBF75A155;
					DFTCoffIM[18] 	<= 32'hBE903F40;
					DFTCoffRE[19] 	<= 32'hBF575C64;
					DFTCoffIM[19] 	<= 32'hBF0A6770;
					DFTCoffRE[20] 	<= 32'hBF27A4F4;
					DFTCoffIM[20] 	<= 32'hBF4178CE;
					DFTCoffRE[21] 	<= 32'hBED4B147;
					DFTCoffIM[21] 	<= 32'hBF68DDA4;
					DFTCoffRE[22] 	<= 32'hBE11BAFB;
					DFTCoffIM[22] 	<= 32'hBF7D64F0;
					DFTCoffRE[23] 	<= 32'h3E11BAFB;
					DFTCoffIM[23] 	<= 32'hBF7D64F0;
					DFTCoffRE[24] 	<= 32'h3ED4B147;
					DFTCoffIM[24] 	<= 32'hBF68DDA4;
					DFTCoffRE[25] 	<= 32'h3F27A4F4;
					DFTCoffIM[25] 	<= 32'hBF4178CE;
					DFTCoffRE[26] 	<= 32'h3F575C64;
					DFTCoffIM[26] 	<= 32'hBF0A6770;
					DFTCoffRE[27] 	<= 32'h3F75A155;
					DFTCoffIM[27] 	<= 32'hBE903F40;
				end
				4'd5: begin
					DFTCoffRE[0] 	<= 32'h00000000;
					DFTCoffIM[0] 	<= 32'h00000000;
					DFTCoffRE[1] 	<= 32'h00000000;
					DFTCoffIM[1] 	<= 32'h00000000;
					DFTCoffRE[2] 	<= 32'h00000000;
					DFTCoffIM[2] 	<= 32'h00000000;
					DFTCoffRE[3] 	<= 32'h00000000;
					DFTCoffIM[3] 	<= 32'h00000000;
					DFTCoffRE[4] 	<= 32'h00000000;
					DFTCoffIM[4] 	<= 32'h00000000;
					DFTCoffRE[5] 	<= 32'h00000000;
					DFTCoffIM[5] 	<= 32'h00000000;
					DFTCoffRE[6] 	<= 32'h00000000;
					DFTCoffIM[6] 	<= 32'h00000000;
					DFTCoffRE[7] 	<= 32'h00000000;
					DFTCoffIM[7] 	<= 32'h00000000;
					DFTCoffRE[8] 	<= 32'h3F800000;
					DFTCoffIM[8] 	<= 32'h00000000;
					DFTCoffRE[9] 	<= 32'h3F737871;
					DFTCoffIM[9] 	<= 32'h3E9E377A;
					DFTCoffRE[10] 	<= 32'h3F4F1BBD;
					DFTCoffIM[10] 	<= 32'h3F167918;
					DFTCoffRE[11] 	<= 32'h3F167918;
					DFTCoffIM[11] 	<= 32'h3F4F1BBD;
					DFTCoffRE[12] 	<= 32'h3E9E377A;
					DFTCoffIM[12] 	<= 32'h3F737871;
					DFTCoffRE[13] 	<= 32'h248D3000;
					DFTCoffIM[13] 	<= 32'h3F800000;
					DFTCoffRE[14] 	<= 32'hBE9E377A;
					DFTCoffIM[14] 	<= 32'h3F737871;
					DFTCoffRE[15] 	<= 32'hBF167918;
					DFTCoffIM[15] 	<= 32'h3F4F1BBD;
					DFTCoffRE[16] 	<= 32'hBF4F1BBD;
					DFTCoffIM[16] 	<= 32'h3F167918;
					DFTCoffRE[17] 	<= 32'hBF737871;
					DFTCoffIM[17] 	<= 32'h3E9E377A;
					DFTCoffRE[18] 	<= 32'hBF800000;
					DFTCoffIM[18] 	<= 32'h250D3000;
					DFTCoffRE[19] 	<= 32'hBF737871;
					DFTCoffIM[19] 	<= 32'hBE9E377A;
					DFTCoffRE[20] 	<= 32'hBF4F1BBD;
					DFTCoffIM[20] 	<= 32'hBF167918;
					DFTCoffRE[21] 	<= 32'hBF167918;
					DFTCoffIM[21] 	<= 32'hBF4F1BBD;
					DFTCoffRE[22] 	<= 32'hBE9E377A;
					DFTCoffIM[22] 	<= 32'hBF737871;
					DFTCoffRE[23] 	<= 32'hA553C800;
					DFTCoffIM[23] 	<= 32'hBF800000;
					DFTCoffRE[24] 	<= 32'h3E9E377A;
					DFTCoffIM[24] 	<= 32'hBF737871;
					DFTCoffRE[25] 	<= 32'h3F167918;
					DFTCoffIM[25] 	<= 32'hBF4F1BBD;
					DFTCoffRE[26] 	<= 32'h3F4F1BBD;
					DFTCoffIM[26] 	<= 32'hBF167918;
					DFTCoffRE[27] 	<= 32'h3F737871;
					DFTCoffIM[27] 	<= 32'hBE9E377A;
				end
				4'd6: begin
					DFTCoffRE[0] 	<= 32'h00000000;
					DFTCoffIM[0] 	<= 32'h00000000;
					DFTCoffRE[1] 	<= 32'h00000000;
					DFTCoffIM[1] 	<= 32'h00000000;
					DFTCoffRE[2] 	<= 32'h00000000;
					DFTCoffIM[2] 	<= 32'h00000000;
					DFTCoffRE[3] 	<= 32'h00000000;
					DFTCoffIM[3] 	<= 32'h00000000;
					DFTCoffRE[4] 	<= 32'h00000000;
					DFTCoffIM[4] 	<= 32'h00000000;
					DFTCoffRE[5] 	<= 32'h00000000;
					DFTCoffIM[5] 	<= 32'h00000000;
					DFTCoffRE[6] 	<= 32'h00000000;
					DFTCoffIM[6] 	<= 32'h00000000;
					DFTCoffRE[7] 	<= 32'h00000000;
					DFTCoffIM[7] 	<= 32'h00000000;
					DFTCoffRE[8] 	<= 32'h00000000;
					DFTCoffIM[8] 	<= 32'h00000000;
					DFTCoffRE[9] 	<= 32'h00000000;
					DFTCoffIM[9] 	<= 32'h00000000;
					DFTCoffRE[10] 	<= 32'h3F800000;
					DFTCoffIM[10] 	<= 32'h00000000;
					DFTCoffRE[11] 	<= 32'h3F708FB2;
					DFTCoffIM[11] 	<= 32'h3EAF1D44;
					DFTCoffRE[12] 	<= 32'h3F441B7D;
					DFTCoffIM[12] 	<= 32'h3F248DBB;
					DFTCoffRE[13] 	<= 32'h3F000000;
					DFTCoffIM[13] 	<= 32'h3F5DB3D7;
					DFTCoffRE[14] 	<= 32'h3E31D0D4;
					DFTCoffIM[14] 	<= 32'h3F7C1C5C;
					DFTCoffRE[15] 	<= 32'hBE31D0D4;
					DFTCoffIM[15] 	<= 32'h3F7C1C5C;
					DFTCoffRE[16] 	<= 32'hBF000000;
					DFTCoffIM[16] 	<= 32'h3F5DB3D7;
					DFTCoffRE[17] 	<= 32'hBF441B7D;
					DFTCoffIM[17] 	<= 32'h3F248DBB;
					DFTCoffRE[18] 	<= 32'hBF708FB2;
					DFTCoffIM[18] 	<= 32'h3EAF1D44;
					DFTCoffRE[19] 	<= 32'hBF800000;
					DFTCoffIM[19] 	<= 32'h250D3000;
					DFTCoffRE[20] 	<= 32'hBF708FB2;
					DFTCoffIM[20] 	<= 32'hBEAF1D44;
					DFTCoffRE[21] 	<= 32'hBF441B7D;
					DFTCoffIM[21] 	<= 32'hBF248DBB;
					DFTCoffRE[22] 	<= 32'hBF000000;
					DFTCoffIM[22] 	<= 32'hBF5DB3D7;
					DFTCoffRE[23] 	<= 32'hBE31D0D4;
					DFTCoffIM[23] 	<= 32'hBF7C1C5C;
					DFTCoffRE[24] 	<= 32'h3E31D0D4;
					DFTCoffIM[24] 	<= 32'hBF7C1C5C;
					DFTCoffRE[25] 	<= 32'h3F000000;
					DFTCoffIM[25] 	<= 32'hBF5DB3D7;
					DFTCoffRE[26] 	<= 32'h3F441B7D;
					DFTCoffIM[26] 	<= 32'hBF248DBB;
					DFTCoffRE[27] 	<= 32'h3F708FB2;
					DFTCoffIM[27] 	<= 32'hBEAF1D44;
				end              
            endcase
        end
    end




//-----------------------------HistoryData-------------------------//
    // data sequence: IA, IB, IC, Speed, Udc, Idc
    //    array     [0] [1] [2] ... [27]
    // sample time   T  T-1 T-2 ... T-27    
    // HistoryData: current time refresh the current data, ensure to satisfy data structure at any time
    generate
        genvar i;
        for (i = 0; i < 6; i = i + 1) begin:History
            HistoryData #(.size(size)) IHistoryData(.rstn(rstn), .dataIn(sensorDataRefresh), .data(data[i]), .array(array[i]));
        end
    endgenerate





    wire [2:0] dataOutFdmt;
    generate
        for (i = 0; i < 3; i = i + 1) begin:Fdmt
            Fundamentals #(.size(size)) IFundamentals(.clk(clk), .rstn(rstn), .dataIn(sensorDataRefresh), .data(array[i]), .RE(DFTCoffRE), .IM(DFTCoffIM), .dataOut(dataOutFdmt[i]), .result(Amp[i]));
        end
    endgenerate



    wire dataOutTmp;
    Coefficients ICoefficients(.clk(clk), .rstn((&dataOutFdmt)&dataInFlag), .dataIn((&dataOutFdmt)&dataInFlag), .amp(Amp), .dataOut(dataOutTmp), .coff(Coff));


    assign dataOut = (&dataOutFdmt) & dataOutTmp & dataInFlag;




endmodule //FFT

