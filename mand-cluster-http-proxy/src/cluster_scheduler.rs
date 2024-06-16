use std::{
    collections::{HashMap, HashSet},
    io::Read,
    rc::Rc,
    sync::{
        atomic::{compiler_fence, Ordering},
        Arc, Mutex,
    },
};

use anyhow::Result;
use serde::{Deserialize, Serialize};
use tokio::sync::mpsc::error::TryRecvError;

use crate::mand_cluster::MandCluster;

type SchedulerN = u64;
type SchedulerF = u128;
type SchedulerP = i128;

#[derive(Clone)]
struct CalculationRequest {
    x: SchedulerP,
    y: SchedulerP,
    itterations_max: SchedulerN,

    response_channel: tokio::sync::mpsc::Sender<Result<SchedulerN>>,
}

pub struct ClusterScheduler {
    calculation_sender: tokio::sync::mpsc::Sender<CalculationRequest>,
}

#[derive(Debug, Serialize, Deserialize)]
pub enum ClusterCommand {
    NOP,
    LoadResult,
    Start,
    Reset,
}

#[derive(Debug, Serialize, Deserialize)]
pub enum ClusterCommandStatus {
    Success,
    ClusterBusy,
    InvalidCommand,
    InvalidCore,
    CoreBusy,
    AfterReset,
    UnknownError,
}

impl Default for ClusterScheduler {
    fn default() -> Self {
        let (tx, rx) = tokio::sync::mpsc::channel(1);

        std::thread::spawn(|| Self::cluster_thread(rx));

        Self {
            calculation_sender: tx,
        }
    }
}

impl ClusterScheduler {
    fn cluster_thread(mut calculation_receiver: tokio::sync::mpsc::Receiver<CalculationRequest>) {
        compiler_fence(Ordering::SeqCst);

        let mut cluster = MandCluster::<SchedulerN, SchedulerF, SchedulerP>::new().unwrap();

        println!("Cluster initialized");
        println!("Cores count: {}", cluster.cores_count());
        println!("Cluster busy flags: {:b}", cluster.cores_busy_flags());
        println!("Cluster valid flags: {:b}", cluster.cores_valid_flags());

        println!("Cluster last command: {}", cluster.command());
        println!("Cluster last command status: {}", cluster.command_status());

        // Reset all cores
        for i in 1..cluster.cores_count() {
            cluster.load_core_address(i);
            cluster.load_command(ClusterCommand::Reset.into());

            if cluster.command_status() != ClusterCommandStatus::Success.into() {
                panic!(
                    "Was not able to reset core: {}. Status reg: {}. Last command: {}",
                    i,
                    cluster.command_status(),
                    cluster.command()
                );
            }
        }

        println!("Cluster reseted");
        println!("Cluster busy flags: {:b}", cluster.cores_busy_flags());
        println!("Cluster valid flags: {:b}", cluster.cores_valid_flags());

        let mut running_tasks: HashMap<u64, CalculationRequest> = HashMap::new();
        let mut queue_tasks: Vec<CalculationRequest> = Vec::new();

        loop {
            running_tasks.retain(|core_id, task| {
                let busy_reg = cluster.cores_busy_flags();
                let valid_reg = cluster.cores_valid_flags();

                if busy_reg & (1 << core_id) == 0 {
                    if valid_reg & (1 << core_id) == 1 {
                        // Run load command
                        cluster.load_core_address(*core_id as SchedulerN);
                        cluster.load_command(ClusterCommand::LoadResult.into());

                        if cluster.command_status() == ClusterCommandStatus::Success.into() {
                            task.response_channel
                                .blocking_send(Ok(cluster.core_result()))
                                .unwrap();
                        } else {
                            task.response_channel
                                .blocking_send(Err(anyhow::anyhow!("Cluster busy")))
                                .unwrap();
                        }
                    } else {
                        task.response_channel
                            .blocking_send(Err(anyhow::anyhow!("Core was reseted")))
                            .unwrap();
                    }

                    return false;
                }

                true
            });

            let new_request = calculation_receiver.try_recv();

            match new_request {
                Ok(request) => {
                    queue_tasks.push(request);
                }
                Err(err) => {
                    if err == TryRecvError::Disconnected {
                        break;
                    }
                }
            }

            queue_tasks = queue_tasks
                .into_iter()
                .enumerate()
                .filter_map(|(_, task)| {
                    let cores_count = cluster.cores_count();
                    let busy_reg = cluster.cores_busy_flags();

                    let mut core_id = None;

                    for i in 0..cores_count {
                        if busy_reg & (1 << i) == 0 && !running_tasks.contains_key(&i) {
                            core_id = Some(i);
                            break;
                        }
                    }

                    if let Some(target_core) = core_id {
                        println!("Starting core: {}", target_core);

                        cluster.load_core_address(target_core);
                        cluster.load_core_x(task.x);
                        cluster.load_core_y(task.y);
                        cluster.load_core_itterations_max(task.itterations_max);

                        cluster.load_command(ClusterCommand::Start.into());

                        if cluster.command_status() == ClusterCommandStatus::Success.into() {
                            running_tasks.insert(target_core, task);
                            return None;
                        } else {
                            println!(
                                "Was not able to start core: {}. Error: {}",
                                target_core,
                                cluster.command_status()
                            );
                        }
                    }

                    Some(task)
                })
                .collect();
        }

        compiler_fence(Ordering::SeqCst);
    }

    pub async fn run_callculation(
        &mut self,
        x: SchedulerP,
        y: SchedulerP,
        itterations_max: SchedulerN,
    ) -> Result<SchedulerN> {
        let (tx, mut rx) = tokio::sync::mpsc::channel(1);

        self.calculation_sender
            .send(CalculationRequest {
                x,
                y,
                itterations_max,
                response_channel: tx,
            })
            .await
            .unwrap();

        rx.recv().await.unwrap()
    }
}

impl From<ClusterCommand> for SchedulerN {
    fn from(val: ClusterCommand) -> Self {
        match val {
            ClusterCommand::NOP => 0,
            ClusterCommand::LoadResult => 1,
            ClusterCommand::Start => 2,
            ClusterCommand::Reset => 3,
        }
    }
}

impl From<ClusterCommandStatus> for SchedulerN {
    fn from(val: ClusterCommandStatus) -> Self {
        match val {
            ClusterCommandStatus::Success => 0,
            ClusterCommandStatus::ClusterBusy => 1,
            ClusterCommandStatus::InvalidCommand => 2,
            ClusterCommandStatus::InvalidCore => 3,
            ClusterCommandStatus::CoreBusy => 4,
            ClusterCommandStatus::AfterReset => 5,
            ClusterCommandStatus::UnknownError => 6,
        }
    }
}
