use anyhow::Result;
use libc::{c_void, mmap, open, MAP_FAILED, MAP_SHARED, O_RDWR, O_SYNC, PROT_READ, PROT_WRITE};
use std::ffi::CString;
use std::fmt::Debug;
use std::io;
use std::mem::size_of;

const LOAD_DELAY: std::time::Duration = std::time::Duration::from_nanos(20);

// Reference to the MandCluster memory space
#[repr(C)]
#[derive(Copy, Clone, Debug)]
struct MandClusterInner<N, F, P>
where
    N: Copy + Debug,
    F: Copy + Debug,
    P: Copy + Debug,
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
    N: Copy + Debug,
    F: Copy + Debug,
    P: Copy + Debug,
{
    __inner: &'a mut MandClusterInner<N, F, P>,
    fd: i32,
}

#[cfg(target_pointer_width = "64")]
const HPS_FPGA_BRIDGE_BASE: i64 = 0xC0000000;

#[cfg(target_pointer_width = "32")]
const HPS_FPGA_BRIDGE_BASE: i32 = -1073741824i32;
// const HPS_FPGA_BRIDGE_BASE: i32 = 0xC0000000;

impl<N, F, P> MandCluster<'_, N, F, P>
where
    N: Copy + Debug,
    F: Copy + Debug,
    P: Copy + Debug,
{
    // UNSAFE!
    pub fn new() -> Result<Self> {
        let mem_file: CString = CString::new("/dev/mem").unwrap();
        let fd = unsafe { open(mem_file.as_ptr(), O_RDWR | O_SYNC) };

        if fd < 0 {
            return Err(anyhow::anyhow!("Failed to open /dev/mem"));
        }

        // This is not really correct, but will be fine
        let current_configuration_length = size_of::<MandClusterInner<N, F, P>>();

        let ptr = unsafe {
            mmap(
                std::ptr::null_mut(),
                current_configuration_length,
                PROT_READ | PROT_WRITE,
                MAP_SHARED,
                fd,
                HPS_FPGA_BRIDGE_BASE,
            )
        };

        if ptr == MAP_FAILED {
            return Err(anyhow::anyhow!(
                "Was not able to map cluster memory, mmap failed: {}. Pointer: {:?}",
                io::Error::last_os_error(),
                ptr
            ));
        }

        let cluster: &mut MandClusterInner<N, F, P> =
            unsafe { &mut *(ptr as *mut MandClusterInner<N, F, P>) };

        Ok(Self {
            __inner: cluster,
            fd,
        })
    }
}

impl<N, F, P> Drop for MandCluster<'_, N, F, P>
where
    N: Copy + Debug,
    F: Copy + Debug,
    P: Copy + Debug,
{
    fn drop(&mut self) {
        // Convert the reference to a raw pointer
        let raw_ptr: *const MandClusterInner<N, F, P> = self.__inner;

        // Cast the raw pointer to a *mut libc::c_void
        let void_ptr: *mut c_void = raw_ptr as *mut c_void;

        // Unmap the memory
        let result = unsafe { libc::munmap(void_ptr, size_of::<MandClusterInner<N, F, P>>()) };
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

// Getters and setters
impl<N, F, P> MandCluster<'_, N, F, P>
where
    N: Copy + Debug,
    F: Copy + Debug,
    P: Copy + Debug,
{
    // Setters
    pub fn load_command(&mut self, command: N) {
        self.__inner.command = command;
        std::thread::sleep(LOAD_DELAY);
    }

    pub fn load_core_address(&mut self, core_address: N) {
        self.__inner.core_address = core_address;
        std::thread::sleep(LOAD_DELAY);
    }

    pub fn load_core_x(&mut self, core_x: P) {
        self.__inner.core_x = core_x;
        std::thread::sleep(LOAD_DELAY);
    }

    pub fn load_core_y(&mut self, core_y: P) {
        self.__inner.core_y = core_y;
        std::thread::sleep(LOAD_DELAY);
    }

    pub fn load_core_itterations_max(&mut self, core_itterations_max: N) {
        self.__inner.core_itterations_max = core_itterations_max;
        std::thread::sleep(LOAD_DELAY);
    }

    // Getters
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
