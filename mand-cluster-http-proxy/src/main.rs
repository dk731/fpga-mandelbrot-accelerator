use mand_cluster_http_proxy::mand_cluster::MandCluster;

fn main() {
    println!("Hello, world! 1");

    let cluster: MandCluster<u64, u128, i128> = MandCluster::<u64, u128, i128>::new().unwrap();

    println!("Cores count: {:?}", cluster.cores_count());
}
