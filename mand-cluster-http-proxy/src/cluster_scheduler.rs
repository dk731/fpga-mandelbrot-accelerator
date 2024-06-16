use std::{
    collections::HashMap,
    sync::atomic::{compiler_fence, Ordering},
};

use anyhow::Result;
use serde::{Deserialize, Serialize};
use tokio::sync::mpsc::error::TryRecvError;

use crate::mand_cluster::MandCluster;

pub type SchedulerN = u64;
pub type SchedulerF = u128;
pub type SchedulerP = u128;

#[derive(Clone)]
struct CalculationRequest {
    x: SchedulerP,
    y: SchedulerP,
    max_itterations: SchedulerN,

    attempts: u64,
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
        let (tx, rx) = tokio::sync::mpsc::channel(1000);

        std::thread::spawn(|| Self::cluster_thread(rx));

        Self {
            calculation_sender: tx,
        }
    }
}

impl ClusterScheduler {
    fn cluster_thread(mut calculation_receiver: tokio::sync::mpsc::Receiver<CalculationRequest>) {
        let mut cluster = MandCluster::<SchedulerN, SchedulerF, SchedulerP>::new().unwrap();

        println!("Cluster initialized");
        println!("Cores count: {}", cluster.cores_count());
        println!("Cluster busy flags: {:b}", cluster.cores_busy_flags());
        println!("Cluster valid flags: {:b}", cluster.cores_valid_flags());

        println!("Cluster last command: {}", cluster.command());
        println!("Cluster last command status: {}", cluster.command_status());

        // Reset all cores
        for i in 0..cluster.cores_count() {
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
            compiler_fence(Ordering::SeqCst);

            let busy_reg = cluster.cores_busy_flags();
            let valid_reg = cluster.cores_valid_flags();

            for core_addres in 0..cluster.cores_count() {
                let running_task = running_tasks.get_mut(&core_addres);

                // Check if core is not busy
                if busy_reg & (1 << core_addres) == 0 {
                    // Check if task was assgined to this core
                    if let Some(task) = running_task {
                        // Check if core is result is valid
                        if valid_reg & (1 << core_addres) == 1 {
                            // Load result command
                            cluster.load_core_address(core_addres);
                            cluster.load_command(ClusterCommand::LoadResult.into());

                            task.response_channel
                                .blocking_send(Ok(cluster.core_result()))
                                .unwrap();
                        } else if task.attempts < 10000 {
                            task.attempts += 1;
                            queue_tasks.push(task.clone());
                        } else {
                            task.response_channel
                                .blocking_send(Err(anyhow::anyhow!("Core was reseted")))
                                .unwrap();
                        }
                    }

                    running_tasks.remove(&core_addres);

                    // Load new task
                    if let Some(task) = queue_tasks.pop() {
                        cluster.load_core_address(core_addres);
                        cluster.load_core_x(task.x);
                        cluster.load_core_y(task.y);
                        cluster.load_core_itterations_max(task.max_itterations);

                        cluster.load_command(ClusterCommand::Start.into());

                        if cluster.command_status() == ClusterCommandStatus::Success.into() {
                            running_tasks.insert(core_addres, task);
                        } else {
                            println!(
                                "Was not able to start core: {}. Error: {}",
                                core_addres,
                                cluster.command_status()
                            );
                        }
                    }
                }
            }

            compiler_fence(Ordering::SeqCst);

            loop {
                let new_request = calculation_receiver.try_recv();

                match new_request {
                    Ok(request) => {
                        queue_tasks.push(request);
                    }
                    Err(err) => {
                        if err == TryRecvError::Empty {
                            break;
                        } else {
                            println!("Request channel closed: {}", err);
                            return;
                        }
                    }
                }
            }
        }
    }

    pub async fn run_callculation(
        &self,
        x: SchedulerP,
        y: SchedulerP,
        max_itterations: SchedulerN,
    ) -> Result<SchedulerN> {
        let (tx, mut rx) = tokio::sync::mpsc::channel(1);

        self.calculation_sender
            .send(CalculationRequest {
                x,
                y,
                max_itterations,
                response_channel: tx,
                attempts: 0,
            })
            .await
            .unwrap();

        let result = rx.recv().await.unwrap()?;

        Ok(result)
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
