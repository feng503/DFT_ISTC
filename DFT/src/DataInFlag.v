// 
module DataInFlag (
    input clk, rstn, dataIn,
    output Flag
);
/*
    clk : clock signal, usually 50MHz or 100MHz
    rstn : reset signal not, [=0: reset, =1: normal]
    dataIn : data input signal, [=posedge means data is freshed]
    Flag : flag signal, usually equal 1, [when dataIn is freshed, Flag = 0 until next posedge of clk]
*/

/*
             _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   
      clk:  | |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_|   
                 ________________________________________________________________________________________________________________________________________________________________________________________
     rstn:  ____|                                                                                                                                                                                       
                                                     ________________________________________                                         ________________________________________
   dataIn:  ________________________________________|                                        |_______________________________________|                                        |__________________________
            ________________________________________     ____________________________________________________________________________    ________________________________________________________________
    Flag:                                           |___|                                                                            |__| 

*/


    reg dataInNext;
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            dataInNext  <= 1'b0;
        end else begin
            dataInNext  <= dataIn;
        end
    end

    assign Flag = ~dataIn | dataInNext;

endmodule //DataInFlag
