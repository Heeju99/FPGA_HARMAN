`timescale 1ns / 1ps

module sobel_filter_top (
    input  logic        clk,
    input  logic        reset,
    input  logic [11:0] g_filter_diff1,
    input  logic [11:0] g_filter_diff2,
    input  logic        DE,
    input  logic [ 9:0] x_pixel,
    input  logic [ 9:0] y_pixel,
    output logic [11:0] sobel_out1,
    output logic [11:0] sobel_out2
);

    sobel_filter U_sobel_filter1 (
        .clk(clk),
        .reset(reset),
        .g_filter_diff(g_filter_diff1),
        .DE(DE),
        .x_pixel(x_pixel),
        .y_pixel(y_pixel),
        .sobel_out(sobel_out1)
    );

    sobel_filter U_sobel_filter2 (
        .clk(clk),
        .reset(reset),
        .g_filter_diff(g_filter_diff2),
        .DE(DE),
        .x_pixel(x_pixel),
        .y_pixel(y_pixel),
        .sobel_out(sobel_out2)
    );

endmodule


module sobel_filter (
    input logic clk,
    input logic reset,
    //input gray
    input logic [11:0] g_filter_diff,
    // input logic [3:0] g_filter_red,
    // input logic [3:0] g_filter_green,
    // input logic [3:0] g_filter_blue,

    input logic       DE,
    input logic [9:0] x_pixel,
    input logic [9:0] y_pixel,

    // output logic [3:0] s_filter_red, 
    // output logic [3:0] s_filter_green, 
    // output logic [3:0] s_filter_blue
    output logic [11:0] sobel_out

);
    localparam IMG_WIDTH = 640;
    localparam THRESHOLD = 8;

    //additional
    // logic [11:0] sobel_out;
    logic [11:0] gray_in = g_filter_diff;

    logic [3:0] line_buffer_1[0:IMG_WIDTH-1];
    logic [3:0] line_buffer_2[0:IMG_WIDTH-1];

    logic [3:0] p11, p12, p13;
    logic [3:0] p21, p22, p23;
    logic [3:0] p31, p32, p33;

    logic [2:0] valid_pipeline;
    logic display_en;

    logic signed [10:0] gx, gy;
    logic [10:0] mag;

    integer i;

    // assign display_en = (x_pixel < 320) && (120 < y_pixel) && (y_pixel < 360);

    // assign s_filter_red = sobel_out[3:0];      //((mag_sobel_0[12:5] > threshold) && sobel_en) ? 4'hF : 4'h0;
    // assign s_filter_blue = sobel_out[3:0];     //((mag_sobel_1[12:5] > threshold) && sobel_en) ? 4'hF : 4'h0;
    // assign s_filter_green = sobel_out[3:0];    //((mag_sobel_2[12:5] > threshold) && sobel_en) ? 4'hF : 4'h0;


    always @(posedge clk) begin
        if (reset) begin
            for (i = 0; i < IMG_WIDTH; i = i + 1) begin
                line_buffer_1[i] <= 0;
                line_buffer_2[i] <= 0;
            end
        end else if (DE) begin
            line_buffer_2[x_pixel] <= line_buffer_1[x_pixel];
            line_buffer_1[x_pixel] <= gray_in[3:0];
        end
    end

    always @(posedge clk) begin
        if (reset) begin
            {p11, p12, p13, p21, p22, p23, p31, p32, p33} <= 0;
            valid_pipeline <= 0;
        end else if (DE) begin
            p13 <= line_buffer_2[x_pixel];
            p12 <= p13;
            p11 <= p12;

            p23 <= line_buffer_1[x_pixel];
            p22 <= p23;
            p21 <= p22;

            p33 <= gray_in[3:0];
            p32 <= p33;
            p31 <= p32;

            valid_pipeline <= {
                valid_pipeline[1:0], (x_pixel >= 2 && y_pixel >= 2)
            };
        end else begin
            valid_pipeline <= {valid_pipeline[1:0], 1'b0};
        end
    end

    always @(posedge clk) begin
        if (reset) begin
            gx        <= 0;
            gy        <= 0;
            mag       <= 0;
            sobel_out <= 0;
        end else if (valid_pipeline[2]) begin
            gx <= (p13 + (p23 << 1) + p33) - (p11 + (p21 << 1) + p31);
            gy <= (p31 + (p32 << 1) + p33) - (p11 + (p12 << 1) + p13);
            mag <= (gx[10] ? -gx : gx) + (gy[10] ? -gy : gy);
            if((x_pixel < 320 - 2) && (120 < y_pixel) && (y_pixel < 360)) begin
                sobel_out <= (mag > THRESHOLD) ? 12'hFFF : 12'h0;
            end else begin
                sobel_out <= 0;
            end
        end else begin
            sobel_out <= 0;
        end
    end

endmodule
