fn main() {
    let c_files = glob::glob("c/*.c")
        .unwrap()
        .collect::<Result<Vec<_>, _>>()
        .unwrap();

    cc::Build::new().files(&c_files).compile("glue");

    for path in &c_files {
        println!("cargo:rerun-if-changed={}", path.display());
    }
}
