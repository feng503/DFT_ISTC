module MultiplyInt #(
    parameter width = 32
)(
    input clk, rstn, dataIn, sign,
    input [width-1:0] x, y,
    output reg dataOut,
    output reg [2*width-1:0] prod
);

/*
    clk : clock signal, usually 50MHz or 100MHz
    rstn : reset signal not, [=0: reset, =1: normal]
    dataIn : data input signal, [=posedge means data is freshed]
    sign : the input digital is signed or unsigned [=0: unsigned, =1: signed]
    x,y : the data to be multiplied
    dataOut : data output signal, [=1 means data is prepared, =0 means data is not prepared]
    result: the prod of x and y
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
   x or y:  ________________________________________X_________________________________________________________________________________X__________________________________________________________________
                                                                                                      ________________________________                                                  _________________
  dataOut:  XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX_______________________________...______________|                                |_______________________________...______________|
            ________________________________________ ________________________________________________ ________________________________ ________________________________________________ _________________
     prod:  (0.00)__________________________________X(0.00)__________________________________________X(x*y unsigned)__________________X(0.00)__________________________________________X(x*y signed)_____

*/

    wire dataInFlag;
    DataInFlag IDataInFlag(.clk(clk), .rstn(rstn), .dataIn(dataIn), .Flag(dataInFlag));
    
    always @(posedge dataIn) begin
        prod <= 0;
    end

    reg [width-1:0] shiftY, sourceX, sourceY;
    reg [2*width-1:0] shiftX, shiftProd;
    reg signX, signY, signProd;

    reg dataOutTmp;
    reg [clog2(width)-1:0] cnt;

    always @(posedge clk or negedge rstn) begin
        if (!rstn || !dataInFlag) begin
            shiftX <= 0; shiftY <= 0; shiftProd <= 0; 
            dataOutTmp <= 0; cnt <= 0;
            if (!rstn) begin
                signX <= 0; signY <= 0; signProd <= 0;
                sourceX <= 0; sourceY <= 0;
            end else if (sign) begin
                signX <= x[width-1]; signY <= y[width-1]; signProd <= x[width-1] ^ y[width-1];
                sourceX <= {1'b0, (({(width-1){x[width-1]}} ^ x[width-2:0]) + x[width-1])};
                sourceY <= {1'b0, ((y[width-2:0] ^ {(width-1){y[width-1]}}) + y[width-1])};
            end else begin
                signX <= 0; signY <= 0; signProd <= 0;
                sourceX <= x; sourceY <= y;
            end
        end else if (dataInFlag && cnt == 0) begin
            shiftX <= sourceX << 1;
            shiftY <= sourceY >> 1;
            shiftProd <= sourceY[0] ? sourceX : 0;
            cnt <= cnt + 1;
        end else if (dataInFlag && cnt < width) begin
            shiftX <= shiftX << 1;
            shiftY <= shiftY >> 1;
            shiftProd <= shiftProd + (shiftY[0] ? shiftX : 0);
            cnt <= cnt + 1;
        end else if (dataInFlag) begin
            if (sign) begin
                prod <= {signProd, (({(2*width-1){signProd}} ^ shiftProd[2*width-2:0]) + signProd)};
            end else begin
                prod <= shiftProd;
            end
            dataOutTmp <= 1;
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

endmodule //MultiplyInt