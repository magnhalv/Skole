#include "../include/ClAccDriver.h"
#include <c++/4.8.3/bitset>
#include <c++/4.8.3/iostream>



/************************** Variable Definitions *****************************/
/*
 * Device instance definitions
 */
XAxiDma AxiDma;

/*
 * Buffer for transmit packet. Must be 32-bit aligned to be used by DMA.
 */
int *Packet = (int *) TX_BUFFER_BASE;

int FloatToFixed(float n) {
	float temp = n*65536;
	int fixed = (int)temp;
	return fixed;
}

float FixedToFloat(float n) {
	float new_num;
	char *num = (char*)&n;
	char *reverse_num = (char*)&new_num;
	reverse_num[0] = num[3];
	reverse_num[1] = num[2];
	reverse_num[2] = num[1];
	reverse_num[3] = num[0];
	return n;
}

void WriteDataToTxBuffer(ConvLayerValues clv) {

	std::vector<int> weights_temp(clv.weights.size());
	std::transform(clv.weights.begin(), clv.weights.end(), weights_temp.begin(), FloatToFixed);

	int *Buffer = (int*)TX_BUFFER_BASE;
	Buffer[0] = FloatToFixed(clv.scale_factor);
	Buffer[1] = FloatToFixed(clv.avg_pool_bias);
	Buffer[2] = FloatToFixed(clv.avg_pool_coefficient);
	Buffer[3] = FloatToFixed(clv.bias);

	std::reverse_copy(weights_temp.begin(), weights_temp.end(), &Buffer[4]);
	std::transform(clv.image.begin(), clv.image.end(), &Buffer[4+clv.weights.size()], FloatToFixed);
}

int CalculateClUsingHWAccelerator(const ConvLayerValues cl_vals, vec_it feature_map)
{
	int Status;
	XAxiDma_Config *Config;
	const int img_dim = cl_vals.img_dim;
	const int kernel_dim = cl_vals.kernel_dim;
	u32 nof_outputs = ((img_dim-kernel_dim+1)/2)*((img_dim-kernel_dim+1)/2);

	Config = XAxiDma_LookupConfig(DMA_DEV_ID);
	if (!Config) {
		xil_printf("No config found for %d\r\n", DMA_DEV_ID);

		return XST_FAILURE;
	}

	/* Initialize DMA engine */
	Status = XAxiDma_CfgInitialize(&AxiDma, Config);
	if (Status != XST_SUCCESS) {
		xil_printf("Initialization failed %d\r\n", Status);
		return XST_FAILURE;
	}

	if(!XAxiDma_HasSg(&AxiDma)) {
		xil_printf("Device configured as Simple mode \r\n");

		return XST_FAILURE;
	}

	Status = TxSetup(&AxiDma);
	if (Status != XST_SUCCESS) {
		return XST_FAILURE;
	}


	Status = RxSetup(&AxiDma, nof_outputs);
	if (Status != XST_SUCCESS) {
		return XST_FAILURE;
	}

	/* Send a packet */
	Status = SendPacket(&AxiDma, cl_vals);
	if (Status != XST_SUCCESS) {
		return XST_FAILURE;
	}

	Status = WaitForTxToFinish(&AxiDma);
	if (Status != XST_SUCCESS) {
		return XST_FAILURE;
	}
	ConfigureAndRunAccelerator(nof_outputs);

	Status = WaitForRxToFinish(&AxiDma);
	if (Status != XST_SUCCESS) {
		return XST_FAILURE;
	}

	Status = GetDataFromRxBuffer(feature_map, nof_outputs);
	if (Status != XST_SUCCESS) {
		return XST_FAILURE;
	}

	return XST_SUCCESS;
}

