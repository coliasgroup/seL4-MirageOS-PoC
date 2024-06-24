#![no_std]

use smoltcp::phy::{Device, DeviceCapabilities, RxToken, TxToken};
use smoltcp::time::Instant;

pub struct Pollable<D: for<'b> Device<RxToken<'b>: 'static, TxToken<'b>: 'static> + 'static> {
    inner: D,
    ready_rx_token_pair: Option<(D::RxToken<'static>, D::TxToken<'static>)>,
    ready_tx_token: Option<D::TxToken<'static>>,
}

impl<D: Device + 'static> Pollable<D> {
    pub fn new(inner: D) -> Self {
        Self {
            inner,
            ready_rx_token_pair: None,
            ready_tx_token: None,
        }
    }

    fn poll_rx(&mut self, timestamp: Instant) -> bool {
        if self.ready_rx_token_pair.is_none() {
            self.ready_rx_token_pair = self.inner.receive(timestamp);
        }
        self.ready_rx_token_pair.is_some()
    }

    fn poll_tx(&mut self, timestamp: Instant) -> bool {
        if self.ready_tx_token.is_none() {
            self.ready_tx_token = self.inner.transmit(timestamp);
        }
        self.ready_tx_token.is_some()
    }
}
impl<D: Device + 'static> Device for Pollable<D> {
    type RxToken<'a> = D::RxToken<'a> where Self: 'a;
    type TxToken<'a> = D::TxToken<'a> where Self: 'a;

    fn receive(&mut self, timestamp: Instant) -> Option<(Self::RxToken<'_>, Self::TxToken<'_>)> {
        self.poll_rx(timestamp);
        self.ready_rx_token_pair.take()
    }

    fn transmit(&mut self, timestamp: Instant) -> Option<Self::TxToken<'_>> {
        self.poll_tx(timestamp);
        self.ready_tx_token.take()
    }

    fn capabilities(&self) -> DeviceCapabilities {
        self.inner.capabilities()
    }
}
