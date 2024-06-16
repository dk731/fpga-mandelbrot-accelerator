use std::sync::Arc;

use axum::{http::StatusCode, response::IntoResponse, routing::post, Json, Router};
use mand_cluster_http_proxy::cluster_scheduler::{ClusterScheduler, SchedulerN, SchedulerP};
use serde::{Deserialize, Serialize};

#[tokio::main]
async fn main() {
    let cluster_scheduler = Arc::new(ClusterScheduler::default());

    // build our application with a route
    let app = Router::new().route(
        "/calculate",
        post({
            let cluster = cluster_scheduler.clone();
            move |json| calculate(json, cluster)
        }),
    );

    let listener = tokio::net::TcpListener::bind("0.0.0.0:8000").await.unwrap();
    axum::serve(listener, app).await.unwrap();
}

#[derive(Deserialize, Serialize, Debug)]
struct CalculateRequest {
    x: String,
    y: String,
    max_itterations: String,
}
// Hex string

#[derive(Deserialize, Serialize)]
struct CalculateResponse {
    itterations: String,
}
// Hex string

async fn calculate(
    Json(request): Json<CalculateRequest>,
    cluster: Arc<ClusterScheduler>,
) -> impl IntoResponse {
    let x: SchedulerP = SchedulerP::from_str_radix(request.x.trim_start_matches("0x"), 16).unwrap();
    let y: SchedulerP = SchedulerP::from_str_radix(request.y.trim_start_matches("0x"), 16).unwrap();
    let max_itterations: SchedulerN =
        SchedulerN::from_str_radix(request.max_itterations.trim_start_matches("0x"), 16).unwrap();

    let result = cluster.run_callculation(x, y, max_itterations).await;

    match result {
        Ok(result) => (
            StatusCode::OK,
            Json(CalculateResponse {
                itterations: format!("{:x}", result),
            }),
        )
            .into_response(),
        Err(err) => (StatusCode::INTERNAL_SERVER_ERROR, err.to_string()).into_response(),
    }
}

#[derive(Deserialize, Serialize)]
struct Test {
    foo: String,
}
