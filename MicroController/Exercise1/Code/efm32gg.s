	/////////////////////////////////////////////////////////////////////////////
	//
  // Various useful I/O addresses and definitions for EFM32GG
	//
	// TODO: Add more registers
	//
	/////////////////////////////////////////////////////////////////////////////


	      //////////////////////////////////////////////////////////////////////
      	// GPIO

	      GPIO_PA_BASE = 0x40006000
	      GPIO_PB_BASE = 0x40006024
	      GPIO_PC_BASE = 0x40006048
	      GPIO_PD_BASE = 0x4000606c
	      GPIO_PE_BASE = 0x40006090
	      GPIO_PF_BASE = 0x400060b4

	      // register offsets from base address
	      GPIO_CTRL     = 0x00
        GPIO_MODEL    = 0x04
        GPIO_MODEH    = 0x08
        GPIO_DOUT     = 0x0c
        GPIO_DOUTSET  = 0x10
        GPIO_DOUTCLR  = 0x14
        GPIO_DOUTTGL  = 0x18
        GPIO_DIN      = 0x1c
        GPIO_PINLOCKN = 0x20

	      GPIO_BASE = 0x40006100

	      // register offsets from base address
        GPIO_EXTIPSELL = 0x00
        GPIO_EXTIPSELH = 0x04
        GPIO_EXTIRISE  = 0x08
        GPIO_EXTIFALL  = 0x0c
	      GPIO_IEN       = 0x10
	      GPIO_IF        = 0x14
	      GPIO_IFC       = 0x1c

	      //////////////////////////////////////////////////////////////////////
      	// CMU
	
        CMU_BASE = 0x400c8000

        CMU_HFPERCLKDIV = 0x008
        CMU_HFPERCLKEN0 = 0x044

        CMU_HFPERCLKEN0_GPIO = 13

	      //////////////////////////////////////////////////////////////////////
	      // NVIC

        ISER0 = 0xe000e100
        ISER1 = 0xe000e104
        ICER0 = 0xe000e180
        ICER1 = 0xe000e184
        ISPR0 = 0xe000e200
        ISPR1 = 0xe000e204
        ICPR0 = 0xe000e280
        ICPR1 = 0xe000e284
        IABR0 = 0xe000e300
        IABR1 = 0xe000e304
        IPR_BASE  = 0xe000e400
        IPR0 = 0x00
        IPR1 = 0x04
        IPR2 = 0x08
        IPR3 = 0x0c

	      //////////////////////////////////////////////////////////////////////
        // EMU

	      EMU_BASE = 0x400c6000

        EMU_CTRL = 0x000

	      //////////////////////////////////////////////////////////////////////
        // System Control Block

        SCR = 0xe000ed10

