// Asynchronous signed integer full adder or subtractor
module AddInt #(
    width = 32
)(
    input sub,
    input [width-1:0] x, y,
    output cout, ovfl,
    output [width-1:0] result
);
/*
    sub : 0 for addition, 1 for subtraction
    x,y : the data to be added or subtracted, x,y are width-bits-signed-integer
    cout : carry out signal for unsigned integer addition
    ovfl : carry the overflow signal for signed integer addition
    result : the sum or sub of x and y
*/

/*
             ____      ____      ____      ____      ____  
      clk:  |    |____|    |____|    |____|    |____|    |_
                 ___         _________          ___________
      sub:  ____|   |_______|         |________|          
            __________ _________ _________ _________ ______
        x:  _x1_______X_x2______X_x3______X_x4______X_x5___
            __________ _________ _________ _________ ______
        y:  _y1_______X_y2______X_y3______X_y4______X_y5___
            __________ _________ _________ _________ ______
   result:  __________X_x1+y1___X_x2-y2___X_x3+y3___X_x4-y4

note: Changes in the input can be quickly passed to the output with only gate delay, a clk cycle is not nessary but recommended.
*/

    wire [width-1:0] yTmp, G, P;
    wire [width:0] C;
    assign yTmp = y ^ {width{sub}};


    generate
    genvar i;
        assign C[0] = sub;
        for(i = 0; i < width; i = i + 1) begin:Add
            assign result[i] = x[i] ^ yTmp[i] ^ C[i];
            assign G[i] = x[i] & yTmp[i];
            assign P[i] = x[i] ^ yTmp[i];
            assign C[i+1] = G[i] | (P[i] & C[i]);
        end
    endgenerate

    assign cout = C[width] ^ sub;
    assign ovfl = C[width] ^ C[width-1];

endmodule //addInt