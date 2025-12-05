use clap::Parser;

#[derive(Parser)]
#[command(arg_required_else_help = true)]
struct Args {}

fn main() {
    Args::parse();
}
