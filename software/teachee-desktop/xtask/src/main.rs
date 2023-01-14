use std::process;

use structopt::StructOpt;
use xshell::{cmd, Shell};

type Result<T> = std::result::Result<T, Box<dyn std::error::Error>>;

#[derive(Debug, StructOpt)]
enum Opt {
    #[structopt(about = "Runs CI checks")]
    Ci,
}

fn main() {
    if let Err(err) = try_main() {
        eprintln!("Error: {:?}", err);
        process::exit(1);
    }
}

fn try_main() -> Result<()> {
    match Opt::from_args() {
        Opt::Ci => ci(),
    }
}

fn ci() -> Result<()> {
    let sh = Shell::new()?;
    cmd!(sh, "cargo clippy --workspace -- -D warnings").run()?;
    cmd!(sh, "cargo fmt -- --check").run()?;
    cmd!(sh, "cargo test --workspace").run()?;
    Ok(())
}
