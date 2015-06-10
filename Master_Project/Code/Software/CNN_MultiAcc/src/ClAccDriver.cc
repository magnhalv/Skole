#include "../include/ClAccDriver.h"
#include <c++/4.8.3/bitset>
#include <c++/4.8.3/iostream>
#include <stdio.h>



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
	InitializeDMA();


}

void ClAccDriver::InitializeDMA() {
	dmas.resize(2);
	for (unsigned int id = 0; id < 1; id++) {
		int Status;
		XAxiDma_Config *Config;
		XAxiDma AxiDma;
		Config = XAxiDma_LookupConfig(dma_ids[id]);
		if (!Config) {
			xil_printf("No config found for %d\r\n", DMA_DEV_ID);


		}
		/* Initialize DMA engine */
		Status = XAxiDma_CfgInitialize(&AxiDma, Config);
		if (Status != XST_SUCCESS) {
			xil_printf("Initialization failed %d\r\n", Status);

		}

		Status = TxSetup(&AxiDma, id);
		if (Status != XST_SUCCESS) {

		}

		Status = RxSetup(&AxiDma, id);
		if (Status != XST_SUCCESS) {

		}

		dmas[id] = (AxiDma);
	}

}

void ClAccDriver::CalculateLayer(feature_map_parameters &fmp) {


	const int img_dim = fmp[0][0].img_dim;
	const int kernel_dim = fmp[0][0].kernel_dim;
	u32 nof_outputs = ((img_dim-kernel_dim+1)/2)*((img_dim-kernel_dim+1)/2);
	int layer = fmp[0].size() > 1 ? 2 : 1;

	int id1 = 0;

	InitializeDMA();
	int nof_tx_bds;

	XAxiDma AxiDma0 = TransferDatatoAccAndSetupRx(fmp, id1, &nof_tx_bds);
	WaitForTxToFinish(&AxiDma0, 4);

	for (unsigned int i = 0; i < fmp.size(); i++) {
//		int data_in = Xil_In32(acc_addr[id1]);
//		xil_printf("Data in: %d\n\r", data_in);
		ConfigureAndRunAccelerator(nof_outputs, layer, fmp[i].size(), id1);
		while(Xil_In32(acc_addr[id1]+16) == 1);

	}
	WaitForRxToFinish(&AxiDma0, fmp.size());
	GetDataFromRxBuffer(fmp[0][0].feature_map, nof_outputs*fmp.size(), id1);

}

XAxiDma ClAccDriver::TransferDatatoAccAndSetupRx(feature_map_parameters &fmp, int id, int *nof_tx_bds)
{
	int Status = 0;
	const vec_clv clv_vec0 = fmp[0];
	const int img_dim = clv_vec0[0].img_dim;
	const int kernel_dim = clv_vec0[0].kernel_dim;
	u32 nof_outputs = ((img_dim-kernel_dim+1)/2)*((img_dim-kernel_dim+1)/2);



	XAxiDma AxiDma;
	AxiDma = dmas[id];


	Status = SetupRxTransfer(&AxiDma, nof_outputs, id, clv_vec0[0].feature_map, fmp.size());

	/* Send a packet */
	Status = SendPacket(&AxiDma, fmp, id, nof_tx_bds);
	if (Status != XST_SUCCESS) {

	}
	return AxiDma;
}