/*****************************************************************************/
/**
*
* This function sets up RX channel of the DMA engine to be ready for packet
* reception
*
* @param	AxiDmaInstPtr is the pointer to the instance of the DMA engine.
*
* @return	XST_SUCCESS if the setup is successful, XST_FAILURE otherwise.
*
* @note		None.
*
******************************************************************************/
int RxSetup(XAxiDma * AxiDmaInstPtr, const int recv_length)
{
	XAxiDma_BdRing *RxRingPtr;
	int Delay = 0;
	int Coalesce = 1;
	int Status;
	XAxiDma_Bd BdTemplate;
	XAxiDma_Bd *BdPtr;
	XAxiDma_Bd *BdCurPtr;
	u32 BdCount;
	u32 FreeBdCount;
	u32 RxBufferPtr;
	int Index;
	const int MAX_RECV_LEN = recv_length*4;

	RxRingPtr = XAxiDma_GetRxRing(&AxiDma);

	/* Disable all RX interrupts before RxBD space setup */

	XAxiDma_BdRingIntDisable(RxRingPtr, XAXIDMA_IRQ_ALL_MASK);

	/* Set delay and coalescing */
	XAxiDma_BdRingSetCoalesce(RxRingPtr, Coalesce, Delay);

	/* Setup Rx BD space */
	BdCount = XAxiDma_BdRingCntCalc(XAXIDMA_BD_MINIMUM_ALIGNMENT,
				RX_BD_SPACE_HIGH - RX_BD_SPACE_BASE + 1);

	Status = XAxiDma_BdRingCreate(RxRingPtr, RX_BD_SPACE_BASE,
				RX_BD_SPACE_BASE,
				XAXIDMA_BD_MINIMUM_ALIGNMENT, BdCount);

	if (Status != XST_SUCCESS) {
		xil_printf("RX create BD ring failed %d\r\n", Status);

		return XST_FAILURE;
	}

	/*
	 * Setup an all-zero BD as the template for the Rx channel.
	 */
	XAxiDma_BdClear(&BdTemplate);

	Status = XAxiDma_BdRingClone(RxRingPtr, &BdTemplate);
	if (Status != XST_SUCCESS) {
		xil_printf("RX clone BD failed %d\r\n", Status);

		return XST_FAILURE;
	}

	/* Attach buffers to RxBD ring so we are ready to receive packets */

	FreeBdCount = XAxiDma_BdRingGetFreeCnt(RxRingPtr);
	u32 NofBds = 2;
	Status = XAxiDma_BdRingAlloc(RxRingPtr, NofBds, &BdPtr);
	if (Status != XST_SUCCESS) {
		xil_printf("RX alloc BD failed %d\r\n", Status);

		return XST_FAILURE;
	}

	BdCurPtr = BdPtr;
	RxBufferPtr = RX_BUFFER_BASE;
	for (Index = 0; Index < NofBds; Index++) {
		Status = XAxiDma_BdSetBufAddr(BdCurPtr, RxBufferPtr);

		if (Status != XST_SUCCESS) {
			xil_printf("Set buffer addr %x on BD %x failed %d\r\n",
			    (unsigned int)RxBufferPtr,
			    (unsigned int)BdCurPtr, Status);

			return XST_FAILURE;
		}

		Status = XAxiDma_BdSetLength(BdCurPtr, MAX_RECV_LEN,
				RxRingPtr->MaxTransferLen);
		if (Status != XST_SUCCESS) {
			xil_printf("Rx set length %d on BD %x failed %d\r\n",
			    MAX_RECV_LEN, (unsigned int)BdCurPtr, Status);

			return XST_FAILURE;
		}

		/* Receive BDs do not need to set anything for the control
		 * The hardware will set the SOF/EOF bits per stream status
		 */
		XAxiDma_BdSetCtrl(BdCurPtr, 0);
		XAxiDma_BdSetId(BdCurPtr, RxBufferPtr);

		RxBufferPtr += MAX_RECV_LEN;
		BdCurPtr = XAxiDma_BdRingNext(RxRingPtr, BdCurPtr);
	}
	/* Clear the receive buffer, so we can verify data
	 */
	memset((void *)RX_BUFFER_BASE, 0, MAX_RECV_LEN);

	Status = XAxiDma_BdRingToHw(RxRingPtr, NofBds,
						BdPtr);
	if (Status != XST_SUCCESS) {
		xil_printf("RX submit hw failed %d\r\n", Status);

		return XST_FAILURE;
	}

	/* Start RX DMA channel */
	Status = XAxiDma_BdRingStart(RxRingPtr);
	if (Status != XST_SUCCESS) {
		xil_printf("RX start hw failed %d\r\n", Status);

		return XST_FAILURE;
	}

	return XST_SUCCESS;
}

