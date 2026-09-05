use std::env;

fn main() {
    // Path to target/release/build/<pkg>-<hash>/out
    let out_dir = env::var("OUT_DIR").unwrap();
    println!("cargo:warning=Build output directory: {}", out_dir);
}
