module washing_machine (
    input clk,
    input reset,
    input start_stop,
    input cycle_select,
    input door_open,
    output reg [1:0] led_cycle,
    output reg [2:0] led_state,
    output reg door_lock,
    output reg buzzer,
    output reg [3:0] timer_display
);

    // State encoding
    localparam IDLE    = 3'b000;
    localparam FILL    = 3'b001;
    localparam WASH    = 3'b010;
    localparam DRAIN   = 3'b011;
    localparam RINSE   = 3'b100;
    localparam SPIN    = 3'b101;
    localparam PAUSED  = 3'b110;
    localparam COMPLETE= 3'b111;

    reg [2:0] current_state, next_state;

    // Cycle encoding
    localparam DELICATE = 2'b00;
    localparam NORMAL   = 2'b01;
    localparam HEAVY    = 2'b10;

    reg [1:0] selected_cycle;

    // Timers
    reg [5:0] timer;
    reg [5:0] fill_time, wash_time, drain_time, rinse_time, spin_time;

    // Update cycle parameters
    always @(*) begin
        case (selected_cycle)
            DELICATE: {fill_time, wash_time, drain_time, rinse_time, spin_time} = {6'd5, 6'd10, 6'd3, 6'd5, 6'd8};
            NORMAL:   {fill_time, wash_time, drain_time, rinse_time, spin_time} = {6'd7, 6'd15, 6'd5, 6'd7, 6'd12};
            HEAVY:    {fill_time, wash_time, drain_time, rinse_time, spin_time} = {6'd8, 6'd20, 6'd7, 6'd10, 6'd15};
            default:  {fill_time, wash_time, drain_time, rinse_time, spin_time} = {6'd5, 6'd10, 6'd3, 6'd5, 6'd8};
        endcase
    end

    // Reset timer on state change
    reg state_changed;
    always @(posedge clk) begin
        state_changed <= (current_state != next_state);
    end

    // State transition and timer logic
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            current_state <= IDLE;
            timer <= 0;
            selected_cycle <= DELICATE;
        end else begin
            current_state <= next_state;
            if (state_changed) begin
                timer <= 0;  // Reset timer on state change
            end else begin
                case (current_state)
                    FILL:  timer <= (timer < fill_time-1) ? timer + 1 : timer;
                    WASH:  timer <= (timer < wash_time-1) ? timer + 1 : timer;
                    DRAIN: timer <= (timer < drain_time-1) ? timer + 1 : timer;
                    RINSE: timer <= (timer < rinse_time-1) ? timer + 1 : timer;
                    SPIN:  timer <= (timer < spin_time-1) ? timer + 1 : timer;
                    default: timer <= 0;
                endcase
            end
        end
    end

    // LED state output
    always @(*) begin
        case (current_state)
            IDLE:     led_state = IDLE;
            FILL:     led_state = FILL;
            WASH:     led_state = WASH;
            DRAIN:    led_state = DRAIN;
            RINSE:    led_state = RINSE;
            SPIN:     led_state = SPIN;
            PAUSED:   led_state = PAUSED;
            COMPLETE: led_state = COMPLETE;
            default:  led_state = IDLE;
        endcase
    end

    // Cycle selection logic
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            selected_cycle <= DELICATE;
        end else if (current_state == IDLE && cycle_select) begin
            case (selected_cycle)
                DELICATE: selected_cycle <= NORMAL;
                NORMAL:   selected_cycle <= HEAVY;
                HEAVY:    selected_cycle <= DELICATE;
                default:  selected_cycle <= DELICATE;
            endcase
        end
    end

    // LED cycle output
    always @(*) begin
        led_cycle = selected_cycle;
    end

    // Output control logic
    always @(*) begin
        // Default assignments
        next_state = current_state;
        door_lock = (current_state != IDLE && current_state != COMPLETE && current_state != PAUSED);
        buzzer = (current_state == PAUSED || current_state == COMPLETE);
        timer_display = timer;
        
        case (current_state)
            IDLE: begin
                if (start_stop && !door_open) next_state = FILL;
            end
            FILL: begin
                if (door_open) next_state = PAUSED;
                else if (timer >= fill_time-1) next_state = WASH;
            end
            WASH: begin
                if (door_open) next_state = PAUSED;
                else if (timer >= wash_time-1) next_state = DRAIN;
            end
            DRAIN: begin
                if (door_open) next_state = PAUSED;
                else if (timer >= drain_time-1) next_state = RINSE;
            end
            RINSE: begin
                if (door_open) next_state = PAUSED;
                else if (timer >= rinse_time-1) next_state = SPIN;
            end
            SPIN: begin
                if (door_open) next_state = PAUSED;
                else if (timer >= spin_time-1) next_state = COMPLETE;
            end
            PAUSED: begin
                if (!door_open && start_stop) next_state = current_state;
            end
            COMPLETE: begin
                if (start_stop) next_state = IDLE;
            end
        endcase
    end

endmodule