/*****************************************************************************/
/**
*
* This function sets up the TX channel of a DMA engine to be ready for packet
* transmission
*
* @param	AxiDmaInstPtr is the instance pointer to the DMA engine.
*
* @return	XST_SUCCESS if the setup is successful, XST_FAILURE otherwise.
*
* @note		None.
*
******************************************************************************/
int TxSetup(XAxiDma * AxiDmaInstPtr)
{
	XAxiDma_BdRing *TxRingPtr;
	XAxiDma_Bd BdTemplate;
	int Delay = 0;
	int Coalesce = 1;
	int Status;
	u32 BdCount;

	TxRingPtr = XAxiDma_GetTxRing(&AxiDma);

	/* Disable all TX interrupts before TxBD space setup */

	XAxiDma_BdRingIntDisable(TxRingPtr, XAXIDMA_IRQ_ALL_MASK);

	/* Set TX delay and coalesce */
	XAxiDma_BdRingSetCoalesce(TxRingPtr, Coalesce, Delay);

	/* Setup TxBD space  */
	BdCount = XAxiDma_BdRingCntCalc(XAXIDMA_BD_MINIMUM_ALIGNMENT,
				TX_BD_SPACE_HIGH - TX_BD_SPACE_BASE + 1);

	Status = XAxiDma_BdRingCreate(TxRingPtr, TX_BD_SPACE_BASE,
				TX_BD_SPACE_BASE,
				XAXIDMA_BD_MINIMUM_ALIGNMENT, BdCount);
	if (Status != XST_SUCCESS) {
		xil_printf("failed create BD ring in txsetup\r\n");

		return XST_FAILURE;
	}

	/*
	 * We create an all-zero BD as the template.
	 */
	XAxiDma_BdClear(&BdTemplate);

	Status = XAxiDma_BdRingClone(TxRingPtr, &BdTemplate);
	if (Status != XST_SUCCESS) {
		xil_printf("failed bdring clone in txsetup %d\r\n", Status);

		return XST_FAILURE;
	}

	/* Start the TX channel */
	Status = XAxiDma_BdRingStart(TxRingPtr);
	if (Status != XST_SUCCESS) {
		xil_printf("failed start bdring txsetup %d\r\n", Status);

		return XST_FAILURE;
	}

	return XST_SUCCESS;
}

