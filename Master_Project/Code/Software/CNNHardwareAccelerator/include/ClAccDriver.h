
/***************************** Include Files *********************************/
#include "xaxidma.h"
#include "xparameters.h"
#include "xdebug.h"
#include <c++/4.8.3/vector>
#include <c++/4.8.3/algorithm>

#if (!defined(DEBUG))
extern void xil_printf(const char *format, ...);
#endif

/******************** Constant Definitions **********************************/

/*
 * Device hardware build related constants.
 */

#define DMA_DEV_ID		XPAR_AXIDMA_0_DEVICE_ID

#define MEM_BASE_ADDR		0x10000000

#define TX_BD_SPACE_BASE	(MEM_BASE_ADDR)
#define TX_BD_SPACE_HIGH	(MEM_BASE_ADDR + 0x00000FFF)
#define RX_BD_SPACE_BASE	(MEM_BASE_ADDR + 0x00001000)
#define RX_BD_SPACE_HIGH	(MEM_BASE_ADDR + 0x00001FFF)
#define TX_BUFFER_BASE		(MEM_BASE_ADDR + 0x00100000)
#define RX_BUFFER_BASE		(MEM_BASE_ADDR + 0x00300000)
#define RX_BUFFER_HIGH		(MEM_BASE_ADDR + 0x004FFFFF)

using vec_t = std::vector<float>;
using vec_it = std::vector<float>::iterator;

struct ConvLayerValues {
	const vec_t &image;
	const vec_t &weights;
	const int img_dim;
	const int kernel_dim;
	const float bias;
	const float avg_pool_coefficient;
	const float avg_pool_bias;
	const float scale_factor;
};

void ConfigureAndRunAccelerator(int nof_outputs);
void WriteDataToTxBuffer(ConvLayerValues clv);
int RxSetup(XAxiDma * AxiDmaInstPtr, const int recv_length);
int TxSetup(XAxiDma * AxiDmaInstPtr);
int SendPacket(XAxiDma * AxiDmaInstPtr, ConvLayerValues clv);
int GetDataFromRxBuffer(vec_it iterator, int data_size);
int WaitForTxToFinish(XAxiDma * AxiDmaInstPtr);
int WaitForRxToFinish(XAxiDma * AxiDmaInstPtr);
int CalculateClUsingHWAccelerator(const ConvLayerValues cl_vals, vec_it feature_map);
