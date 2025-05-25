module DivideInt #(
    parameter widthDend = 32,
    parameter widthDsor = 32
)(
    input clk, rstn, dataIn, sign,
    input [widthDend-1:0] dend,
    input [widthDsor-1:0] dsor,
    output dataOut,
    output reg [widthDend-1:0] quot,
    output reg [widthDsor-1:0] rmdr
);

/*
    clk : clock signal, usually 50MHz or 100MHz
    rstn : reset signal not, [=0: reset, =1: normal]
    dataIn : data input signal, [=posedge means data is freshed]
    sign : the input digital is signed or unsigned [=0: unsigned, =1: signed]
    dend : the data to be divided
    dsor : the number by which dividend is divided
    dataOut : data output signal, [=1 means data is prepared, =0 means data is not prepared]
    quot : the quotient of dividend and divisor
    rmdr : the remainder of dividend and divisor
*/

/*
             _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   
      clk:  | |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_|   
                 ________________________________________________________________________________________________________________________________________________________________________________________
     rstn:  ____|
                                                     ________________________________________                                          ________________________________________
   dataIn:  ________________________________________|                                        |________________________________________|                                        |_________________________
                                                                                                       __________________________________________________________________________________________________
     sign:  __________________________________________________________________________________________|
            ________________________________________ _________________________________________________________________________________ __________________________________________________________________
 denddsor:  ________________________________________X_________________________________________________________________________________X__________________________________________________________________
                                                                                                      ________________________________                                                  _________________
  dataOut:  XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX_______________________________...______________|                                |_______________________________...______________|
            ________________________________________ ________________________________________________ ________________________________ ________________________________________________ _________________
     quot:  (0.00)__________________________________X(0.00)__________________________________________X(x/y unsigned)__________________X(0.00)__________________________________________X(x/y signed)_____
            ________________________________________ ________________________________________________ ________________________________ ________________________________________________ _________________
     rmdr:  (0.00)__________________________________X(0.00)__________________________________________X(x%y unsigned)__________________X(0.00)__________________________________________X(x%y signed)_____
*/


    wire dataInFlag;
    DataInFlag IDataInFlag(.clk(clk), .rstn(rstn), .dataIn(dataIn), .Flag(dataInFlag));

    always @(posedge dataIn) begin
        quot <= 0; rmdr <= 0;
    end    

    reg signDend, signDsor, signQuot, signRmdr;
    reg [widthDend-1:0] absDend, quotTmp, shiftDend;
    reg [widthDsor-1:0] absDsor;
    reg [widthDsor:0] rmdrTmp;

    reg dataOutTmp;
    reg [clog2(widthDend)-1:0] cnt;

    always @(posedge clk or negedge rstn) begin
        if (!rstn || !dataInFlag) begin 
            quot <= 0; rmdr <= 0;
            if ((!rstn) || (!sign)) begin
                signDend <= 0; signDsor <= 0; signQuot <= 0; signRmdr <= 0;
                if (rstn) begin
                    absDend <= dend; absDsor <= dsor;
                end
            end else begin
                signDend <= dend[widthDend-1]; signDsor <= dsor[widthDsor-1]; signQuot <= dend[widthDend-1] ^ dsor[widthDsor-1]; signRmdr <= 0;
                absDend <= {1'd0, ((dend[widthDend-2:0] ^ {widthDend-1{dend[widthDend-1]}}) + dend[widthDend-1])};
                absDsor <= {1'd0, ((dsor[widthDsor-2:0] ^ {widthDsor-1{dsor[widthDsor-1]}}) + dsor[widthDsor-1])};
            end
            quotTmp <= 0; rmdrTmp <= 0;
            dataOutTmp <= 0; cnt <= 0;
        end else if (dataInFlag && cnt == 0) begin
            quotTmp <= 0;
            rmdrTmp <= {{(widthDsor){1'b0}}, absDend[widthDend-1]};
            shiftDend <= absDend << 1;
            cnt <= cnt + 1;
        end else if (dataInFlag && cnt <= widthDend) begin 
            rmdrTmp <= (rmdrTmp >= absDsor) ? ({rmdrTmp - absDsor, shiftDend[widthDend-1]}) : ({rmdrTmp, shiftDend[widthDend-1]});
            quotTmp <= (rmdrTmp >= absDsor) ? (quotTmp + (1 << (widthDend - cnt))) : (quotTmp);
            shiftDend <= shiftDend << 1;
            cnt <= cnt + 1;
        end else if (dataInFlag && cnt > widthDend) begin
            quot <= (quotTmp ^ {widthDend{signQuot}}) + signQuot;
            rmdr <= (rmdrTmp[widthDsor:1] ^ {widthDsor{signDend}}) + signDend;
            dataOutTmp <= 1'b1;
        end else begin
            dataOutTmp <= 1'b0;
            quot <= 0; rmdr <= 0;
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



endmodule //DivideInt