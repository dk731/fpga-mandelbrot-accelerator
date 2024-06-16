use std::sync::Arc;

use axum::{http::StatusCode, response::IntoResponse, routing::post, Json, Router};
use mand_cluster_http_proxy::cluster_scheduler::{CalculationRequest, ClusterScheduler};
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

async fn calculate(
    Json(request): Json<CalculationRequest>,
    cluster: Arc<ClusterScheduler>,
) -> impl IntoResponse {
    let result = cluster.run_callculation(request).await;

    match result {
        Ok(result) => (StatusCode::OK, Json(result)).into_response(),
        Err(err) => (StatusCode::INTERNAL_SERVER_ERROR, err.to_string()).into_response(),
    }
}

#[derive(Deserialize, Serialize)]
struct Test {
    foo: String,
}
