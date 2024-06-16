use fixed::{traits::Fixed, types::extra::*, *};
use rand::Rng;
use std::any::type_name;

fn calculate_mandelbrot<T: Fixed>(x0: T, y0: T, max_itterations: u64) -> u64 {
    let bound_radius = T::from_num(4);
    let fixed_2 = T::from_num(2);

    let mut x = T::from_num(0);
    let mut y = T::from_num(0);

    for itteration in 0..max_itterations {
        let x_s = x * x;
        let y_s = y * y;

        if x_s + y_s > bound_radius {
            return itteration;
        }

        let x_temp = x_s - y_s + x0;
        y = fixed_2 * x * y + y0;
        x = x_temp;
    }

    max_itterations
}

fn perform_test<T: Fixed>() -> f64 {
    let x = T::from_num(rand::random::<f64>() * 0.2);
    let y = T::from_num(rand::random::<f64>() * 0.2);

    let max_itterations = 1_000_000_000;

    let start_time = std::time::Instant::now();
    let itterations = calculate_mandelbrot(x, y, max_itterations);

    println!("Fixed point type: {:?}", type_name::<T>());

    println!("Point: ({}, {})", x, y);
    println!("Itterations: {}", itterations);
    println!("Time: {:?}", start_time.elapsed());

    let itt_per_sec = max_itterations as f64 / start_time.elapsed().as_secs_f64();
    println!(
        "Iterations per second: {} Mitt/s\n\n",
        itt_per_sec / 1_000_000.0
    );

    itt_per_sec
}

fn main() {
    let results = [
        perform_test::<FixedI8<U3>>(),
        perform_test::<FixedI16<U11>>(),
        perform_test::<FixedI32<U27>>(),
        perform_test::<FixedI64<U59>>(),
        perform_test::<FixedI128<U123>>(),
    ];

    println!("Results: {:?}", results);
    // Chose arbitrary point inside bulb, to get max itterations
}
