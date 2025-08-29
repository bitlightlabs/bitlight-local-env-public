use std::env;
use std::io::{BufRead, BufReader};
use std::process::{Command, Stdio};
use structopt::StructOpt;

#[derive(StructOpt)]
pub struct Mint {
    #[structopt(default_value = "1")]
    blocks: u32,
}

pub fn mint(args: Mint) {
    let project_name = env::var("BITCOIN_COMPOSE_PROJECT_NAME")
        .expect("BITCOIN_COMPOSE_PROJECT_NAME environment variable is not set");

    println!("Minting {} blocks", args.blocks);

    let mut child = Command::new("docker-compose")
        .args([
            "-p",
            &project_name,
            "exec",
            "-it",
            "-w",
            "/cli",
            "bitcoin-core",
            "/cli/active.sh",
            "mint",
            &args.blocks.to_string(),
        ])
        .stdout(Stdio::piped())
        .spawn()
        .expect("Failed to execute command");

    if let Some(ref mut stdout) = child.stdout {
        let reader = BufReader::new(stdout);
        for line in reader.lines() {
            println!("{}", line.unwrap());
        }
    }

    let exit_status = child.wait().expect("Failed to wait on child");

    if !exit_status.success() {
        eprintln!("Command executed with error");
        std::process::exit(1);
    }
}
