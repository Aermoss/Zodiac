/*
 * Copyright 2026 Yusuf Rençber
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

module uart(
    input logic clk,
    input logic [3:0] we,
    input logic [31:0] write
);

always_ff @(posedge clk) begin
    if (we[0]) $write("%c", write[7:0]);
    if (we[1]) $write("%c", write[15:8]);
    if (we[2]) $write("%c", write[23:16]);
    if (we[3]) $write("%c", write[31:24]);
end

endmodule
