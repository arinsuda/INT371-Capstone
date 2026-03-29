ALTER TABLE
    background_jobs
ADD
    INDEX idx_type_status_run_after (type, status, run_after),
ADD
    INDEX idx_created_at_status (created_at, status);