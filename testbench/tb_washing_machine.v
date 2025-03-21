`timescale 1ns/1ps

module tb_washing_machine;
    // State definitions for readability 
    localparam IDLE     = 3'b000;
    localparam FILL     = 3'b001;
    localparam WASH     = 3'b010;
    localparam DRAIN    = 3'b011;
    localparam RINSE    = 3'b100;
    localparam SPIN     = 3'b101;
    localparam PAUSED   = 3'b110;
    localparam COMPLETE = 3'b111;

    // Cycle timing constants
    localparam FILL_TIME  = 4'd5;
    localparam WASH_TIME  = 4'd10;
    localparam DRAIN_TIME = 4'd3;
    localparam RINSE_TIME = 4'd5;
    localparam SPIN_TIME  = 4'd8;

    // Test signals
    reg clk;
    reg reset;
    reg start_stop;
    reg cycle_select;
    reg door_open;

    // DUT outputs
    wire [1:0] led_cycle;
    wire [2:0] led_state;
    wire door_lock;
    wire buzzer;
    wire [3:0] timer_display;

    // Previous state storage
    reg [2:0] prev_state;
    reg [1:0] prev_cycle;
    reg prev_door_lock;
    reg prev_buzzer; 
    reg [3:0] prev_timer;

    // For verification
    integer error_count = 0;

    // Task to check timer values with state name as parametery
    task check_timer;
        input [3:0] expected;
        input [64*8-1:0] state_name;  // 64 character string as bits
        begin
            if(timer_display !== expected) begin
                $display("ERROR: %s timer mismatch - Expected: %0d, Got: %0d at time %0t",
                    state_name, expected, timer_display, $time);
                error_count = error_count + 1;
            end
        end
    endtask

    // Task to print state transitions
    task print_state;
        input [2:0] state;
        begin
            case(state)
                IDLE:     $write("IDLE    ");
                FILL:     $write("FILL    ");
                WASH:     $write("WASH    ");
                DRAIN:    $write("DRAIN   ");
                RINSE:    $write("RINSE   ");
                SPIN:     $write("SPIN    ");
                PAUSED:   $write("PAUSED  ");
                COMPLETE: $write("COMPLETE");
                default:  $write("UNKNOWN ");
            endcase
        end
    endtask

    // Create a task for state transition verification
    task wait_for_state;
        input [2:0] expected_state;
        input [31:0] timeout;  // Timeout in ns
        begin : wait_state    // Add the block label here
            repeat(timeout) @(posedge clk)
            if (led_state == expected_state) begin
                disable wait_state;
            end
        end
    endtask

    // Instantiate washing machine
    washing_machine uut (
        .clk(clk),
        .reset(reset),
        .start_stop(start_stop),
        .cycle_select(cycle_select),
        .door_open(door_open),
        .led_cycle(led_cycle),
        .led_state(led_state),
        .door_lock(door_lock),
        .buzzer(buzzer),
        .timer_display(timer_display)
    );

    // Clock generation
    always #10 clk = ~clk;

    // Monitor state changes with decoded state names
    always @(posedge clk) begin
        if (led_state != prev_state || led_cycle != prev_cycle || 
            door_lock != prev_door_lock || buzzer != prev_buzzer ||
            timer_display != prev_timer) begin
            
            $write("Time: %0t ns | State: ", $time);
            print_state(led_state);
            $display(" | Cycle: %b | Timer: %d | Door Lock: %b | Buzzer: %b",
                led_cycle, timer_display, door_lock, buzzer);
            
            // Update previous values
            prev_state <= led_state;
            prev_cycle <= led_cycle;
            prev_door_lock <= door_lock;
            prev_buzzer <= buzzer;
            prev_timer <= timer_display;
        end
    end

    // Add timeout watchdog
    initial begin
        #10000000; // 10ms timeout
        $display("ERROR: Simulation timeout - possible infinite loop");
        $finish;
    end

    // Test procedure
    initial begin
        // Initialize and setup
        $dumpfile("waves.vcd");
        $dumpvars(0, tb_washing_machine);

        // Initialize all inputs with known states
        clk = 0;
        reset = 0;
        start_stop = 0;
        cycle_select = 0;
        door_open = 0;
        prev_state = 0;
        prev_cycle = 0;
        prev_door_lock = 0;
        prev_buzzer = 0;
        prev_timer = 0;

        // Reset sequence
        #100 reset = 1;
        #100 reset = 0;
        $display("\n=== System Reset Complete at %0t ns ===", $time);

        // Test 1: Normal delicate cycle with longer timeouts
        $display("\n=== Test 1: Normal Delicate Cycle at %0t ns ===", $time);
        cycle_select = 0;  // Ensure DELICATE cycle
        #100 start_stop = 1;
        #100 start_stop = 0;
        wait_for_state(FILL, 1000);    // Increased timeout
        wait_for_state(WASH, 1000);    // Increased timeout
        wait_for_state(DRAIN, 1000);   // Increased timeout
        wait_for_state(RINSE, 1000);   // Increased timeout
        wait_for_state(SPIN, 1000);    // Increased timeout
        wait_for_state(COMPLETE, 1000); // Increased timeout

        // Test 2: Door open during operation
        $display("\n=== Test 2: Door Open During Wash at %0t ns ===", $time);
        #20 start_stop = 1;
        #20 start_stop = 0;
        wait_for_state(FILL, 200);
        #100;  // Wait for WASH state
        door_open = 1;
        wait_for_state(PAUSED, 100);
        #20 door_open = 0;
        #20 start_stop = 1;
        #20 start_stop = 0;
        wait_for_state(WASH, 200);

        // Test 3: Cycle selection
        $display("\n=== Test 3: Cycle Selection at %0t ns ===", $time);
        #20 reset = 1;    // Reset to known state
        #20 reset = 0;
        wait_for_state(IDLE, 100);
        
        #20 cycle_select = 1;
        #20 cycle_select = 0;
        #20;  // Wait for cycle to update
        if (led_cycle !== 2'b01) begin
            $display("ERROR: Failed to switch to NORMAL cycle");
            error_count = error_count + 1;
        end
        
        #20 cycle_select = 1;
        #20 cycle_select = 0;
        #20;  // Wait for cycle to update
        if (led_cycle !== 2'b10) begin
            $display("ERROR: Failed to switch to HEAVY cycle");
            error_count = error_count + 1;
        end

        // Test 4: Reset during operation
        reset = 1;
        #40 reset = 0;
        wait_for_state(IDLE, 500);

        // Display final results
        #200;
        $display("\n=== Test Summary ===");
        $display("Total Errors: %0d", error_count);
        $display("Total Time: %0t ns", $time);
        $finish;
    end

endmodule