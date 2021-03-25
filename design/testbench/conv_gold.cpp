#include <stdio.h>
#include <cassert>
#include <string.h>
#include <cstdint>

template <int OY, int OX, int OC, int IC, int FY, int FX, int STRIDE>
void conv_gold(int16_t ifmap[(OY-1)*STRIDE+FY][(OX-1)*STRIDE+FX][IC],
               int16_t weight[FY][FX][IC][OC],
               int32_t ofmap[OY][OX][OC]){

  // Implement the functionality of a convolutional layer, which convolves
  // ifmap with weight to produce ofmap. Your code should assign values to the
  // ofmap array. Make sure you take STRIDE into account.
 
  // Your code starts here
  OY: for (int oy = 0; oy < OY; oy++) {
    OX: for (int ox = 0; ox < OX; ox++) {
      OC: for (int oc = 0; oc < OC; oc++) {
        int32_t tmp=0;
        IC: for (int ic = 0; ic < IC; ic++) { 
          FX: for (int fx = 0; fx < FX; fx++) {
            FY: for (int fy = 0; fy < FY; fy++) {
              tmp += (int32_t) ifmap[STRIDE*oy+fy][STRIDE*ox+fx][ic] * 
                     (int32_t) weight[fy][fx][ic][oc];
            }
          }
        }
        ofmap[oy][ox][oc]= tmp;
      }
    }
  }
  // Your code ends here
}