/*****************************************************************************/
/**
*
* This function transmits one packet non-blockingly through the DMA engine.
*
* @param	AxiDmaInstPtr points to the DMA engine instance
*
* @return	- XST_SUCCESS if the DMA accepts the packet successfully,
*		- XST_FAILURE otherwise.
*
* @note     None.
*
******************************************************************************/
int SendPacket(XAxiDma * AxiDmaInstPtr, ConvLayerValues clv)
{
	XAxiDma_BdRing *TxRingPtr;
	int *TxPacket;
	XAxiDma_Bd *BdPtr;
	int Status;
	int Index;
	const int MAX_PKT_LEN = (clv.image.size()+clv.weights.size()+2)*sizeof(int);

	TxRingPtr = XAxiDma_GetTxRing(AxiDmaInstPtr);

	WriteDataToTxBuffer(clv);
	/* Create pattern in the packet to transmit */
	TxPacket = (int *) Packet;

	/* Flush the SrcBuffer before the DMA transfer, in case the Data Cache
	 * is enabled
	 */
	Xil_DCacheFlushRange((u32)TxPacket, MAX_PKT_LEN+32);


	/* Allocate a BD */
	Status = XAxiDma_BdRingAlloc(TxRingPtr, 1, &BdPtr);
	if (Status != XST_SUCCESS) {
		return XST_FAILURE;
	}

	/* Set up the BD using the information of the packet to transmit */
	Status = XAxiDma_BdSetBufAddr(BdPtr, (u32) TxPacket);
	if (Status != XST_SUCCESS) {
		xil_printf("Tx set buffer addr %x on BD %x failed %d\r\n",
		    (unsigned int)Packet, (unsigned int)BdPtr, Status);

		return XST_FAILURE;
	}

	Status = XAxiDma_BdSetLength(BdPtr, MAX_PKT_LEN,
				TxRingPtr->MaxTransferLen);
	if (Status != XST_SUCCESS) {
		xil_printf("Tx set length %d on BD %x failed %d\r\n",
		    MAX_PKT_LEN, (unsigned int)BdPtr, Status);

		return XST_FAILURE;
	}

#if (XPAR_AXIDMA_0_SG_INCLUDE_STSCNTRL_STRM == 1)
	Status = XAxiDma_BdSetAppWord(BdPtr,
	    XAXIDMA_LAST_APPWORD, MAX_PKT_LEN);

	/* If Set app length failed, it is not fatal
	 */
	if (Status != XST_SUCCESS) {
		xil_printf("Set app word failed with %d\r\n", Status);
	}
#endif

	/* For single packet, both SOF and EOF are to be set
	 */
	XAxiDma_BdSetCtrl(BdPtr, XAXIDMA_BD_CTRL_TXEOF_MASK |
						XAXIDMA_BD_CTRL_TXSOF_MASK);

	XAxiDma_BdSetId(BdPtr, (u32) TxPacket);

	/* Give the BD to DMA to kick off the transmission. */
	Status = XAxiDma_BdRingToHw(TxRingPtr, 1, BdPtr);
	if (Status != XST_SUCCESS) {
		xil_printf("to hw failed %d\r\n", Status);
		return XST_FAILURE;
	}



	return XST_SUCCESS;
}

void printInfo() {
	int msg;
	char *msg2;

	msg = Xil_In32(XPAR_CL_ACCELERATOR_0_BASEADDR);
	msg2 = (char*) &msg;
	std::bitset<8> x0(msg2[0]);
	std::bitset<8> x1(msg2[1]);
	std::bitset<8> x2(msg2[2]);
	std::bitset<8> x3(msg2[3]);
	std::cout << "tdata: " << x0 << x1 << x2 << x3 << std::endl;
//
//	msg = Xil_In32(XPAR_CL_ACCELERATOR_0_BASEADDR+4);
//	msg2 = (char*) &msg;
//	std::bitset<8> xa(msg2[0]);
//	std::bitset<8> xb(msg2[1]);
//	std::bitset<8> xc(msg2[2]);
//	std::bitset<8> xd(msg2[3]);
//	std::cout << "TEST: " << xa << xb << xc << xd << std::endl;
//
//	msg = Xil_In32(XPAR_CL_ACCELERATOR_0_BASEADDR+8);
//	msg2 = (char*) &msg;
//	std::bitset<8> x4(msg2[0]);
//	std::bitset<8> x5(msg2[1]);
//	std::bitset<8> x6(msg2[2]);
//	std::bitset<8> x7(msg2[3]);
//	std::cout << "tdata_fixed: " << x4 << x5 << x6 << x7 << std::endl;

	msg = Xil_In32(XPAR_CL_ACCELERATOR_0_BASEADDR+28);
	msg2 = (char*) &msg;
	std::bitset<8> x8(msg2[0]);
	std::bitset<8> x9(msg2[1]);
	std::bitset<8> x10(msg2[2]);
	std::bitset<8> x11(msg2[3]);
	std::cout << "tdata_float: " << x8 << x9 << x10 << x11 << std::endl;


}

