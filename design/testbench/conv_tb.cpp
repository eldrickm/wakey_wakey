#include <stdio.h>      /* printf, scanf, puts, NULL */
#include <stdlib.h>     /* srand, rand */
#include "conv_gold.cpp"
#include "conv_gold_tiled.cpp"
#include "conv_tb_params.h"

template <int OY1, int OY0, int OX1, int OX0, int OC1, int OC0, int IC1, int IC0, int FX, int FY, int STRIDE>
void run_layer() {

    int16_t ifmap[(OY1*OY0-1)*STRIDE+FY][(OX1*OX0-1)*STRIDE+FX][IC1*IC0]; 
    int16_t weight[FY][FX][IC1*IC0][OC1*OC0]; 
    int32_t ofmap_gold[OY1*OY0][OX1*OX0][OC1*OC0];
    int32_t ofmap_tiled[OY1*OY0][OX1*OX0][OC1*OC0];

    printf("Generating ifmap\n");

    // Initialize input feature map
    for (int iy = 0; iy < (OY1*OY0-1)*STRIDE + FY; iy++) {
      for (int ix = 0; ix < (OX1*OX0-1)*STRIDE + FX; ix++) {
        for (int ic = 0; ic < IC1*IC0; ic++) {
          ifmap[iy][ix][ic] = rand() % 100; 
        }
      }
    }

    FILE * ifile;
    ifile = fopen ("ifmap_data.txt", "w");
    
    // Stream ifmap to the interface
    for (int oy1 = 0; oy1 < OY1; oy1++) {
      for (int ox1 = 0; ox1 < OX1; ox1++) {
        for (int ic1 = 0; ic1 < IC1; ic1++) {
          for (int iy0 = 0; iy0 < STRIDE*(OY0-1) + FY; iy0++) {
            for (int ix0 = 0; ix0 < STRIDE*(OX0-1) + FX; ix0++) {
              for (int ic0 = 0; ic0 < IC0; ic0++) {
                //printf("ifmap = %d\n", 
                //    ifmap[oy1*STRIDE*OY0+iy0][ox1*STRIDE*OX0+ix0][ic1*IC0+ic0]);
                fprintf(ifile, "%02x\n", 
                    ifmap[oy1*STRIDE*OY0+iy0][ox1*STRIDE*OX0+ix0][ic1*IC0+ic0]);
              }  // for ic0
            }  // for ix0
          }  // for iy0
        }  // for ic1
      }  // for ox1
    }  // for oy1
    
    fclose(ifile);
    
    printf("Generating weight\n");

    // Initialize weight
    for (int fy = 0; fy < FY; fy++) {  
      for (int fx = 0; fx < FX; fx++) {  
        for (int ic = 0; ic < IC1*IC0; ic++) {
          for (int oc = 0; oc < OC1*OC0; oc++) {
            weight[fy][fx][ic][oc] = rand() % 100;  
          }
        }  
      }
    }
    
    FILE * wfile;
    wfile = fopen ("weight_data.txt", "w");
    
    // Stream weight to the interface
    //for (int oy1 = 0; oy1 < OY1; oy1++) {
    //  for (int ox1 = 0; ox1 < OX1; ox1++) {     
        for(int oc1 = 0; oc1 < OC1; oc1++) {
          for (int ic1 = 0; ic1 < IC1; ic1++) {
            for (int fy = 0; fy < FY; fy++) {
              for (int fx = 0; fx < FX; fx++) {
                for (int ic0 = 0; ic0 < IC0; ic0++) {
                  for (int oc0 = 0; oc0 < OC0; oc0++) {
                    //printf("weight = %d\n", 
                    //    weight[fy][fx][ic1*IC0 + ic0][oc1*OC0 + oc0]);
                    fprintf(wfile, "%02x\n", 
                        weight[fy][fx][ic1*IC0 + ic0][oc1*OC0 + oc0]);
                  } // for oc0
                } // for ic0
              } // for fx
            } // for fy
          } // for ic1
        } // for oc1
      //} // for ox1
    //} // for oy1

    fclose(wfile);

    // Run reference model
    conv_gold<OY1*OY0, OX1*OX0, OC1*OC0, IC1*IC0, FX, FY, STRIDE>
      (ifmap, weight, ofmap_gold); 
    conv_gold_tiled<OY1, OY0, OX1, OX0, OC1, OC0, IC1, IC0, FX, FY, STRIDE>
      (ifmap, weight, ofmap_tiled);          
    int error = 0;
    printf("\nChecking output\n\n"); 
    for (int oy1 = 0; oy1 < OY1; oy1++) {
      for (int ox1 = 0; ox1 < OX1; ox1++) {
        for (int oc1 = 0; oc1 < OC1; oc1++) {
          for (int oy0 = 0; oy0 < OY0; oy0++) {
            for (int ox0 = 0; ox0 < OX0; ox0++) {
              for (int oc0 = 0; oc0 < OC0; oc0++) {
                if (ofmap_gold[oy1*OY0 + oy0][ox1*OX0 + ox0][oc1*OC0 + oc0] != 
                    ofmap_tiled[oy1*OY0 + oy0][ox1*OX0 + ox0][oc1*OC0 + oc0]) {
                  printf("***ERROR***\n");
		              error++;
                }
              } // for oc0
            } // for ox0
          } // for oy0
        } // for oc1
      } // for ox1
    } // for oy1


    printf("\nNumber of errors: %d\n\n",error); 

    FILE * ofile;
    ofile = fopen("ofmap_data.txt", "w");

    // Generate reference output stream from the interface   
    for (int oy1 = 0; oy1 < OY1; oy1++) {
      for (int ox1 = 0; ox1 < OX1; ox1++) {
        for (int oc1 = 0; oc1 < OC1; oc1++) {
          for (int oy0 = 0; oy0 < OY0; oy0++) { 
            for (int ox0 = 0; ox0 < OX0; ox0++) { 
              for (int oc0 = 0; oc0 < OC0; oc0++) {
                int oy = oy1*OY0 + oy0;
                int ox = ox1*OX0 + ox0;
                int oc = oc1*OC0 + oc0;
                //printf("output = %d\n", ofmap_tiled[oy][ox][oc]);
                fprintf(ofile, "%04x\n", ofmap_tiled[oy][ox][oc]);
              } // for oc0
            } // for ox0
          } // for oy0
        } // for oc1
      } // for ox1
    } // for oy1
 
    fclose(ofile);
}

