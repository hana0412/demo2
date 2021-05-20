`default_nettype none

module ir_transmitter #(

    // Minimum number of clock cycles between tx_port transitions.
    // Must be greater than 0.
    // Set according to hardware bandwidth limitation.
    // Required_HW_bandwidth = clock_Frequency / BASE_DELAY / 2
    // E.g.:
    //   50 MHz / 10 / 2 = 2.5 MHz (can be used in simulation)
    //   50 MHz / 250 / 2 = 100 kHz (used on real hardware)
    parameter BASE_DELAY = 250
    //parameter BASE_DELAY = 10
)(

    input wire clock,
    input wire reset_n,
    
    input wire [31:0] tx_data,
    input wire tx_start,
    output reg tx_busy,

    output reg tx_port

);

    localparam 
        IDLE     = 2'b00,
        TX_WAIT0 = 2'b01,
        TX_WAIT1 = 2'b10,
        TX_STOP  = 2'b11;

    reg [1:0] state;
    
    reg [5:0] symbol_count;  // 6 bits to store values 0...63

    reg [$clog2(BASE_DELAY*3)-1:0] clock_count;  // enough bits to store values 0...(BASE_DELAY*3)-1

    always @ (posedge clock) begin
        if (~reset_n) begin
            state <= IDLE;
            clock_count <= 0;
            symbol_count <= 0;
            tx_port <= 0;
            tx_busy <= 0;
        end
        else begin
            case(state)
                IDLE: begin
                    if (tx_start) begin
                        symbol_count <= ~0;  // set to maximum value (63)
                        clock_count <= (BASE_DELAY * 2) - 1;
                        tx_busy <= 1;
                        tx_port <= 1;
                        state <= TX_WAIT0;
                    end 
                    else begin
                        tx_busy <= 0;
                        tx_port <= 0;
                    end
                end
                TX_WAIT0: begin
                    if (clock_count > 0) clock_count <= clock_count <= clock_count -1;
                    else begin
                        if (symbol_count > 31) clock_count <= (BASE_DELAY * 3) - 1;  // set delay for current symbol
                        else if (tx_data[symbol_count]) clock_count <= (BASE_DELAY * 3) - 1;
                        else clock_count <= (BASE_DELAY * 3) - 1;
                        tx_port <= 0;
                        state <= TX_WAIT1;
                    end
                end
                TX_WAIT1: begin
                    if (clock_count > 0) clock_count <= clock_count -1;
                    else begin
                        if (symbol_count > 0) begin
                            if ((symbol_count-1) > 31) clock_count <= (BASE_DELAY * 3) - 1;  // set delay for next symbol
                            else if (tx_data[symbol_count-1]) clock_count <= (BASE_DELAY * 3) - 1;
                            else clock_count <= (BASE_DELAY * 3) - 1;
                            symbol_count <= symbol_count -1;
                            tx_port <= 1;
                            state <= TX_WAIT0;
                        end
                        else begin
                            clock_count <= (BASE_DELAY * 3) - 1;  // stop pulse
                            tx_port <= 1;
                            state <= TX_STOP;
                        end
                    end
                end
                TX_STOP: begin
                    if (clock_count > 0) clock_count <= clock_count -1;
                    else begin
                        tx_port <= 0;
                        state <= IDLE;
                    end 
                end
                default: state <= IDLE;
            endcase
        end
    end

endmodule
 demo2