void ConfigureAndRunAccelerator(int nof_outputs) {

	//printInfo();
	Xil_Out32(XPAR_CL_ACCELERATOR_0_BASEADDR+4, 1); //Write weights
	Xil_Out32(XPAR_CL_ACCELERATOR_0_BASEADDR+8, 1); //Write weights
	Xil_Out32(XPAR_CL_ACCELERATOR_0_BASEADDR, 0); //Write weights
	while(Xil_In32(XPAR_CL_ACCELERATOR_0_BASEADDR+16) == 1); // Wait until done writing.

	//Xil_Out32(XPAR_CL_ACCELERATOR_0_BASEADDR+4, nof_outputs); //Set nof outputs

	//printInfo();
	//Xil_Out32(XPAR_CL_ACCELERATOR_0_BASEADDR, 1); //Start cl
	//while(Xil_In32(XPAR_CL_ACCELERATOR_0_BASEADDR+20) == 1); //Wait until cl is done
}

int GetDataFromRxBuffer(vec_it iterator, int data_size)
{
	float *RxPacket = (float*)RX_BUFFER_BASE;

	Xil_DCacheInvalidateRange((u32)RxPacket, data_size*4+32);
	std::transform(RxPacket, RxPacket+data_size, iterator, FixedToFloat);

	return XST_SUCCESS;
}

/*****************************************************************************/
/**
*
* This function waits until the DMA transaction is finished, checks data,
* and cleans up.
*
* @param	None
*
* @return	- XST_SUCCESS if DMA transfer is successful and data is correct,
*		- XST_FAILURE if fails.
*
* @note		None.
*
******************************************************************************/

int WaitForTxToFinish(XAxiDma * AxiDmaInstPtr) {
	XAxiDma_BdRing *TxRingPtr;
	XAxiDma_Bd *BdPtr;
	int ProcessedBdCount;
	int Status;

	TxRingPtr = XAxiDma_GetTxRing(AxiDmaInstPtr);


	/* Wait until the one BD TX transaction is done */
	while ((ProcessedBdCount = XAxiDma_BdRingFromHw(TxRingPtr,
							   XAXIDMA_ALL_BDS,
							   &BdPtr)) == 0) {
	}

	/* Free all processed TX BDs for future transmission */
	Status = XAxiDma_BdRingFree(TxRingPtr, ProcessedBdCount, BdPtr);
	if (Status != XST_SUCCESS) {
		xil_printf("Failed to free %d tx BDs %d\r\n",
			ProcessedBdCount, Status);
		return XST_FAILURE;
	}

}

int WaitForRxToFinish(XAxiDma * AxiDmaInstPtr)
{

	XAxiDma_BdRing *RxRingPtr;
	XAxiDma_Bd *BdPtr;
	int ProcessedBdCount;
	int FreeBdCount;
	int Status;


	RxRingPtr = XAxiDma_GetRxRing(AxiDmaInstPtr);


	/* Wait until the data has been received by the Rx channel */
	while ((ProcessedBdCount = XAxiDma_BdRingFromHw(RxRingPtr,
						       XAXIDMA_ALL_BDS,
						       &BdPtr)) == 0) {
	}

	/* Free all processed RX BDs for future transmission */
	Status = XAxiDma_BdRingFree(RxRingPtr, ProcessedBdCount, BdPtr);
	if (Status != XST_SUCCESS) {
		xil_printf("Failed to free %d rx BDs %d\r\n",
		    ProcessedBdCount, Status);
		return XST_FAILURE;
	}

	/* Return processed BDs to RX channel so we are ready to receive new
	 * packets:
	 *    - Allocate all free RX BDs
	 *    - Pass the BDs to RX channel
	 */
//	FreeBdCount = XAxiDma_BdRingGetFreeCnt(RxRingPtr);
//	Status = XAxiDma_BdRingAlloc(RxRingPtr, FreeBdCount, &BdPtr);
//	if (Status != XST_SUCCESS) {
//		xil_printf("bd alloc failed\r\n");
//		return XST_FAILURE;
//	}
//
//	Status = XAxiDma_BdRingToHw(RxRingPtr, FreeBdCount, BdPtr);
//	if (Status != XST_SUCCESS) {
//		xil_printf("Submit %d rx BDs failed %d\r\n", FreeBdCount, Status);
//		return XST_FAILURE;
//	}

	return XST_SUCCESS;
}
