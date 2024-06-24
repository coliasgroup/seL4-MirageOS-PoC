use cortex_a::registers::{CNTFRQ_EL0, CNTPCT_EL0};
use tock_registers::interfaces::Readable;

#[inline(never)]
pub fn read_cntfrq_el0() -> u32 {
    CNTFRQ_EL0.get() as u32
}

#[inline(never)]
pub fn read_cntpct_el0() -> u64 {
    CNTPCT_EL0.get()
}

pub fn time_ns() -> u64 {
    let cntfrq = read_cntfrq_el0() as i128;
    let cntvct = read_cntpct_el0() as i128;
    ((cntvct * 1_000_000_000) / cntfrq) as u64
}
