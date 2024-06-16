use std::ffi::CString;

use axum::{
    http::StatusCode,
    response::IntoResponse,
    routing::{get, post},
    Json, Router,
};
use libc::{mmap, open, MAP_FAILED, MAP_SHARED, O_SYNC, PROT_READ, PROT_WRITE};
use mand_cluster_http_proxy::cluster_scheduler;
use serde::{Deserialize, Serialize};

#[tokio::main]
async fn main() {
    let mut cluster_scheduler = cluster_scheduler::ClusterScheduler::default();

    let start_time = std::time::Instant::now();
    let res = cluster_scheduler
        .run_callculation(0, 0, 1000000)
        .await
        .unwrap();

    println!("res: {}", res);
    println!("time: {:?}", start_time.elapsed());

    // build our application with a route
    let app = Router::new()
        // `GET /` goes to `root`
        .route("/", get(root));

    let listener = tokio::net::TcpListener::bind("0.0.0.0:8000").await.unwrap();
    axum::serve(listener, app).await.unwrap();
}

async fn root() -> impl IntoResponse {
    let tmp = Test {
        foo: "bar".to_string(),
    };

    (StatusCode::OK, Json(tmp))

    // fn qwe() {}
    // todo!()
}

#[derive(Deserialize, Serialize)]
struct Test {
    foo: String,
}
