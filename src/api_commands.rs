use std::env;
use structopt::StructOpt;
use reqwest::Error;

#[derive(StructOpt)]
pub struct Get {
    path: String,
}

pub fn get(args: Get) {
    let runtime = tokio::runtime::Runtime::new().unwrap();
    runtime.block_on(query(args.path)).unwrap();
}

pub async fn query(path: String) -> Result<(), Error> {
    let esplora_api_url = env::var("ESPLORA_API_URL").unwrap_or_else(|_| String::from("http://localhost:3002"));
    let response = reqwest::get(format!("{}/{}", esplora_api_url, path)).await?;
    let body = response.json::<serde_json::Value>().await?;
    println!("{}", serde_json::to_string_pretty(&body).unwrap());

    Ok(())
}