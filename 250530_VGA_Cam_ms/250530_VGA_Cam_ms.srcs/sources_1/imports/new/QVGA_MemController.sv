`timescale 1ns / 1ps

module QVGA_MemController (
    input logic sw_up,
    // VGA Controller side
    input  logic        clk,
    input  logic [ 9:0] x_pixel,
    input  logic [ 9:0] y_pixel,
    input  logic        DE,
    // frame buffer side
    output logic        rclk,
    output logic        d_en,
    output logic [16:0] rAddr,
    input  logic [15:0] rData,
    // export side
    output logic [ 3:0] red_port,
    output logic [ 3:0] green_port,
    output logic [ 3:0] blue_port
);
    logic display_en;
    assign rclk = clk;

    //assign display_en = (x_pixel < 320 && y_pixel < 240);
    assign d_en = display_en;

    //assign rAddr = display_en ? (y_pixel * 320 + x_pixel) : 0;

    assign {red_port, green_port, blue_port} = display_en ? {rData[15:12], rData[10:7], rData[4:1]} : 12'b0; // RGB565 -> RGB444

    always_comb begin
        if(sw_up) begin
            display_en = (x_pixel < 640 && y_pixel < 480);
            rAddr = display_en ? (320 * (y_pixel/2) + (x_pixel/2)) : 0;
        end else begin
            display_en = (x_pixel < 320 && y_pixel < 240);
            rAddr = display_en ? (y_pixel * 320 + x_pixel) : 0;
        end
    end
endmodule