int main(int argc, char *argv[]) 
{
  run_layer <OY1, OY0, OX1, OX0, OC1, OC0, IC1, IC0, FX,  FY, STRIDE> ();

  // Small layer
  //run_layer <4/*OY1*/, 3/*OY0*/, 4/*OX1*/, 3/*OX0*/, 4/*OC1*/, 4/*OC0*/, 2/*IC1*/, 4/*IC0*/, 3/*FX*/,  3/*FY*/, 1/*STRIDE*/> ();

  // ResNet conv1
  // printf("Layer 1\n");
  // run_layer <8/*OY1*/, 14/*OY0*/, 8/*OX1*/, 14/*OX0*/, 4/*OC1*/, 16/*OC0*/, 1/*IC1*/, 16/*IC0*/, 7/*FX*/,  7/*FY*/, 2/*STRIDE*/> ();

  // printf("Layer 2\n");
  // // ResNet conv2_x
  // run_layer <4/*OY1*/, 14/*OY0*/, 4/*OX1*/, 14/*OX0*/, 4/*OC1*/, 16/*OC0*/, 4/*IC1*/, 16/*IC0*/, 3/*FX*/,  3/*FY*/, 1/*STRIDE*/> ();

  // printf("Layer 3\n");
  // // ResNet conv3_x
  // run_layer <4/*OY1*/, 7/*OY0*/, 4/*OX1*/, 7/*OX0*/, 8/*OC1*/, 16/*OC0*/, 8/*IC1*/, 16/*IC0*/, 3/*FX*/,  3/*FY*/, 1/*STRIDE*/> ();

  // ResNet conv4_x
  //run_layer <2/*OY1*/, 7/*OY0*/, 2/*OX1*/, 7/*OX0*/, 16/*OC1*/, 16/*OC0*/, 16/*IC1*/, 16/*IC0*/, 3/*FX*/,  3/*FY*/, 1/*STRIDE*/> ();

  // ResNet conv5_x
  //run_layer <1/*OY1*/, 7/*OY0*/, 1/*OX1*/, 7/*OX0*/, 32/*OC1*/, 16/*OC0*/, 32/*IC1*/, 16/*IC0*/, 3/*FX*/,  3/*FY*/, 1/*STRIDE*/> ();

  // ResNet fc - **FAILS**
  //run_layer <1/*OY1*/, 1/*OY0*/, 1/*OX1*/, 1/*OX0*/, 64/*OC1*/, 16/*OC0*/, 32/*IC1*/, 16/*IC0*/, 1/*FX*/,  1/*FY*/, 1/*STRIDE*/> ();

  // ResNet conv1, but with stride 1
  //run_layer <8/*OY1*/, 14/*OY0*/, 8/*OX1*/, 14/*OX0*/, 4/*OC1*/, 16/*OC0*/, 1/*IC1*/, 16/*IC0*/, 7/*FX*/,  7/*FY*/, 1/*STRIDE*/> ();

  // ResNet conv3_1
  //run_layer <4/*OY1*/, 7/*OY0*/, 4/*OX1*/, 7/*OX0*/, 8/*OC1*/, 16/*OC0*/, 4/*IC1*/, 16/*IC0*/, 3/*FX*/,  3/*FY*/, 2/*STRIDE*/> ();

  // ResNet conv4_1
  // run_layer <2/*OY1*/, 7/*OY0*/, 2/*OX1*/, 7/*OX0*/, 16/*OC1*/, 16/*OC0*/, 8/*IC1*/, 16/*IC0*/, 3/*FX*/,  3/*FY*/, 2/*STRIDE*/> ();

  // ResNet conv5_1
  //run_layer <1/*OY1*/, 7/*OY0*/, 1/*OX1*/, 7/*OX0*/, 32/*OC1*/, 16/*OC0*/, 16/*IC1*/, 16/*IC0*/, 3/*FX*/,  3/*FY*/, 2/*STRIDE*/> ();

  return 0;
}
