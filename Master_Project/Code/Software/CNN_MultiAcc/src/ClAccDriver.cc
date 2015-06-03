#include "../include/ClAccDriver.h"
#include <c++/4.8.3/bitset>
#include <c++/4.8.3/iostream>



/************************** Variable Definitions *****************************/
/*
 * Device instance definitions
 */

/*
 * Buffer for transmit packet. Must be 32-bit aligned to be used by DMA.
 */





int FloatToFixed(float n) {
	float temp = n*65536;
	int fixed = (int)temp;
	return fixed;
}

float FixedToFloat(float n) {
	return n;
}

ClAccDriver::ClAccDriver() {
	buffer_addr dma0_addr{MEM_BASE_0_ADDR};
	buffer_addr dma1_addr{MEM_BASE_1_ADDR};
	dma_buffer_addr.push_back(dma0_addr);
	dma_buffer_addr.push_back(dma1_addr);


}

void ClAccDriver::CalculateLayer(feature_map_parameters &fmp) {
	for (unsigned int i = 0; i < fmp.size(); i++) {
		int Status;
		int id1 = 0;
		int id2 = 1;

		const int img_dim = fmp[i][0].img_dim;
		const int kernel_dim = fmp[i][0].kernel_dim;
		u32 nof_outputs = ((img_dim-kernel_dim+1)/2)*((img_dim-kernel_dim+1)/2);
		int layer = fmp[i].size() > 1 ? 2 : 1;

		XAxiDma AxiDma1 = TransferDatatoAccAndSetupRx(fmp[i], id1);
		//XAxiDma AxiDma2 = TransferDatatoAccAndSetupRx(fmp[i+1], id2);

		Status = WaitForTxToFinish(&AxiDma1);
		//Status = WaitForTxToFinish(&AxiDma2);


		ConfigureAndRunAccelerator(nof_outputs, layer, fmp[i].size(), id1);
		//ConfigureAndRunAccelerator(nof_outputs, layer, fmp[i+1].size(), id2);

		Status = WaitForRxToFinish(&AxiDma1);
		//Status = WaitForRxToFinish(&AxiDma2);


		Status = GetDataFromRxBuffer(fmp[i][0].feature_map, nof_outputs, id1);
		//Status = GetDataFromRxBuffer(fmp[i+1][0].feature_map, nof_outputs, id2);

	}
}

void ClAccDriver::WriteDataToTxBuffer(const std::vector<ConvLayerValues> &clv_vec, int id) {


	const int img_size = clv_vec[0].img_dim*clv_vec[0].img_dim;
	const int weights_size = clv_vec[0].kernel_dim*clv_vec[0].kernel_dim;
	int leap = (img_size+weights_size+4);
	for (unsigned int i = 0; i < clv_vec.size(); i++) {
		float *Buffer = (float*)dma_buffer_addr[id].tx_buffer_base();
		ConvLayerValues clv = clv_vec[i];

		Buffer[0+i*leap] = clv.scale_factor;
		Buffer[1+i*leap] = clv.avg_pool_bias;
		Buffer[2+i*leap] = clv.avg_pool_coefficient;
		Buffer[3+i*leap] = clv.bias;

		std::copy(clv.weights, clv.weights+25, &Buffer[4+i*leap]);
		std::copy(clv.image, clv.image+img_size, &Buffer[4+i*leap+weights_size]);
	}
}

