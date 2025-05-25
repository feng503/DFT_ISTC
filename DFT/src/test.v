// the testbench of other modules

`timescale 1ns/100ps

module test;
 
//-----------------------------module FFT definition-----------------------------
    reg clk, rstn, sensorDataRefresh;
    reg [31:0] A, B, C, speed, Udc, Idc;
    wire data_valid, data_out;
    wire [31:0] Amp[0:2], Coff;
    wire [31:0] data[0:5];
    assign data[0] = A;
    assign data[1] = B;
    assign data[2] = C;
    assign data[3] = speed;
    assign data[4] = Udc;
    assign data[5] = Idc;

    FFT IFFT(.clk(clk), .rstn(rstn), .sensorDataRefresh(sensorDataRefresh), 
                  .data(data), .dataValid(data_valid), .dataOut(data_out), .Amp(Amp), .Coff(Coff));



//-----------------------------time sequence definition-----------------------------
    initial begin
        clk = 0; rstn = 0;
        #10;     rstn = 1;
        forever #5 clk = ~clk;
    end

    initial begin
        sensorDataRefresh = 0;
        forever #1000 sensorDataRefresh = ~sensorDataRefresh;
    end

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, test);
        #20000;
        $finish;
    end

    integer clk_number_in_sensor_data = 0;
    reg sensorDataRefreshn;
    wire sensorDataRefresh_posedge = sensorDataRefresh & sensorDataRefreshn;
    always @(posedge clk) begin
        sensorDataRefreshn = ~sensorDataRefresh;
        if (sensorDataRefresh_posedge) begin
            clk_number_in_sensor_data = 0;
        end else begin 
            clk_number_in_sensor_data = clk_number_in_sensor_data + 1;
        end
    end



//-----------------------------data reading from CSV file-----------------------------
    integer file_read, skip_lines, file_line_number;
    string temp;
    real file_time, file_A_phase_current, file_B_phase_current, file_C_phase_current, file_speed, file_Bus_voltage, file_Bus_current;

    initial begin
        file_line_number = 0;
        file_time = 0; file_A_phase_current = 0; file_B_phase_current = 0; file_C_phase_current = 0;
        file_speed = 0; file_Bus_voltage = 0; file_Bus_current = 0;

        $display("\n=== Current Working Directory ===");
        $write("%0s", $system("cd")); // 输出工作目录路径
        $display("================================\n");

        file_read = $fopen("./data/data_Created.csv", "r");

        if (!file_read) begin
            $display("Error: Failed to open CSV file!");
            $finish;            
        end

        // while (($fscanf(file_read, "%c", temp)) && (temp != "\n")); // 跳过无效行或处理文件结束
        // Skip the first xxxxxx lines
        skip_lines = 8500;
        while (skip_lines > 0) begin
            if ($fgets(temp, file_read)) begin
                skip_lines = skip_lines - 1;
            end else begin
                $display("Error: File has less than 100 lines.");
                $finish;
            end
        end

        while (!$feof(file_read)) begin
            @(posedge sensorDataRefresh);
            if($fscanf(file_read, "%d,%f,%f,%f,%f,%f,%f,%f", file_line_number, file_time, file_A_phase_current, file_B_phase_current, file_C_phase_current, file_speed, file_Bus_voltage, file_Bus_current) == 8) begin
                $display("Time: %10.5f ms;\tLine: %06d; Data passed to verilog.", $realtime/1000000, file_line_number);              
            end else begin
                $display("Warning: Invalid line %d or file end, skipping...", file_line_number);
                while (($fscanf(file_read, "%c", temp)) && (temp != "\n")); // 跳过无效行或处理文件结束                
            end
        end

        $fclose(file_read);
        $display("Info: CSV file reading completed.");
        $finish;
    end



//------------------------------data output to txt file-----------------------------
    integer file_write;
    initial begin
        file_write = $fopen("./data/data_Output.txt", "w");
        if (!file_write) begin
            $display("Error: Failed to open txt file!");
            $finish;            
        end
        while (1) begin
            // @(posedge sensorDataRefresh);
            @(posedge data_out);
            @(posedge clk);
            $fdisplay(file_write, "%6d\t%10.1f\t%10.1f\t%10.1f\t%6.2f\t%8.0f\t%3d", file_line_number, $bitstoshortreal(Amp[0]), $bitstoshortreal(Amp[1]), $bitstoshortreal(Amp[2]), ($bitstoshortreal(Coff)*100), file_speed, clk_number_in_sensor_data);
        end
    end



//-----------------------------float data generation-----------------------------

    assign A = $shortrealtobits(file_A_phase_current);
    assign B = $shortrealtobits(file_B_phase_current);
    assign C = $shortrealtobits(file_C_phase_current);
    assign speed = $shortrealtobits(file_speed);
    assign Udc = $shortrealtobits(file_Bus_voltage);
    assign Idc = $shortrealtobits(file_Bus_current);

    







/*
// -------------------------------module DivideFloat----------------------------------

    real X, Y;
    reg divideFloatDataIn, divideFloatRstn, divideFloatCheckor;
    reg [31:0] divideFloatCmp;
    wire [31:0] divideFloatX, divideFloatY, divideFloatRes;
    wire divideFloatDataOut;

    assign divideFloatX = $shortrealtobits(X);
    assign divideFloatY = $shortrealtobits(Y);
    DivideFloat IDivideFloat(.clk(clk), .rstn(divideFloatRstn), .dataIn(divideFloatDataIn), .dend(divideFloatX), .dsor(divideFloatY), .dataOut(divideFloatDataOut), .quot(divideFloatRes));

    initial begin
        divideFloatDataIn = 0; divideFloatRstn = 0; divideFloatCheckor = 0; divideFloatCmp = 0;
        @(posedge clk); divideFloatRstn = 1;
        @(posedge clk); divideFloatRstn = 0;
        @(posedge clk); divideFloatRstn = 1;
        repeat(10) begin
            @(posedge sensorDataRefresh);
            @(posedge clk); divideFloatDataIn = 0;
            @(posedge clk); divideFloatDataIn = 1;
            divideFloatCmp = $shortrealtobits(X*Y);
            @(posedge divideFloatDataOut); @(posedge clk);
            // $display("addFloatRes = %h, addFloatCmp = %h", addFloatRes, addFloatCmp);
            divideFloatCheckor <= (divideFloatCmp == divideFloatRes);
        end
    end

    initial begin
        @(posedge sensorDataRefresh); X = 3.1415926; Y = 2.7182818;
        @(posedge sensorDataRefresh); X = 3.1415926; Y =-2.7182818;
        @(posedge sensorDataRefresh); X = 3.1415926; Y = 2.7182818;
        @(posedge sensorDataRefresh); X = 3.1415926; Y =-2.7182818;
        @(posedge sensorDataRefresh); X =-3.1415926; Y = 2.7182818;
        @(posedge sensorDataRefresh); X =-3.1415926; Y =-2.7182818;
        @(posedge sensorDataRefresh); X =-3.1415926; Y = 2.7182818;
        @(posedge sensorDataRefresh); X =-3.1415926; Y =-2.7182818;
        @(posedge sensorDataRefresh); $finish;
    end

// -------------------------------module DivideInt----------------------------------

    localparam widthDend = 16, widthDsor = 16;
    reg devideIntRstn, devideIntDataIn;
    reg signed [widthDend-1:0] devideIntDend;
    reg signed [widthDsor-1:0] devideIntDsor;
    wire devideIntDataOut;
    wire [widthDend-1:0] devideIntQuot;
    wire [widthDsor-1:0] devideIntRmdr;

    DivideInt #(.widthDend(widthDend), .widthDsor(widthDend)) IDivideInt(.clk(clk), .rstn(devideIntRstn), .dataIn(devideIntDataIn), .sign(1'b1), .dend(devideIntDend), .dsor(devideIntDsor), 
                    .dataOut(devideIntDataOut), .quot(devideIntQuot), .rmdr(devideIntRmdr));

    initial begin
        devideIntRstn = 0; devideIntDataIn = 0;
        devideIntDend  = 100; devideIntDsor = -20;    
        @(posedge clk); devideIntRstn = 1;
        @(posedge clk); devideIntRstn = 0;
        @(posedge clk); devideIntRstn = 1;
        repeat(10) begin
            @(posedge sensorDataRefresh);
            devideIntDend = devideIntDend + 1;
            devideIntDsor = devideIntDsor + 1;
            @(posedge clk); devideIntDataIn = 0;
            @(posedge clk); devideIntDataIn = 1;
            @(posedge devideIntDataOut);
        end
        $finish;
    end

/*
//-------------------------------module MultiplyFloat--------------------------------

    real X, Y;
    reg multiplyFloatDataIn, multiplyFloatRstn, multiplyFloatCheckor;
    reg [31:0] multiplyFloatCmp;
    wire [31:0] multiplyFloatX, multiplyFloatY, multiplyFloatRes;
    wire multiplyFloatDataOut;

    assign multiplyFloatX = $shortrealtobits(X);
    assign multiplyFloatY = $shortrealtobits(Y);
    MultiplyFloat IMultiplyFloat(.clk(clk), .rstn(multiplyFloatRstn), .dataIn(multiplyFloatDataIn), .x(multiplyFloatX), .y(multiplyFloatY), .dataOut(multiplyFloatDataOut), .prod(multiplyFloatRes));

    initial begin
        multiplyFloatDataIn = 0; multiplyFloatRstn = 0; multiplyFloatCheckor = 0; multiplyFloatCmp = 0;
        @(posedge clk); multiplyFloatRstn = 1;
        @(posedge clk); multiplyFloatRstn = 0;
        @(posedge clk); multiplyFloatRstn = 1;
        repeat(10) begin
            @(posedge sensorDataRefresh);
            @(posedge clk); multiplyFloatDataIn = 0;
            @(posedge clk); multiplyFloatDataIn = 1;
            multiplyFloatCmp = $shortrealtobits(X*Y);
            @(posedge multiplyFloatDataOut); @(posedge clk);
            // $display("addFloatRes = %h, addFloatCmp = %h", addFloatRes, addFloatCmp);
            multiplyFloatCheckor <= (multiplyFloatCmp == multiplyFloatRes);
        end
    end

    initial begin
        @(posedge sensorDataRefresh); X = 3.1415926; Y = 2.7182818;
        @(posedge sensorDataRefresh); X = 3.1415926; Y =-2.7182818;
        @(posedge sensorDataRefresh); X = 3.1415926; Y = 2.7182818;
        @(posedge sensorDataRefresh); X = 3.1415926; Y =-2.7182818;
        @(posedge sensorDataRefresh); X =-3.1415926; Y = 2.7182818;
        @(posedge sensorDataRefresh); X =-3.1415926; Y =-2.7182818;
        @(posedge sensorDataRefresh); X =-3.1415926; Y = 2.7182818;
        @(posedge sensorDataRefresh); X =-3.1415926; Y =-2.7182818;
        @(posedge sensorDataRefresh); $finish;
    end

//-------------------------------module MultiplyInt----------------------------------

    localparam widthMultiplyInt = 16;
    reg multiplyIntRstn, multiplyIntDataIn;
    reg signed [widthMultiplyInt-1:0] multiplyIntX, multiplyIntY;
    wire multiplyIntDataOut;
    wire [2*widthMultiplyInt-1:0] multiplyIntRes;

    MultiplyInt #(.width(widthMultiplyInt)) IMultiplyInt(.clk(clk), .rstn(multiplyIntRstn), .dataIn(multiplyIntDataIn), .sign(1'b1), .x(multiplyIntX), .y(multiplyIntY), 
                    .dataOut(multiplyIntDataOut), .prod(multiplyIntRes));

    initial begin
        multiplyIntRstn = 0; multiplyIntDataIn = 0;
        multiplyIntX  = 10; multiplyIntY = -10;    
        @(posedge clk); multiplyIntRstn = 1;
        @(posedge clk); multiplyIntRstn = 0;
        @(posedge clk); multiplyIntRstn = 1;
        repeat(10) begin
            @(posedge sensorDataRefresh);
            multiplyIntX = multiplyIntX + 1;
            multiplyIntY = multiplyIntY + 1;
            @(posedge clk); multiplyIntDataIn = 0;
            @(posedge clk); multiplyIntDataIn = 1;
            @(posedge multiplyIntDataOut);
        end
        $finish;
    end

/*
//-------------------------------module AddFloat----------------------------------------

    real X, Y;
    reg addFloatDataIn, addFloatRstn, addFloatCheckor, addFloatSub;
    reg [31:0] addFloatCmp;
    wire [31:0] addFloatX, addFloatY, addFloatRes;
    wire addFloatDataOut;

    assign addFloatX = $shortrealtobits(X);
    assign addFloatY = $shortrealtobits(Y);
    AddFloat IAddFloat(.clk(clk), .rstn(addFloatRstn), .sub(addFloatSub), .dataIn(addFloatDataIn), .x(addFloatX), .y(addFloatY), .dataOut(addFloatDataOut), .result(addFloatRes));

    initial begin
        addFloatDataIn = 0; addFloatRstn = 0; addFloatCheckor = 0; addFloatSub = 0; addFloatCmp = 0;
        @(posedge clk); addFloatRstn = 1;
        @(posedge clk); addFloatRstn = 0;
        @(posedge clk); addFloatRstn = 1;
        repeat(10) begin
            @(posedge sensorDataRefresh);
            @(posedge clk); addFloatDataIn = 0;
            @(posedge clk); addFloatDataIn = 1;
            addFloatCmp = $shortrealtobits(addFloatSub ? X-Y : X+Y);
            @(posedge addFloatDataOut); @(posedge clk);
            // $display("addFloatRes = %h, addFloatCmp = %h", addFloatRes, addFloatCmp);
            addFloatCheckor <= (addFloatCmp == addFloatRes);
        end
    end

    initial begin
        @(posedge sensorDataRefresh); X = 3.1415926; addFloatSub = 0; Y = 2.7182818;
        @(posedge sensorDataRefresh); X = 3.1415926; addFloatSub = 0; Y =-2.7182818;
        @(posedge sensorDataRefresh); X = 3.1415926; addFloatSub = 1; Y = 2.7182818;
        @(posedge sensorDataRefresh); X = 3.1415926; addFloatSub = 1; Y =-2.7182818;
        @(posedge sensorDataRefresh); X =-3.1415926; addFloatSub = 0; Y = 2.7182818;
        @(posedge sensorDataRefresh); X =-3.1415926; addFloatSub = 0; Y =-2.7182818;
        @(posedge sensorDataRefresh); X =-3.1415926; addFloatSub = 1; Y = 2.7182818;
        @(posedge sensorDataRefresh); X =-3.1415926; addFloatSub = 1; Y =-2.7182818;
        @(posedge sensorDataRefresh); $finish;
    end

/*
//-------------------------------module AddInt------------------------------------------

    localparam widthAdd = 8;
    reg addsub;
    reg [widthAdd-1:0] addx, addy;
    wire addcout, addoverflow;
    wire [widthAdd-1:0] addresult;
    AddInt #(widthAdd) IAddInt(.sub(addsub), .x(addx), .y(addy),
        .cout(addcout), .ovfl(addoverflow), .result(addresult));

    initial begin
        addx = 0; addsub = 0; addy = 0;
        @(posedge clk); addx = 10; addsub = 0; addy = 20;
        @(posedge clk); addx = 100; addsub = 0; addy = 200;
        @(posedge clk); addx = -100; addsub = 0; addy = 110;
        @(posedge clk); addx = -100; addsub = 0; addy = -50;
        @(posedge clk); addx = 100; addsub = 1; addy = 20;
        @(posedge clk); addx = 10; addsub = 1; addy = 20;
        @(posedge clk); addx = -100; addsub = 1; addy = 20;
        @(posedge clk); addx = -100; addsub = 1; addy = 50;
        @(posedge clk);
        $finish;
    end

/**/

endmodule //test
