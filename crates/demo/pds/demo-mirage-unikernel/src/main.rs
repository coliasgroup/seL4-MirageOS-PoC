//
// Copyright 2023, Colias Group, LLC
//
// SPDX-License-Identifier: BSD-2-Clause
//

#![no_std]
#![no_main]

extern crate alloc;

use alloc::sync::Arc;

use lock_api::Mutex;
use smoltcp::iface::Config;
use smoltcp::phy::{Device, DeviceCapabilities, Medium};
use smoltcp::wire::{EthernetAddress, HardwareAddress};

use sel4_bounce_buffer_allocator::{Basic, BounceBufferAllocator};
use sel4_driver_interfaces::net::GetNetDeviceMeta;
use sel4_driver_interfaces::timer::DefaultTimer;
use sel4_externally_shared::{ExternallySharedRef, ExternallySharedRefExt};
use sel4_logging::{LevelFilter, Logger, LoggerBuilder};
use sel4_microkit::{memory_region_symbol, protection_domain, Handler};
use sel4_microkit_driver_adapters::net::client::Client as NetClient;
use sel4_microkit_driver_adapters::timer::client::Client as TimerClient;
use sel4_shared_ring_buffer::RingBuffers;
use sel4_shared_ring_buffer_smoltcp::DeviceImpl;

mod config;

use config::channels;

use demo_mirage_unikernel_core::HandlerImpl;

extern crate demo_mirage_unikernel_core;

const LOG_LEVEL: LevelFilter = {
    // LevelFilter::Trace
    // LevelFilter::Debug
    LevelFilter::Info
    // LevelFilter::Warn
};

static LOGGER: Logger = LoggerBuilder::const_default()
    .level_filter(LOG_LEVEL)
    .filter(|meta| !meta.target().starts_with("sel4_sys"))
    .write(|s| sel4::debug_print!("{}", s))
    .build();

#[protection_domain(
    heap_size = 16 * 1024 * 1024,
)]
fn init() -> impl Handler {
    LOGGER.set().unwrap();

    let mut net_client = NetClient::new(channels::NET_DRIVER);

    let timer_client = Arc::new(Mutex::new(DefaultTimer(TimerClient::new(
        channels::TIMER_DRIVER,
    ))));

    let notify_net: fn() = || channels::NET_DRIVER.notify();

    let net_device = {
        let dma_region = unsafe {
            ExternallySharedRef::<'static, _>::new(
                memory_region_symbol!(virtio_net_client_dma_vaddr: *mut [u8], n = config::VIRTIO_NET_CLIENT_DMA_SIZE),
            )
        };

        let bounce_buffer_allocator =
            BounceBufferAllocator::new(Basic::new(dma_region.as_ptr().len()), 1);

        DeviceImpl::new(
            dma_region,
            bounce_buffer_allocator,
            RingBuffers::from_ptrs_using_default_initialization_strategy_for_role(
                unsafe {
                    ExternallySharedRef::new(memory_region_symbol!(virtio_net_rx_free: *mut _))
                },
                unsafe {
                    ExternallySharedRef::new(memory_region_symbol!(virtio_net_rx_used: *mut _))
                },
                notify_net,
            ),
            RingBuffers::from_ptrs_using_default_initialization_strategy_for_role(
                unsafe {
                    ExternallySharedRef::new(memory_region_symbol!(virtio_net_tx_free: *mut _))
                },
                unsafe {
                    ExternallySharedRef::new(memory_region_symbol!(virtio_net_tx_used: *mut _))
                },
                notify_net,
            ),
            16,
            2048,
            {
                let mut caps = DeviceCapabilities::default();
                caps.max_transmission_unit = 1500;
                caps
            },
        )
        .unwrap()
    };

    let net_config = {
        assert_eq!(net_device.capabilities().medium, Medium::Ethernet);
        let mac_address = EthernetAddress(net_client.get_mac_address().unwrap().0);
        let hardware_addr = HardwareAddress::Ethernet(mac_address);
        let mut this = Config::new(hardware_addr);
        this.random_seed = 0;
        this
    };

    HandlerImpl::new(
        channels::TIMER_DRIVER,
        channels::NET_DRIVER,
        timer_client,
        net_device,
        net_config,
    )
}
