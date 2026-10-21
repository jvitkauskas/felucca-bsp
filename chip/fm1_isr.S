/* SPDX-License-Identifier: MPL-2.0
 * Copyright (c) 2026 Julius Vitkauskas (optional BLE preemption accounting)
 * Copyright (C) 2026 Leo Kuroshita (@kurogedelic), Hügelton Instruments */
/* IRQ entry wrappers: save what a C call may
 * clobber, call the plain C body, restore, csync, rti. Our clang never emits
 * the csync stock ISRs have before rti, so ISRs are not written in C directly. */
	.macro FM1_ISR name, body, account=0
	.section .text.\name,"ax",@progbits
	.globl \name
\name:
	[--sp] = {psr, rets, reti}
	[--sp] = {r3-r0}
#if FM1B_BLE_OPEN
	.if \account
	call ble_time_preempt_enter
	.endif
#endif
	call \body
#if FM1B_BLE_OPEN
	.if \account
	call ble_time_preempt_leave
	.endif
#endif
	{r3-r0} = [sp++]
	{psr, rets, reti} = [sp++]
	csync
	rti
	.endm

	FM1_ISR isr_timer5, fm1_timer5_irq, 1
	FM1_ISR isr_alnk0, fm1_alnk0_irq, 1

#if FM1B_BLE_OPEN
	FM1_ISR isr_ble_rx, fm1_ble_rx_irq, 1
	FM1_ISR isr_ble_event, fm1_ble_event_irq, 1
	FM1_ISR isr_ble_worker, fm1_ble_worker_irq
#endif
