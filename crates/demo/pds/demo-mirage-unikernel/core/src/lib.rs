#![no_std]
#![feature(c_variadic)]
#![feature(new_uninit)]
#![allow(dead_code)]
#![allow(unused_variables)]

extern crate alloc;

use alloc::format;
use alloc::sync::Arc;
use alloc::vec;
use alloc::vec::Vec;
use core::ffi::c_int;

use lock_api::Mutex;
use smoltcp::iface::Config;
use smoltcp::phy::{Device, RxToken, TxToken};
use smoltcp::time::Instant as SmoltcpInstant;

use sel4_bounce_buffer_allocator::Basic;
use sel4_driver_interfaces::timer::DefaultTimer;
use sel4_microkit::debug_println;
use sel4_microkit::{Handler, Infallible, Never};
use sel4_microkit_driver_adapters::timer::client::Client as TimerClient;
use sel4_mirage_core::ocaml;
use sel4_shared_ring_buffer_smoltcp::DeviceImpl;
use sel4_sync::{PanickingRawMutex, SharedArcMutex};

mod syscall;
mod time_hack;

static GLOBAL_STATE: lock_api::Mutex<PanickingRawMutex, Option<State>> = lock_api::Mutex::new(None);

type NetIfaceId = usize;

pub struct State {
    timer_driver_channel: sel4_microkit::Channel,
    net_driver_channel: sel4_microkit::Channel,
    timer: Arc<Mutex<PanickingRawMutex, DefaultTimer<TimerClient>>>,
    net_devices: Vec<DeviceImpl<Basic, SharedArcMutex<PanickingRawMutex>>>,
}

pub struct HandlerImpl {
    net_config: Config,
}

impl HandlerImpl {
    pub fn new(
        timer_driver_channel: sel4_microkit::Channel,
        net_driver_channel: sel4_microkit::Channel,
        timer: Arc<Mutex<PanickingRawMutex, DefaultTimer<TimerClient>>>,
        net_device: DeviceImpl<Basic, SharedArcMutex<PanickingRawMutex>>,
        net_config: Config,
    ) -> Self {
        let state = State {
            timer_driver_channel,
            net_driver_channel,
            timer,
            net_devices: vec![net_device],
        };
        {
            let mut global_state = GLOBAL_STATE.lock();
            *global_state = Some(state);
        }

        syscall::init();

        Self { net_config }
    }
}

impl Handler for HandlerImpl {
    type Error = Infallible;

    fn run(&mut self) -> Result<Never, Self::Error> {
        let obj = serde_json::json!({
            "network_config": {
                "mac": format!("{}", self.net_config.hardware_addr),
                "ip": "192.168.1.2",
                "network": "192.168.1.0/24",
                "gateway": "192.168.1.1",
            },
        });

        let arg = serde_json::to_vec(&obj).unwrap();
        debug_println!("mirage enter");
        let ret = ocaml::run_main(&arg);
        debug_println!("mirage exit: {:?}", ret);
        panic!()
    }
}

fn with<T, F: FnOnce(&mut State) -> T>(f: F) -> T {
    let mut state = GLOBAL_STATE.lock();
    let state = state.as_mut().unwrap();
    state.callback();
    let ret = f(state);
    state.callback();
    ret
}

impl State {
    fn wfe(&mut self) {
        // panic!("wfe");
        // TODO (must be notified of timeouts)
        // let badge = self.event.wait();
        // self.event_server_bitfield.clear_ignore(badge);
    }

    fn callback(&mut self) {
        for d in &mut self.net_devices {
            d.poll();
        }
    }
}

#[no_mangle]
extern "C" fn impl_wfe() {
    with(|s| s.wfe())
}

#[no_mangle]
extern "C" fn impl_get_time_ns() -> u64 {
    with(|s| time_hack::time_ns())
}

#[no_mangle]
extern "C" fn impl_set_timeout_ns(ns: u64) {
    with(|s| {
        // HACK
    })
}

#[no_mangle]
extern "C" fn impl_num_net_ifaces() -> usize {
    with(|s| s.net_devices.len())
}

#[no_mangle]
extern "C" fn impl_net_iface_poll(id: NetIfaceId) -> c_int {
    with(|s| s.net_devices[id].can_receive()) as c_int
}

#[no_mangle]
extern "C" fn impl_net_iface_tx(id: NetIfaceId, buf: *const u8, n: usize) {
    with(|s| {
        let tx_tok = s.net_devices[id].transmit(SmoltcpInstant::ZERO).unwrap();
        tx_tok.consume(n, |out_buf| {
            let foreign = unsafe { core::slice::from_raw_parts(buf, n) };
            out_buf.copy_from_slice(foreign);
        })
    })
}

#[no_mangle]
extern "C" fn impl_net_iface_rx(id: NetIfaceId) -> usize {
    with(|s| {
        let (rx_tok, _) = s.net_devices[id].receive(SmoltcpInstant::ZERO).unwrap();
        rx_tok.consume(|buf| {
            let bytes = ocaml::alloc(buf.len());
            bytes.as_mut_slice().copy_from_slice(buf);
            bytes.handle
        })
    })
}