int ClAccDriver::SetupRxTransfer (XAxiDma * AxiDmaInstPtr, const int recv_length, int id, vec_it buffer, int nof_transfers) {
	XAxiDma_Bd *BdPtr;
	XAxiDma_Bd *BdCurPtr;
	u32 RxBufferPtr;
	const int MAX_RECV_LEN = recv_length*4;
	XAxiDma_BdRing *RxRingPtr;
	int Status;

	RxRingPtr = XAxiDma_GetRxRing(AxiDmaInstPtr);

	int nof_bds = nof_transfers;
	Status = XAxiDma_BdRingAlloc(RxRingPtr, nof_bds, &BdPtr);
	if (Status != XST_SUCCESS) {
		xil_printf("RX alloc BD failed %d\r\n", Status);

		return XST_FAILURE;
	}

	BdCurPtr = BdPtr;
	RxBufferPtr = (u32)&(*buffer);//dma_buffer_addr[id].rx_buffer_base();

	for (int i = 0; i < nof_bds; i++) {
		Status = XAxiDma_BdSetBufAddr(&BdCurPtr[i], RxBufferPtr+MAX_RECV_LEN*i);

		if (Status != XST_SUCCESS) {
			xil_printf("Set buffer addr %x on BD %x failed %d\r\n",
				(unsigned int)RxBufferPtr,
				(unsigned int)BdCurPtr[i], Status);

			return XST_FAILURE;
		}

		Status = XAxiDma_BdSetLength(&BdCurPtr[i], MAX_RECV_LEN,
				RxRingPtr->MaxTransferLen);
		if (Status != XST_SUCCESS) {
			xil_printf("Rx set length %d on BD %x failed %d\r\n",
				MAX_RECV_LEN, (unsigned int)&BdCurPtr[i], Status);

			return XST_FAILURE;
		}

		/* Receive BDs do not need to set anything for the control
		 * The hardware will set the SOF/EOF bits per stream status
		 */
		XAxiDma_BdSetId(&BdCurPtr[0], RxBufferPtr+MAX_RECV_LEN*i);
	}
	XAxiDma_BdSetCtrl(&BdCurPtr[0], XAXIDMA_BD_CTRL_TXSOF_MASK);
	XAxiDma_BdSetCtrl(&BdCurPtr[nof_transfers-1], XAXIDMA_BD_CTRL_TXEOF_MASK);





	Status = XAxiDma_BdRingToHw(RxRingPtr, nof_bds,
						BdPtr);
	if (Status != XST_SUCCESS) {
		xil_printf("RX submit hw failed %d\r\n", Status);

		return XST_FAILURE;
	}
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
int ClAccDriver::RxSetup(XAxiDma * AxiDmaInstPtr, int id)
{
	XAxiDma_BdRing *RxRingPtr;
	int Delay = 0;
	int Coalesce = 1;
	int Status;
	XAxiDma_Bd *BdPtr;
	XAxiDma_Bd *BdCurPtr;
	u32 BdCount;
	u32 FreeBdCount;
	u32 RxBufferPtr;
	int Index;
	XAxiDma_Bd BdTemplate;

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


	XAxiDma_BdClear(&BdTemplate);

	Status = XAxiDma_BdRingClone(RxRingPtr, &BdTemplate);
	if (Status != XST_SUCCESS) {
		xil_printf("RX clone BD failed %d\r\n", Status);

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
int ClAccDriver::SendPacket(XAxiDma * AxiDmaInstPtr, feature_map_parameters &fmp, int id, int *nof_tx_bds)
{
	XAxiDma_BdRing *TxRingPtr;
	XAxiDma_Bd *BdPtr;
	int Status;
	const std::vector<float> padding(16, 0);

	TxRingPtr = XAxiDma_GetTxRing(AxiDmaInstPtr);

	int tot_nof_bds = 0;
	for (auto &input_maps : fmp) {
		tot_nof_bds += (input_maps.size()*3+1);
	}
	if (XAxiDma_BdRingGetFreeCnt(TxRingPtr) < tot_nof_bds) xil_printf("Not enough bds");
	Status = XAxiDma_BdRingAlloc(TxRingPtr, tot_nof_bds, &BdPtr);
	if (Status != XST_SUCCESS) xil_printf("Could not allocate Bds\n\r");
	int bd_offset = 0;
	for (auto &clv_vec : fmp) {
		for (auto &clv : clv_vec) {
			Xil_DCacheFlushRange((u32)&(*clv.biases.begin()), 4*4+4);
			Xil_DCacheFlushRange((u32)&(*clv.image), clv.img_dim*clv.img_dim+4);
			Xil_DCacheFlushRange((u32)&(*clv.weights), clv.kernel_dim*clv.kernel_dim+4);

			/* Set up the BD using the information of the packet to transmit */

			Status = XAxiDma_BdSetBufAddr(&BdPtr[bd_offset], (u32)&(*clv.biases.begin()));
			if (Status != XST_SUCCESS) xil_printf("Fail set addr");
			Status = XAxiDma_BdSetBufAddr(&BdPtr[bd_offset+1], (u32) &(*clv.weights));
			if (Status != XST_SUCCESS) xil_printf("Fail set addr");
			Status = XAxiDma_BdSetBufAddr(&BdPtr[bd_offset+2], (u32) &(*clv.image));
			if (Status != XST_SUCCESS) xil_printf("Fail set addr");


			Status = XAxiDma_BdSetLength(&BdPtr[bd_offset], sizeof(float)*4, TxRingPtr->MaxTransferLen);
			if (Status != XST_SUCCESS) xil_printf("Fail set length");
			Status = XAxiDma_BdSetLength(&BdPtr[bd_offset+1], sizeof(float)*clv.kernel_dim*clv.kernel_dim, TxRingPtr->MaxTransferLen);
			if (Status != XST_SUCCESS) xil_printf("Fail set length");
			Status = XAxiDma_BdSetLength(&BdPtr[bd_offset+2], sizeof(float)*clv.img_dim*clv.img_dim, TxRingPtr->MaxTransferLen);
			if (Status != XST_SUCCESS) xil_printf("Fail set length");



			XAxiDma_BdSetId(&BdPtr[bd_offset+0], (u32) &clv.biases[0]);
			XAxiDma_BdSetId(&BdPtr[bd_offset+1], (u32) &(*clv.weights));
			XAxiDma_BdSetId(&BdPtr[bd_offset+2], (u32) &(*clv.image));

			bd_offset = bd_offset + 3;
		}
		Status = XAxiDma_BdSetBufAddr(&BdPtr[bd_offset], (u32) &(*padding.begin()));
		if (Status != XST_SUCCESS) xil_printf("Fail set addr");
		Status = XAxiDma_BdSetLength(&BdPtr[bd_offset], sizeof(float)*padding.size(), TxRingPtr->MaxTransferLen);
		if (Status != XST_SUCCESS) xil_printf("Fail set length");
		XAxiDma_BdSetId(&BdPtr[bd_offset], (u32) &(*(padding.begin())));
		bd_offset = bd_offset + 1;
	}


	XAxiDma_BdSetCtrl(&BdPtr[0], XAXIDMA_BD_CTRL_TXSOF_MASK);
	XAxiDma_BdSetCtrl(&BdPtr[tot_nof_bds-1], XAXIDMA_BD_CTRL_TXEOF_MASK);

	Status = XAxiDma_BdRingToHw(TxRingPtr, tot_nof_bds, BdPtr);
	if (Status != XST_SUCCESS) {
		xil_printf("to hw failed %d\r\n", tot_nof_bds);
		return XST_FAILURE;
	}

	*nof_tx_bds = bd_offset;

	return XST_SUCCESS;
}


void ClAccDriver::ConfigureAndRunAccelerator(int nof_outputs, int layer, int nof_sets, int id) {

	Xil_Out32(acc_addr[id]+4, layer); //Layer
	Xil_Out32(acc_addr[id]+8, nof_sets); //Nof sets
	Xil_Out32(acc_addr[id], 0); //Start processing



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

int ClAccDriver::WaitForTxToFinish(XAxiDma * AxiDmaInstPtr, int tota_nof_bds) {
	XAxiDma_BdRing *TxRingPtr;
	XAxiDma_Bd *BdPtr;
	int ProcessedBdCount;
	int Status;

	TxRingPtr = XAxiDma_GetTxRing(AxiDmaInstPtr);


//	/* Wait until the one BD TX transaction is done */
//	while ((ProcessedBdCount = XAxiDma_BdRingFromHw(TxRingPtr,
//							   XAXIDMA_ALL_BDS,
//							   &BdPtr)) == 0) {
//	}
//	Status = XAxiDma_BdRingFree(TxRingPtr, ProcessedBdCount, BdPtr);
//	if (Status != XST_SUCCESS) {
//		xil_printf("Failed to free %d tx BDs %d\r\n",
//			ProcessedBdCount, Status);
//		return XST_FAILURE;
//	}
	int nof_bds = 0;
	/* Wait until the one BD TX transaction is done */
	while (nof_bds < tota_nof_bds) {
		ProcessedBdCount = XAxiDma_BdRingFromHw(TxRingPtr, XAXIDMA_ALL_BDS, &BdPtr);
		nof_bds += ProcessedBdCount;

		Status = XAxiDma_BdRingFree(TxRingPtr, ProcessedBdCount, BdPtr);
		if (Status != XST_SUCCESS) {
			xil_printf("Failed to free %d tx BDs %d\r\n",
				ProcessedBdCount, Status);
			return XST_FAILURE;
		}
	}

	/* Free all processed TX BDs for future transmission */

}

int ClAccDriver::WaitForRxToFinish(XAxiDma * AxiDmaInstPtr, int tot_nof_bds)
{

	XAxiDma_BdRing *RxRingPtr;
	XAxiDma_Bd *BdPtr;
	int ProcessedBdCount;
	int FreeBdCount;
	int Status;


	RxRingPtr = XAxiDma_GetRxRing(AxiDmaInstPtr);


//	/* Wait until the data has been received by the Rx channel */
//	while ((ProcessedBdCount = XAxiDma_BdRingFromHw(RxRingPtr,
//						       XAXIDMA_ALL_BDS,
//						       &BdPtr)) == 0) {
//	}
//	/* Free all processed RX BDs for future transmission */
//	Status = XAxiDma_BdRingFree(RxRingPtr, ProcessedBdCount, BdPtr);
//	if (Status != XST_SUCCESS) {
//		xil_printf("Failed to free %d rx BDs %d\r\n",
//			ProcessedBdCount, Status);
//		return XST_FAILURE;
//	}


	int nof_bds = 0;
	while (nof_bds < tot_nof_bds) {
		ProcessedBdCount = XAxiDma_BdRingFromHw(RxRingPtr, XAXIDMA_ALL_BDS, &BdPtr);
		nof_bds += ProcessedBdCount;

		Status = XAxiDma_BdRingFree(RxRingPtr, ProcessedBdCount, BdPtr);
		if (Status != XST_SUCCESS) {
			xil_printf("Failed to free %d tx BDs %d\r\n",
				ProcessedBdCount, Status);
			return XST_FAILURE;
		}
	}


	XAxiDma_Reset(AxiDmaInstPtr);


	return XST_SUCCESS;
}
