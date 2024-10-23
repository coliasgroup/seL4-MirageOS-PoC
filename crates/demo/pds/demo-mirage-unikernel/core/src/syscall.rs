use alloc::boxed::Box;
use core::ffi::VaList;
use core::mem::MaybeUninit;
use core::ops::Range;
use core::ptr;

use sel4_musl::set_syscall_handler;
use sel4_linux_syscall_types::{VaListAsSyscallArgs, Syscall, ParseSyscallError, SyscallReturnValue};
use sel4_microkit::debug_print;

const OCAML_HEAP_SIZE: usize = 2097152; // 2MB
static mut OCAML_HEAP: &'static mut [u8] = &mut [0; OCAML_HEAP_SIZE];

fn ocaml_heap_ptr_range() -> Range<*const u8> {
    unsafe { OCAML_HEAP.as_ptr_range() }
}

pub fn init() {
    unsafe {
        set_syscall_handler(handle_syscall);
    }
}

fn handle_syscall(syscall: Result<Syscall, ParseSyscallError<VaListAsSyscallArgs>) -> Result<SyscallReturnValue, ()> {
    match Syscall::get(sysnum, args) {
        Some(syscall) => {
            // println!("syscall: {:?}", syscall);
            handle_known_syscall(syscall)
        }
        None => {
            panic!("unknown syscall: sysnum={}", sysnum)
        }
    }
}

fn handle_known_syscall(syscall: Syscall) -> Result<SyscallReturnValue, ()> {
    use Syscall::*;

    Ok(match syscall {
        Getuid | Geteuid | Getgid | Getegid => -ENOSYS,
        Brk { addr } => {
            (if addr.is_null() {
                ocaml_heap_ptr_range().start
            } else if ocaml_heap_ptr_range().contains(&addr) {
                addr
            } else {
                ptr::null()
            }) as i64
        }
        Mmap {
            addr,
            len,
            prot,
            flag,
            fd,
            offset,
        } => {
            if flag & MAP_ANONYMOUS != 0 {
                let ret: *const [MaybeUninit<u8>] =
                    Box::into_raw(Box::<[u8]>::new_uninit_slice(len));
                ret as *const () as i64
            } else {
                -ENOMEM
            }
        }
        Lseek { fd, offset, whence } => {
            assert!(whence == SEEK_CUR);
            assert!(offset == 0);
            assert!(0 <= fd && fd <= 2);
            0
        }
        Write { fd, buf, count } => {
            assert!(fd == 1 || fd == 2);
            for i in 0..(count as isize) {
                let c: u8 = unsafe { *buf.offset(i) };
                debug_print!("{}", c as char);
            }
            count as i64
        }
        Writev { fd, iov, iovcnt } => {
            assert!(fd == 1 || fd == 2);
            let mut ret: isize = 0;
            for i in 0..(iovcnt as isize) {
                let iov = unsafe { &*iov.offset(i) };
                for j in 0..(iov.iov_len as isize) {
                    let c: u8 = unsafe { *(iov.iov_base as *const u8).offset(j) };
                    debug_print!("{}", c as char);
                    ret += 1;
                }
            }
            ret as i64
        }
    })
}
