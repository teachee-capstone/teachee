`default_nettype none

`include "vunit_defines.svh"

// Verifies an AND gate as an example of issuing test cases through VUnit.
module vunit_example_tb;

    var logic clk;

    // inputs to the AND gate
    var logic x1;
    var logic x2;

    // output of the AND gate
    var logic y;

    // In a normal case we would instance the DUT but this is an example
    // So the AND gate will be done with a simple assign statement
    assign y = x1 & x2;

    always begin
        #10
        clk <= !clk;
    end

    // Begin the Test suite run
    `TEST_SUITE begin
        `TEST_SUITE_SETUP begin
            // what would normally go in an initial block we can put here
            clk = 0;
            x1 = 0;
            x2 = 0;
        end

        `TEST_CASE("x1_0_x2_0") begin
            x1 = 0;
            x2 = 0;
            @(posedge clk) `CHECK_EQUAL(y, 0);
        end

        `TEST_CASE("x1_1_x2_0") begin
            x1 = 1;
            x2 = 0;
            @(posedge clk) `CHECK_EQUAL(y, 0);
        end

        `TEST_CASE("x1_0_x2_1") begin
            x1 = 0;
            x2 = 1;
            @(posedge clk) `CHECK_EQUAL(y, 0);
        end

        `TEST_CASE("x1_1_x2_1") begin
            x1 = 1;
            x2 = 1;
            @(posedge clk) `CHECK_EQUAL(y, 1);
        end
    end

    `WATCHDOG(0.1ms);
endmodule

`default_nettype wire