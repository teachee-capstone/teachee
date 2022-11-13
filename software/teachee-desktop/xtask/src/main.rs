use std::process;

use xshell::{cmd, Result, Shell};

fn main() {
    if let Err(err) = try_main() {
        eprintln!("{}", err);
        process::exit(1);
    }
}

fn try_main() -> Result<()> {
    let sh = Shell::new()?;
    cmd!(sh, "cargo clippy --workspace -- -D warnings").run()?;
    cmd!(sh, "cargo fmt -- --check").run()?;
    cmd!(sh, "cargo test --workspace").run()?;
    Ok(())
}