XAxiDma ClAccDriver::TransferDatatoAccAndSetupRx(const std::vector<ConvLayerValues> &clv_vec, int id)
{
	int Status;
	XAxiDma_Config *Config;
	XAxiDma AxiDma;
	const int img_dim = clv_vec[0].img_dim;
	const int kernel_dim = clv_vec[0].kernel_dim;
	u32 nof_outputs = ((img_dim-kernel_dim+1)/2)*((img_dim-kernel_dim+1)/2);
	int layer = clv_vec.size() > 1 ? 2 : 1;



	Config = XAxiDma_LookupConfig(dma_ids[id]);
	if (!Config) {
		xil_printf("No config found for %d\r\n", DMA_DEV_ID);


	}

	/* Initialize DMA engine */
	Status = XAxiDma_CfgInitialize(&AxiDma, Config);
	if (Status != XST_SUCCESS) {
		xil_printf("Initialization failed %d\r\n", Status);

	}

	if(!XAxiDma_HasSg(&AxiDma)) {
		xil_printf("Device configured as Simple mode \r\n");


	}

	Status = TxSetup(&AxiDma, id);
	if (Status != XST_SUCCESS) {

	}


	Status = RxSetup(&AxiDma, nof_outputs, id, clv_vec[0].feature_map);
	if (Status != XST_SUCCESS) {

	}

	/* Send a packet */
	Status = SendPacket(&AxiDma, clv_vec, id);
	if (Status != XST_SUCCESS) {

	}

	return AxiDma;
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
int ClAccDriver::RxSetup(XAxiDma * AxiDmaInstPtr, const int recv_length, int id, vec_it buffer)
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

	RxRingPtr = XAxiDma_GetRxRing(AxiDmaInstPtr);

	/* Disable all RX interrupts before RxBD space setup */

	XAxiDma_BdRingIntDisable(RxRingPtr, XAXIDMA_IRQ_ALL_MASK);

	/* Set delay and coalescing */
	XAxiDma_BdRingSetCoalesce(RxRingPtr, Coalesce, Delay);

	/* Setup Rx BD space */
	BdCount = XAxiDma_BdRingCntCalc(XAXIDMA_BD_MINIMUM_ALIGNMENT,
				dma_buffer_addr[id].rx_bd_space_high()- dma_buffer_addr[id].rx_bd_space_base() + 1);

	Status = XAxiDma_BdRingCreate(RxRingPtr, dma_buffer_addr[id].rx_bd_space_base(),
			dma_buffer_addr[id].rx_bd_space_base(),
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
	RxBufferPtr = (u32)&(*buffer);//dma_buffer_addr[id].rx_buffer_base();
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
	//memset((void *)dma_buffer_addr[id].rx_buffer_base(), 0, MAX_RECV_LEN);

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
int ClAccDriver::TxSetup(XAxiDma * AxiDmaInstPtr, int id)
{
	XAxiDma_BdRing *TxRingPtr;
	XAxiDma_Bd BdTemplate;
	int Delay = 0;
	int Coalesce = 1;
	int Status;
	u32 BdCount;

	TxRingPtr = XAxiDma_GetTxRing(AxiDmaInstPtr);

	/* Disable all TX interrupts before TxBD space setup */

	XAxiDma_BdRingIntDisable(TxRingPtr, XAXIDMA_IRQ_ALL_MASK);

	/* Set TX delay and coalesce */
	XAxiDma_BdRingSetCoalesce(TxRingPtr, Coalesce, Delay);

	/* Setup TxBD space  */
	BdCount = XAxiDma_BdRingCntCalc(XAXIDMA_BD_MINIMUM_ALIGNMENT,
			dma_buffer_addr[id].tx_bd_space_high() - dma_buffer_addr[id].tx_bd_space_base() + 1);

	Status = XAxiDma_BdRingCreate(TxRingPtr, dma_buffer_addr[id].tx_bd_space_base(),
			dma_buffer_addr[id].tx_bd_space_base(),
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
int ClAccDriver::SendPacket(XAxiDma * AxiDmaInstPtr, const std::vector<ConvLayerValues> &clv_vec, int id)
{
	XAxiDma_BdRing *TxRingPtr;
	int *TxPacket;
	XAxiDma_Bd *BdPtr;
	int Status;
	int Index;
	const int img_size = clv_vec[0].img_dim*clv_vec[0].img_dim;
	const int weights_size = clv_vec[0].kernel_dim*clv_vec[0].kernel_dim;
	const int MAX_PKT_LEN = clv_vec.size()*(img_size+weights_size+4)*sizeof(int);

	TxRingPtr = XAxiDma_GetTxRing(AxiDmaInstPtr);
	if (clv_vec.size() > 1) {
		WriteDataToTxBuffer(clv_vec, id);
		/* Create pattern in the packet to transmit */
		TxPacket = (int *) dma_buffer_addr[id].tx_buffer_base();

		/* Flush the SrcBuffer before the DMA transfer, in case the Data Cache
		 * is enabled
		 */
		Xil_DCacheFlushRange((u32)TxPacket, MAX_PKT_LEN+32);

		/* Allocate a BD */
		Status = XAxiDma_BdRingAlloc(TxRingPtr, 2, &BdPtr);
		if (Status != XST_SUCCESS) {
			return XST_FAILURE;
		}
		/* Set up the BD using the information of the packet to transmit */
		Status = XAxiDma_BdSetBufAddr(BdPtr, (u32) TxPacket);
		if (Status != XST_SUCCESS) {
			xil_printf("Tx set buffer addr %x on BD %x failed %d\r\n",
				(unsigned int)dma_buffer_addr[id].tx_buffer_base(), (unsigned int)BdPtr, Status);

			return XST_FAILURE;
		}

		Status = XAxiDma_BdSetLength(BdPtr, MAX_PKT_LEN,
					TxRingPtr->MaxTransferLen);
		if (Status != XST_SUCCESS) {
			xil_printf("Tx set length %d on BD %x failed %d\r\n",
				MAX_PKT_LEN, (unsigned int)BdPtr, Status);

			return XST_FAILURE;
		}

		/* For single packet, both SOF and EOF are to be set
		 */

		XAxiDma_BdSetCtrl(BdPtr, XAXIDMA_BD_CTRL_TXSOF_MASK | XAXIDMA_BD_CTRL_TXEOF_MASK);


		XAxiDma_BdSetId(BdPtr, (u32) TxPacket);

		/* Give the BD to DMA to kick off the transmission. */
		Status = XAxiDma_BdRingToHw(TxRingPtr, 1, BdPtr);
		if (Status != XST_SUCCESS) {
			xil_printf("to hw failed %d\r\n", Status);
			return XST_FAILURE;
		}

	}
	else {

		const ConvLayerValues &clv = clv_vec[0];
		vec_t bias;
		bias.push_back(clv.scale_factor);
		bias.push_back(clv.avg_pool_bias);
		bias.push_back(clv.avg_pool_coefficient);
		bias.push_back(clv.bias);
		Xil_DCacheFlushRange((u32)TxPacket, MAX_PKT_LEN+32);
		Status = XAxiDma_BdRingAlloc(TxRingPtr, 3, &BdPtr);
		/* Set up the BD using the information of the packet to transmit */

		Status = XAxiDma_BdSetBufAddr(&BdPtr[0], (u32) &bias[0]);
		if (Status != XST_SUCCESS) xil_printf("Fail set addr");
		Status = XAxiDma_BdSetBufAddr(&BdPtr[1], (u32) &(*clv.weights));
		if (Status != XST_SUCCESS) xil_printf("Fail set addr");
		Status = XAxiDma_BdSetBufAddr(&BdPtr[2], (u32) &(*clv.image));
		if (Status != XST_SUCCESS) xil_printf("Fail set addr");


		Status = XAxiDma_BdSetLength(&BdPtr[0], sizeof(float)*4, TxRingPtr->MaxTransferLen);
		if (Status != XST_SUCCESS) xil_printf("Fail set length");
		Status = XAxiDma_BdSetLength(&BdPtr[1], sizeof(float)*clv.kernel_dim*clv.kernel_dim, TxRingPtr->MaxTransferLen);
		if (Status != XST_SUCCESS) xil_printf("Fail set length");
		Status = XAxiDma_BdSetLength(&BdPtr[2], sizeof(float)*clv.img_dim*clv.img_dim, TxRingPtr->MaxTransferLen);
		if (Status != XST_SUCCESS) xil_printf("Fail set length");

		/* For single packet, both SOF and EOF are to be set
		 */
		XAxiDma_BdSetCtrl(&BdPtr[0], XAXIDMA_BD_CTRL_TXSOF_MASK);
		XAxiDma_BdSetCtrl(&BdPtr[2], XAXIDMA_BD_CTRL_TXEOF_MASK);



		XAxiDma_BdSetId(&BdPtr[0], (u32) &bias[0]);
		XAxiDma_BdSetId(&BdPtr[1], (u32) &(*clv.weights));
		XAxiDma_BdSetId(&BdPtr[2], (u32) &(*clv.image));
	}
	/* Give the BD to DMA to kick off the transmission. */
	Status = XAxiDma_BdRingToHw(TxRingPtr, 2, BdPtr);
	if (Status != XST_SUCCESS) {
		xil_printf("to hw failed %d\r\n", Status);
		return XST_FAILURE;
	}

	return XST_SUCCESS;
}


void ClAccDriver::ConfigureAndRunAccelerator(int nof_outputs, int layer, int nof_sets, int id) {

	Xil_Out32(acc_addr[id]+4, layer); //Layer
	Xil_Out32(acc_addr[id]+8, nof_sets); //Nof sets
	Xil_Out32(acc_addr[id], 0); //Start processing

	while(Xil_In32(acc_addr[id]+16) == 1);

}

int ClAccDriver::GetDataFromRxBuffer(vec_it iterator, int data_size, int id)
{
	//float *RxPacket = (float*)dma_buffer_addr[id].rx_buffer_base();

	Xil_DCacheInvalidateRange((u32)&(*iterator), data_size*4+32);
	//std::transform(RxPacket, RxPacket+data_size, iterator, FixedToFloat);

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

int ClAccDriver::WaitForTxToFinish(XAxiDma * AxiDmaInstPtr) {
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

int ClAccDriver::WaitForRxToFinish(XAxiDma * AxiDmaInstPtr)
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
