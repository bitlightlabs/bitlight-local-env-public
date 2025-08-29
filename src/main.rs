// src/main.rs
mod blockchain_commands;
mod api_commands;
use dotenv::dotenv;
use structopt::StructOpt;

#[derive(StructOpt)]
enum Command {
    Mint(blockchain_commands::Mint),
    Get(api_commands::Get),
}

#[derive(StructOpt)]
struct Cli {
    #[structopt(subcommand)]
    cmd: Option<Command>,
}

fn main() {
    dotenv().ok(); // load environment variables from .env file
    let args = Cli::from_args();
    match args.cmd {
        Some(Command::Mint(mint)) => {
            blockchain_commands::mint(mint);
        }
        Some(Command::Get(get)) => {
            api_commands::get(get);
        }
        None => {
            println!("No command provided");
        }
    }
}