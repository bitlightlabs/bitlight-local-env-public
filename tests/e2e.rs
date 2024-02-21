use assert_cmd::Command;

#[test]
fn test_e2e() {
    // Mint 1 block via the docker-compose command in the blockchain_commands module
    let mut cmd = Command::cargo_bin("bitlight-local-env").unwrap();
    cmd.arg("mint").arg("1").assert().success();

    // Get the tip height via the API in the api_commands module
    let mut cmd = Command::cargo_bin("bitlight-local-env").unwrap();
    cmd.arg("get").arg("blocks/tip/height").assert().success();
}