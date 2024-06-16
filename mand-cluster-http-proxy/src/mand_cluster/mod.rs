use anyhow::Result;
use lazy_static::lazy_static;
use libc::{c_void, mmap, open, MAP_FAILED, MAP_PRIVATE, O_RDONLY, PROT_READ};
use std::ffi::CString;
use std::io;
use std::mem::size_of;
use std::sync::Arc;
use tokio::sync::Mutex;

// Reference to the MandCluster memory space
struct MandClusterInner<N, F, P>
where
    N: Copy,
    F: Copy,
    P: Copy,
{
    // Metadata registers
    pub cores_count: N,
    pub fixed_size: N,
    pub fixed_integer_size: N,

    // Controll registers
    pub command: N,
    pub command_status: N,
    pub core_address: N,
    pub cores_busy_flags: F,
    pub cores_valid_flags: F,

    // Loaded core output
    pub core_result: N,
    pub core_busy: N,
    pub core_valid: N,

    // Core input
    pub core_itterations_max: N,
    pub core_x: P,
    pub core_y: P,
}

pub struct MandCluster<'a, N, F, P>
where
    N: Copy,
    F: Copy,
    P: Copy,
{
    __inner: &'a MandClusterInner<N, F, P>,
    fd: i32,
}

#[cfg(target_pointer_width = "64")]
const HPS_FPGA_BRIDGE_BASE: i64 = 0xC0000000;

#[cfg(target_pointer_width = "32")]
const HPS_FPGA_BRIDGE_BASE: i32 = 0xC0000000_u32 as i32;

impl<N, F, P> MandCluster<'_, N, F, P>
where
    N: Copy,
    F: Copy,
    P: Copy,
{
    // UNSAFE!
    pub fn new() -> Result<Self> {
        let mem_file = CString::new("/dev/mem").unwrap();
        let fd = unsafe { open(mem_file.as_ptr(), O_RDONLY) };

        // This is not really correct, but will be fine
        let current_configuration_length = size_of::<Self>();

        if fd < 0 {
            return Err(anyhow::anyhow!("Failed to open /dev/mem"));
        }

        let ptr = unsafe {
            mmap(
                std::ptr::null_mut(),
                current_configuration_length,
                PROT_READ,
                MAP_PRIVATE,
                fd,
                HPS_FPGA_BRIDGE_BASE,
            )
        };

        if ptr == MAP_FAILED {
            return Err(anyhow::anyhow!(
                "Was not able to map cluster memory, mmap failed: {}",
                io::Error::last_os_error()
            ));
        }

        let cluster: &MandClusterInner<N, F, P> =
            unsafe { &*(ptr as *const MandClusterInner<N, F, P>) };

        Ok(Self {
            __inner: cluster,
            fd,
        })
    }
}

impl<N, F, P> Drop for MandCluster<'_, N, F, P>
where
    N: Copy,
    F: Copy,
    P: Copy,
{
    fn drop(&mut self) {
        // Convert the reference to a raw pointer
        let raw_ptr: *const MandClusterInner<N, F, P> = self.__inner;

        // Cast the raw pointer to a *mut libc::c_void
        let void_ptr: *mut c_void = raw_ptr as *mut c_void;

        // Unmap the memory
        let result = unsafe { libc::munmap(void_ptr, size_of::<Self>()) };
        if result != 0 {
            eprintln!(
                "Was not able to munmap mand cluster, failed: {}",
                io::Error::last_os_error()
            );
        }

        // Close the file
        let result = unsafe { libc::close(self.fd) };
        if result != 0 {
            eprintln!(
                "Was not able to close `/dev/mem` close failed: {}",
                io::Error::last_os_error()
            );
        }
    }
}

// Getters
impl<N, F, P> MandCluster<'_, N, F, P>
where
    N: Copy,
    F: Copy,
    P: Copy,
{
    pub fn cores_count(&self) -> N {
        self.__inner.cores_count
    }

    pub fn fixed_size(&self) -> N {
        self.__inner.fixed_size
    }

    pub fn fixed_integer_size(&self) -> N {
        self.__inner.fixed_integer_size
    }

    pub fn command(&self) -> N {
        self.__inner.command
    }

    pub fn command_status(&self) -> N {
        self.__inner.command_status
    }

    pub fn core_address(&self) -> N {
        self.__inner.core_address
    }

    pub fn cores_busy_flags(&self) -> F {
        self.__inner.cores_busy_flags
    }

    pub fn cores_valid_flags(&self) -> F {
        self.__inner.cores_valid_flags
    }

    pub fn core_result(&self) -> N {
        self.__inner.core_result
    }

    pub fn core_busy(&self) -> N {
        self.__inner.core_busy
    }

    pub fn core_valid(&self) -> N {
        self.__inner.core_valid
    }

    pub fn core_itterations_max(&self) -> N {
        self.__inner.core_itterations_max
    }

    pub fn core_x(&self) -> P {
        self.__inner.core_x
    }

    pub fn core_y(&self) -> P {
        self.__inner.core_y
    }
}
